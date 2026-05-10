// lib/core/theme/nimbus_widgets.dart
//
// Compoziție vizuală: GlassCard (sticla peste fundal) și LvBackdrop
// (fundalul derivat din tema activă).
//
// Fundalul nu mai e mesh-dinamic per vehicul — în schimb, e generat din
// schema de culori a temei active (gradient subtil + spot accent), ca să
// se potrivească natural cu fiecare temă.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'nimbus_tokens.dart';

// ──────────── LvBackdrop ────────────
//
// Fundal care urmează tema curentă. Pune-l ca primul copil al Stack-ului
// care conține Scaffold-ul.
//
// Comportament per chrome:
//   • soft (Blush, Olive, Mint) — gradient diagonal pe surface ↔
//     surfaceContainerLow + 1 spot foarte difuz pe primary la opacitate
//     mică. Calm, aerisit.
//   • glow (Midnight) — surface aproape-negru cu un glow verde-neon
//     ambiental.
//   • block (Carbon Racing) — flat dark cu 2 spot-uri foarte subtile
//     (roșu + alb) pentru a păstra identitatea sportivă fără zgomot.
//   • paper (rezervat) — flat surface, fără spot-uri.

class LvBackdrop extends StatelessWidget {
  const LvBackdrop({super.key, this.intensity = 1.0});

  /// 0..1 — multiplicator pe opacitate. 1.0 = default. Folosește <1 pentru
  /// ecrane unde fundalul ar concura cu conținutul (e.g. forms lungi).
  final double intensity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tokens = theme.extension<NimbusTokens>();
    final chrome = tokens?.chrome ?? NimbusChrome.soft;

    switch (chrome) {
      case NimbusChrome.glow:
        return _GlowBackdrop(cs: cs, intensity: intensity);
      case NimbusChrome.block:
        return _BlockBackdrop(cs: cs, intensity: intensity);
      case NimbusChrome.paper:
        return DecoratedBox(decoration: BoxDecoration(color: cs.surface));
      case NimbusChrome.soft:
        return _SoftBackdrop(cs: cs, intensity: intensity);
    }
  }
}

class _SoftBackdrop extends StatelessWidget {
  const _SoftBackdrop({required this.cs, required this.intensity});
  final ColorScheme cs;
  final double intensity;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.surface,
            cs.surfaceContainerLow,
            cs.surfaceContainer,
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(fit: StackFit.expand, children: [
        // spot accent foarte difuz în colțul de sus dreapta
        _SoftSpot(
          color: cs.primary.withOpacity(0.10 * intensity),
          alignment: const Alignment(0.9, -0.85),
          radiusFactor: 0.65,
        ),
        // spot secondary jos-stânga, și mai difuz
        _SoftSpot(
          color: cs.secondary.withOpacity(0.06 * intensity),
          alignment: const Alignment(-0.9, 0.95),
          radiusFactor: 0.7,
        ),
      ]),
    );
  }
}

class _GlowBackdrop extends StatelessWidget {
  const _GlowBackdrop({required this.cs, required this.intensity});
  final ColorScheme cs;
  final double intensity;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: cs.surfaceContainerLowest),
      child: Stack(fit: StackFit.expand, children: [
        _SoftSpot(
          color: cs.primary.withOpacity(0.18 * intensity),
          alignment: const Alignment(-0.4, -0.7),
          radiusFactor: 0.7,
        ),
        _SoftSpot(
          color: cs.secondary.withOpacity(0.10 * intensity),
          alignment: const Alignment(0.8, 0.6),
          radiusFactor: 0.6,
        ),
      ]),
    );
  }
}

class _BlockBackdrop extends StatelessWidget {
  const _BlockBackdrop({required this.cs, required this.intensity});
  final ColorScheme cs;
  final double intensity;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: cs.surfaceContainerLowest),
      child: Stack(fit: StackFit.expand, children: [
        // un singur glow roșu, foarte subtil, în colțul de jos dreapta
        _SoftSpot(
          color: cs.primary.withOpacity(0.14 * intensity),
          alignment: const Alignment(0.95, 1.0),
          radiusFactor: 0.55,
        ),
        // și o linie ambient subtilă pe diagonală (vibe "racing stripe")
        _SoftSpot(
          color: cs.onSurface.withOpacity(0.03 * intensity),
          alignment: const Alignment(-0.7, -0.7),
          radiusFactor: 0.4,
        ),
      ]),
    );
  }
}

class _SoftSpot extends StatelessWidget {
  const _SoftSpot({
    required this.color,
    required this.alignment,
    required this.radiusFactor,
  });
  final Color color;
  final Alignment alignment;
  final double radiusFactor;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: alignment,
            radius: radiusFactor,
            colors: [color, color.withOpacity(0)],
            stops: const [0, 1],
          ),
        ),
      );
}

// ──────────── GlassCard ────────────
//
// Card translucent cu blur. Folosește în loc de Card-ul standard pentru
// orice element pus peste fundal. Variantele:
//   GlassCard.heavy()  — card principal (radius 24)
//   GlassCard.light()  — chip / control mic (radius 14)
//   GlassCard.ultra()  — modal / overlay
//
// Important: BackdropFilter NU funcționează dacă nu e ceva în spatele
// widget-ului — adică ai nevoie de LvBackdrop sau de o imagine sub el.

enum NimbusGlassWeight { light, heavy, ultra }

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.weight = NimbusGlassWeight.heavy,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius,
    this.onTap,
    this.tinted, // override-uiește overlay-ul cu o tentă (e.g. risc.criticalSoft)
  });

  final Widget child;
  final NimbusGlassWeight weight;
  final EdgeInsets padding;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final Color? tinted;

  factory GlassCard.light({Key? key, required Widget child, EdgeInsets padding = const EdgeInsets.all(12), VoidCallback? onTap}) =>
      GlassCard(key: key, weight: NimbusGlassWeight.light, padding: padding, onTap: onTap, child: child);
  factory GlassCard.heavy({Key? key, required Widget child, EdgeInsets padding = const EdgeInsets.all(16), VoidCallback? onTap, Color? tinted}) =>
      GlassCard(key: key, padding: padding, onTap: onTap, tinted: tinted, child: child);
  factory GlassCard.ultra({Key? key, required Widget child, EdgeInsets padding = const EdgeInsets.all(20)}) =>
      GlassCard(key: key, weight: NimbusGlassWeight.ultra, padding: padding, child: child);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<NimbusTokens>()!;
    final layer = switch (weight) {
      NimbusGlassWeight.light => t.glass.light,
      NimbusGlassWeight.heavy => t.glass.heavy,
      NimbusGlassWeight.ultra => t.glass.ultra,
    };
    final radius = borderRadius ?? BorderRadius.circular(
      weight == NimbusGlassWeight.light ? t.radii.sm : t.radii.lg,
    );

    final card = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: layer.blurSigma, sigmaY: layer.blurSigma),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: tinted ?? layer.fill,
            borderRadius: radius,
            border: Border.all(color: t.borderGlass, width: 0.5),
            // shine inset 1px sus — îl simulăm cu un BoxShadow inset alb
            boxShadow: [
              BoxShadow(color: layer.insetHighlight, offset: const Offset(0, 1), blurRadius: 0, spreadRadius: -0.5, blurStyle: BlurStyle.inner),
            ],
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );

    final withShadow = DecoratedBox(
      decoration: BoxDecoration(borderRadius: radius, boxShadow: t.shadow),
      child: card,
    );

    if (onTap == null) return withShadow;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        splashColor: Colors.white.withOpacity(0.08),
        highlightColor: Colors.white.withOpacity(0.04),
        child: withShadow,
      ),
    );
  }
}

// ──────────── Eyebrow & RiskPill ────────────
// Două componente foarte folosite în dashboard.

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color});
  final String text;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: color ?? cs.onSurfaceVariant,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class RiskPill extends StatelessWidget {
  const RiskPill({super.key, required this.tier, required this.label});
  final NimbusRiskTier tier;
  final String label;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<NimbusTokens>()!;
    final color = switch (tier) {
      NimbusRiskTier.safe     => t.risk.safe,
      NimbusRiskTier.watch    => t.risk.watch,
      NimbusRiskTier.warn     => t.risk.warn,
      NimbusRiskTier.critical => t.risk.critical,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(t.radii.xs),
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.black.withOpacity(0.85),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
