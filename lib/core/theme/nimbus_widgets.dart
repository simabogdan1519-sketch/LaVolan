// lib/core/theme/nimbus_widgets.dart
//
// Compoziție vizuală: GlassCard (sticla peste mesh) și MeshBackdrop (fundalul
// dinamic per vehicul). Theme-ul Material singur nu poate reda glass-ul —
// folosește astea ca primitive.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'nimbus_tokens.dart';

// ──────────── MeshBackdrop ────────────
//
// Fundal cu 3 spot-uri radiale + culoare de bază. Pune-l ca primul copil
// al Stack-ului care conține Scaffold-ul, sau folosește-l ca background
// la tot ecranul. Tinte se schimbă cu vehiculul activ — animă cu
// AnimatedSwitcher / TweenAnimationBuilder pe culori.
//
// Exemplu:
//   Stack(
//     children: [
//       AnimatedMeshBackdrop(tint: t.tintFor(vehicle.id)),
//       Scaffold(backgroundColor: Colors.transparent, body: …),
//     ],
//   );

class MeshBackdrop extends StatelessWidget {
  const MeshBackdrop({super.key, required this.tint, this.grain = 0.06});
  final NimbusVehicleTint tint;
  final double grain; // 0..1 — opacitate film grain

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: tint.d),
      child: Stack(fit: StackFit.expand, children: [
        // 3 spot-uri radiale — alignment-urile match-uiesc UI-ul HTML
        _Spot(color: tint.a, alignment: const Alignment(-0.64, -0.6), radiusFactor: 0.6),
        _Spot(color: tint.b, alignment: const Alignment( 0.7,  -0.7), radiusFactor: 0.5),
        _Spot(color: tint.c, alignment: const Alignment( 0.4,   0.6), radiusFactor: 0.7),
        if (grain > 0)
          IgnorePointer(
            child: Opacity(
              opacity: grain,
              child: const ColoredBox(color: Colors.transparent),
              // În producție: pune aici un PNG noise tile-uit cu BlendMode.overlay,
              // sau un CustomPaint care desenează zgomot. Skipped aici pentru
              // dependency-zero.
            ),
          ),
      ]),
    );
  }
}

class _Spot extends StatelessWidget {
  const _Spot({required this.color, required this.alignment, required this.radiusFactor});
  final Color color;
  final Alignment alignment;
  final double radiusFactor;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: alignment,
            radius: radiusFactor,
            colors: [color, color.withValues(alpha: 0)],
            stops: const [0, 1],
          ),
        ),
      );
}

/// Variant care animează tranziția între tinte (folosește la schimbarea
/// vehiculului). Durata și curve-ul vin din [NimbusTokens.motion].
class AnimatedMeshBackdrop extends StatelessWidget {
  const AnimatedMeshBackdrop({super.key, required this.tint});
  final NimbusVehicleTint tint;

  @override
  Widget build(BuildContext context) {
    final motion = Theme.of(context).extension<NimbusTokens>()!.motion;
    return TweenAnimationBuilder<NimbusVehicleTint>(
      tween: _TintTween(end: tint),
      duration: motion.meshSwap,
      curve: motion.emphasized,
      builder: (_, value, __) => MeshBackdrop(tint: value),
    );
  }
}

class _TintTween extends Tween<NimbusVehicleTint> {
  _TintTween({required NimbusVehicleTint end}) : super(end: end);
  @override
  NimbusVehicleTint lerp(double t) => NimbusVehicleTint(
        a: Color.lerp(begin?.a ?? end!.a, end!.a, t)!,
        b: Color.lerp(begin?.b ?? end!.b, end!.b, t)!,
        c: Color.lerp(begin?.c ?? end!.c, end!.c, t)!,
        d: Color.lerp(begin?.d ?? end!.d, end!.d, t)!,
      );
}

// ──────────── GlassCard ────────────
//
// Card translucent cu blur. Folosește în loc de Card-ul standard pentru
// orice element pus peste mesh. Variantele:
//   GlassCard.heavy()  — card principal (radius 24)
//   GlassCard.light()  — chip / control mic (radius 14)
//   GlassCard.ultra()  — modal / overlay
//
// Important: BackdropFilter NU funcționează dacă nu e ceva în spatele
// widget-ului — adică ai nevoie de MeshBackdrop sau de o imagine sub el.

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
        splashColor: Colors.white.withValues(alpha: 0.08),
        highlightColor: Colors.white.withValues(alpha: 0.04),
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
          color: Colors.black.withValues(alpha: 0.85),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
