// lib/core/theme/nimbus_tokens.dart
//
// Tokeni Nimbus care nu încap în [ColorScheme]:
//   • risc (safe / watch / warn / critical)
//   • tinte mesh per vehicul (4 stop-uri) — legacy, păstrate pentru
//     compatibilitate cu vehicle_tint_service
//   • scări de glass (light / heavy / ultra) — alpha + blur sigma
//   • timing curves recomandate pentru micro-interactions
//   • spacing scale (4-step) și radii canonice
//   • chrome — stilul de fundal (soft / glow / block / paper)
//
// Acces:
//   final t = Theme.of(context).extension<NimbusTokens>()!;
//   color: t.riskColor(points: vehicle.points);

import 'package:flutter/material.dart';

/// Stilul vizual de fundal pentru tema activă.
enum NimbusChrome { soft, glow, block, paper }

@immutable
class NimbusTokens extends ThemeExtension<NimbusTokens> {
  const NimbusTokens({
    required this.brightness,
    required this.risk,
    required this.glass,
    required this.shadow,
    required this.borderHairline,
    required this.borderGlass,
    required this.spacing,
    required this.radii,
    required this.motion,
    required this.tints,
    this.chrome = NimbusChrome.soft,
  });

  final Brightness brightness;
  final NimbusRiskColors risk;
  final NimbusGlassScale glass;
  final List<BoxShadow> shadow;          // umbra standard sub un GlassCard
  final Color borderHairline;            // ~15% white în dark
  final Color borderGlass;               // ~25-30% white în dark, pentru carduri principale
  final NimbusSpacing spacing;
  final NimbusRadii radii;
  final NimbusMotion motion;
  final Map<String, NimbusVehicleTint> tints;
  final NimbusChrome chrome;

  // ──────────── helpers ────────────

  /// Returnează culoarea de risc pentru numărul de puncte de penalizare
  /// (0..15). Pragurile match-uiesc UI-ul: <4 safe, <8 watch, <12 warn,
  /// altfel critical (≥12 = aproape de suspendare).
  Color riskColor({required int points}) {
    if (points < 4)  return risk.safe;
    if (points < 8)  return risk.watch;
    if (points < 12) return risk.warn;
    return risk.critical;
  }

  /// Tier-ul textual al riscului (folosește-l pentru aria-labels & string-uri).
  NimbusRiskTier riskTier({required int points}) {
    if (points < 4)  return NimbusRiskTier.safe;
    if (points < 8)  return NimbusRiskTier.watch;
    if (points < 12) return NimbusRiskTier.warn;
    return NimbusRiskTier.critical;
  }

  /// Culoare în funcție de zilele rămase până la expirarea documentului.
  Color docColor({required int daysLeft}) {
    if (daysLeft <= 7)  return risk.critical;
    if (daysLeft <= 30) return risk.warn;
    if (daysLeft <= 60) return risk.watch;
    return risk.safe;
  }

  /// Tinte mesh per vehicul. Cheia e `vehicle.id` (logan / passat / bmw / …).
  /// Fallback la o paletă neutră dacă nu e definită.
  NimbusVehicleTint tintFor(String vehicleId) =>
      tints[vehicleId] ?? const NimbusVehicleTint(
        a: Color(0xFF9CC4DA), b: Color(0xFF5687AA),
        c: Color(0xFF3D4F7E), d: Color(0xFF1B2342),
      );

  // ──────────── factory ────────────
  factory NimbusTokens.fromBrightness(Brightness b) {
    final isDark = b == Brightness.dark;

    return NimbusTokens(
      brightness: b,

      risk: NimbusRiskColors(
        safe:     const Color(0xFF41E0B0),                     // mint
        watch:    const Color(0xFFFFC85A),                     // amber
        warn:     const Color(0xFFFF7A6B),                     // coral
        critical: const Color(0xFFFF4D5E),                     // signal red
        safeSoft:     const Color(0xFF41E0B0).withOpacity(0.18),
        watchSoft:    const Color(0xFFFFC85A).withOpacity(0.18),
        warnSoft:     const Color(0xFFFF7A6B).withOpacity(0.18),
        criticalSoft: const Color(0xFFFF4D5E).withOpacity(0.20),
      ),

      glass: NimbusGlassScale(
        // Alpha-ul peste mesh; sigma = blur radius pentru ImageFilter.blur.
        // În light mode glass-ul folosește alb peste mesh-ul colorat — în
        // dark, tot alb dar cu opacitate mai mică. Funcționează în ambele
        // pentru că mesh-ul e mereu colorat (nu alb).
        light: NimbusGlassLayer(
          fill: Colors.white.withOpacity(isDark ? 0.10 : 0.55),
          insetHighlight: Colors.white.withOpacity(isDark ? 0.20 : 0.65),
          blurSigma: 18,
        ),
        heavy: NimbusGlassLayer(
          fill: Colors.white.withOpacity(isDark ? 0.16 : 0.70),
          insetHighlight: Colors.white.withOpacity(isDark ? 0.35 : 0.85),
          blurSigma: 30,
        ),
        ultra: NimbusGlassLayer(
          fill: Colors.white.withOpacity(isDark ? 0.22 : 0.85),
          insetHighlight: Colors.white.withOpacity(isDark ? 0.45 : 0.92),
          blurSigma: 42,
        ),
      ),

      shadow: [
        BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.18 : 0.08),
          blurRadius: 24, offset: const Offset(0, 8),
        ),
      ],

      borderHairline: (isDark ? Colors.white : Colors.black).withOpacity(isDark ? 0.10 : 0.08),
      borderGlass:    (isDark ? Colors.white : Colors.black).withOpacity(isDark ? 0.25 : 0.10),

      spacing: const NimbusSpacing(),
      radii: const NimbusRadii(),

      motion: const NimbusMotion(
        // curve standard "spring soft" — cea pe care o folosim în React
        // pentru tranziția mesh-ului
        emphasized: Cubic(0.2, 0.7, 0.3, 1.0),
        standard:   Cubic(0.4, 0.0, 0.2, 1.0),
        meshSwap:   Duration(milliseconds: 600),
        cardTap:    Duration(milliseconds: 150),
        criticalPulse: Duration(milliseconds: 1600),
      ),

      // 3 tinte default — pe rest le adaugi când userul adaugă o mașină
      // nouă (extrage paletă din imagine cu palette_generator, sau default
      // la una din astea bazat pe brand).
      tints: const {
        'logan': NimbusVehicleTint(
          a: Color(0xFFF4D9B8), b: Color(0xFFE89F7A),
          c: Color(0xFFA66B8C), d: Color(0xFF3E4868),
        ),
        'passat': NimbusVehicleTint(
          a: Color(0xFF9CC4DA), b: Color(0xFF5687AA),
          c: Color(0xFF3D4F7E), d: Color(0xFF1B2342),
        ),
        'bmw': NimbusVehicleTint(
          a: Color(0xFF5B6FA8), b: Color(0xFF3A2E5C),
          c: Color(0xFF1A1430), d: Color(0xFF0A0518),
        ),
      },
    );
  }

  // ──────────── ThemeExtension boilerplate ────────────
  @override
  NimbusTokens copyWith({
    Brightness? brightness,
    NimbusRiskColors? risk,
    NimbusGlassScale? glass,
    List<BoxShadow>? shadow,
    Color? borderHairline,
    Color? borderGlass,
    NimbusSpacing? spacing,
    NimbusRadii? radii,
    NimbusMotion? motion,
    Map<String, NimbusVehicleTint>? tints,
    NimbusChrome? chrome,
  }) =>
      NimbusTokens(
        brightness: brightness ?? this.brightness,
        risk: risk ?? this.risk,
        glass: glass ?? this.glass,
        shadow: shadow ?? this.shadow,
        borderHairline: borderHairline ?? this.borderHairline,
        borderGlass: borderGlass ?? this.borderGlass,
        spacing: spacing ?? this.spacing,
        radii: radii ?? this.radii,
        motion: motion ?? this.motion,
        tints: tints ?? this.tints,
        chrome: chrome ?? this.chrome,
      );

  @override
  NimbusTokens lerp(ThemeExtension<NimbusTokens>? other, double t) {
    if (other is! NimbusTokens) return this;
    return NimbusTokens(
      brightness: t < 0.5 ? brightness : other.brightness,
      risk: NimbusRiskColors.lerp(risk, other.risk, t),
      glass: NimbusGlassScale.lerp(glass, other.glass, t),
      shadow: BoxShadow.lerpList(shadow, other.shadow, t) ?? shadow,
      borderHairline: Color.lerp(borderHairline, other.borderHairline, t)!,
      borderGlass: Color.lerp(borderGlass, other.borderGlass, t)!,
      spacing: spacing,
      radii: radii,
      motion: motion,
      tints: t < 0.5 ? tints : other.tints,
      chrome: t < 0.5 ? chrome : other.chrome,
    );
  }
}

// ──────────── tipuri auxiliare ────────────

enum NimbusRiskTier { safe, watch, warn, critical }

extension NimbusRiskTierLabel on NimbusRiskTier {
  String get labelRo => switch (this) {
        NimbusRiskTier.safe     => 'sigur',
        NimbusRiskTier.watch    => 'atenție',
        NimbusRiskTier.warn     => 'risc ridicat',
        NimbusRiskTier.critical => 'suspendare iminentă',
      };
}

@immutable
class NimbusRiskColors {
  const NimbusRiskColors({
    required this.safe, required this.watch, required this.warn, required this.critical,
    required this.safeSoft, required this.watchSoft, required this.warnSoft, required this.criticalSoft,
  });
  final Color safe, watch, warn, critical;
  final Color safeSoft, watchSoft, warnSoft, criticalSoft;
  static NimbusRiskColors lerp(NimbusRiskColors a, NimbusRiskColors b, double t) => NimbusRiskColors(
        safe: Color.lerp(a.safe, b.safe, t)!,
        watch: Color.lerp(a.watch, b.watch, t)!,
        warn: Color.lerp(a.warn, b.warn, t)!,
        critical: Color.lerp(a.critical, b.critical, t)!,
        safeSoft: Color.lerp(a.safeSoft, b.safeSoft, t)!,
        watchSoft: Color.lerp(a.watchSoft, b.watchSoft, t)!,
        warnSoft: Color.lerp(a.warnSoft, b.warnSoft, t)!,
        criticalSoft: Color.lerp(a.criticalSoft, b.criticalSoft, t)!,
      );
}

@immutable
class NimbusGlassLayer {
  const NimbusGlassLayer({required this.fill, required this.insetHighlight, required this.blurSigma});
  final Color fill;            // overlay color peste mesh
  final Color insetHighlight;  // shine 1px sus
  final double blurSigma;      // ImageFilter.blur(sigma)
  static NimbusGlassLayer lerp(NimbusGlassLayer a, NimbusGlassLayer b, double t) => NimbusGlassLayer(
        fill: Color.lerp(a.fill, b.fill, t)!,
        insetHighlight: Color.lerp(a.insetHighlight, b.insetHighlight, t)!,
        blurSigma: a.blurSigma + (b.blurSigma - a.blurSigma) * t,
      );
}

@immutable
class NimbusGlassScale {
  const NimbusGlassScale({required this.light, required this.heavy, required this.ultra});
  final NimbusGlassLayer light, heavy, ultra;
  static NimbusGlassScale lerp(NimbusGlassScale a, NimbusGlassScale b, double t) => NimbusGlassScale(
        light: NimbusGlassLayer.lerp(a.light, b.light, t),
        heavy: NimbusGlassLayer.lerp(a.heavy, b.heavy, t),
        ultra: NimbusGlassLayer.lerp(a.ultra, b.ultra, t),
      );
}

@immutable
class NimbusVehicleTint {
  // 4 stop-uri pentru mesh: a (warm spot), b (mid), c (deep), d (background fill)
  const NimbusVehicleTint({required this.a, required this.b, required this.c, required this.d});
  final Color a, b, c, d;
}

@immutable
class NimbusSpacing {
  const NimbusSpacing();
  final double xxs = 4;
  final double xs  = 8;
  final double sm  = 12;
  final double md  = 16;
  final double lg  = 20;
  final double xl  = 24;
  final double xxl = 32;
}

@immutable
class NimbusRadii {
  const NimbusRadii();
  final double xs   = 8;     // chip / badge
  final double sm   = 14;    // input / button mic
  final double md   = 18;    // card mic
  final double lg   = 24;    // card principal
  final double xl   = 28;    // bottom nav glass / sheet header
  final double pill = 9999;
}

@immutable
class NimbusMotion {
  const NimbusMotion({
    required this.emphasized,
    required this.standard,
    required this.meshSwap,
    required this.cardTap,
    required this.criticalPulse,
  });
  final Curve emphasized;
  final Curve standard;
  final Duration meshSwap;       // tranziția mesh când schimbi vehiculul
  final Duration cardTap;        // ripple / scale pe card
  final Duration criticalPulse;  // pulse pe gauge când risk == critical
}
