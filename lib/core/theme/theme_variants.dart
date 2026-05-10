// lib/core/theme/theme_variants.dart
//
// Override-uri vizuale pentru fiecare AppThemeVariant. NimbusTheme rămâne
// "shell"-ul (layout, padding, glass), iar variantele schimbă schemele de
// culori, fonturile și paleta de risk pentru a transmite vibe-uri diferite:
//
//   • nimbus  → mesh dinamic, mint, Inter (default)
//   • bloom   → coral / lavandă / cream, Inter (rotunjit prin weight)
//   • garage  → charcoal / cupru / portocaliu metalic, JetBrains Mono pe cifre

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/app_settings_service.dart';
import 'nimbus_tokens.dart';

class ThemeVariantPalette {
  const ThemeVariantPalette({
    required this.darkScheme,
    required this.lightScheme,
    required this.risk,
    required this.headlineFont,
    required this.bodyFont,
    required this.numberFont,
  });

  final ColorScheme darkScheme;
  final ColorScheme lightScheme;
  final NimbusRiskColors risk;

  /// Headlines (display, headline)
  final TextStyle Function({
    double? fontSize,
    FontWeight? fontWeight,
    double? letterSpacing,
    double? height,
    List<FontFeature>? fontFeatures,
  }) headlineFont;

  /// Body & UI text
  final TextStyle Function({
    double? fontSize,
    FontWeight? fontWeight,
    double? letterSpacing,
    double? height,
  }) bodyFont;

  /// Big numbers (kilometraj, puncte, zile rămase)
  final TextStyle Function({
    double? fontSize,
    FontWeight? fontWeight,
    double? letterSpacing,
    double? height,
    List<FontFeature>? fontFeatures,
  }) numberFont;

  static ThemeVariantPalette of(AppThemeVariant variant) => switch (variant) {
        AppThemeVariant.nimbus => _nimbus,
        AppThemeVariant.bloom => _bloom,
        AppThemeVariant.garage => _garage,
      };
}

// ───────────────────────────── NIMBUS ─────────────────────────────

const _nimbusDark = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFF41E0B0),
  onPrimary: Color(0xFF003328),
  primaryContainer: Color(0xFF005140),
  onPrimaryContainer: Color(0xFF7CFFD2),
  secondary: Color(0xFFFF7A6B),
  onSecondary: Color(0xFF3A0A06),
  secondaryContainer: Color(0xFF6A1A12),
  onSecondaryContainer: Color(0xFFFFD9D3),
  tertiary: Color(0xFFFFC85A),
  onTertiary: Color(0xFF3A2A00),
  tertiaryContainer: Color(0xFF5A4200),
  onTertiaryContainer: Color(0xFFFFDF94),
  error: Color(0xFFFF4D5E),
  onError: Color(0xFF3A0610),
  errorContainer: Color(0xFF6A1322),
  onErrorContainer: Color(0xFFFFD3D9),
  surface: Color(0xFF0A0518),
  onSurface: Color(0xFFF2EEFF),
  surfaceContainerLowest: Color(0xFF050310),
  surfaceContainerLow: Color(0xFF0E0A22),
  surfaceContainer: Color(0xFF14102E),
  surfaceContainerHigh: Color(0xFF1B1638),
  surfaceContainerHighest: Color(0xFF231D45),
  onSurfaceVariant: Color(0xFFCFC9E5),
  outline: Color(0x4DFFFFFF),
  outlineVariant: Color(0x26FFFFFF),
  inverseSurface: Color(0xFFF2EEFF),
  onInverseSurface: Color(0xFF0A0518),
  inversePrimary: Color(0xFF005140),
  shadow: Colors.black,
  scrim: Color(0xCC000000),
  surfaceTint: Color(0xFF41E0B0),
);

const _nimbusLight = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF006C56),
  onPrimary: Colors.white,
  primaryContainer: Color(0xFF7CFFD2),
  onPrimaryContainer: Color(0xFF002018),
  secondary: Color(0xFFB13325),
  onSecondary: Colors.white,
  secondaryContainer: Color(0xFFFFD9D3),
  onSecondaryContainer: Color(0xFF410600),
  tertiary: Color(0xFF7A5A00),
  onTertiary: Colors.white,
  tertiaryContainer: Color(0xFFFFDF94),
  onTertiaryContainer: Color(0xFF261A00),
  error: Color(0xFFBA1A1A),
  onError: Colors.white,
  errorContainer: Color(0xFFFFDADA),
  onErrorContainer: Color(0xFF410006),
  surface: Color(0xFFFBF8FF),
  onSurface: Color(0xFF1B1B22),
  surfaceContainerLowest: Colors.white,
  surfaceContainerLow: Color(0xFFF5F2FB),
  surfaceContainer: Color(0xFFEFEDF7),
  surfaceContainerHigh: Color(0xFFE9E7F1),
  surfaceContainerHighest: Color(0xFFE3E1EC),
  onSurfaceVariant: Color(0xFF45464F),
  outline: Color(0x33000000),
  outlineVariant: Color(0x14000000),
  inverseSurface: Color(0xFF2F3038),
  onInverseSurface: Color(0xFFF2EEFF),
  inversePrimary: Color(0xFF41E0B0),
  shadow: Colors.black,
  scrim: Color(0xCC000000),
  surfaceTint: Color(0xFF006C56),
);

final _nimbus = ThemeVariantPalette(
  darkScheme: _nimbusDark,
  lightScheme: _nimbusLight,
  risk: NimbusRiskColors(
    safe: const Color(0xFF41E0B0),
    watch: const Color(0xFFFFC85A),
    warn: const Color(0xFFFF7A6B),
    critical: const Color(0xFFFF4D5E),
    safeSoft: const Color(0xFF41E0B0).withOpacity(0.18),
    watchSoft: const Color(0xFFFFC85A).withOpacity(0.18),
    warnSoft: const Color(0xFFFF7A6B).withOpacity(0.18),
    criticalSoft: const Color(0xFFFF4D5E).withOpacity(0.20),
  ),
  headlineFont: GoogleFonts.inter,
  bodyFont: GoogleFonts.inter,
  numberFont: GoogleFonts.inter,
);

// ───────────────────────────── BLOOM ─────────────────────────────
// Soft, warm. Mai feminin/jucăuș fără să devină pufos.

const _bloomDark = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFFFFB4C2),           // soft coral pink
  onPrimary: Color(0xFF4A0A1F),
  primaryContainer: Color(0xFF7A1B3A),
  onPrimaryContainer: Color(0xFFFFD8E0),
  secondary: Color(0xFFD9B3FF),         // lavender
  onSecondary: Color(0xFF2D0A4D),
  secondaryContainer: Color(0xFF4A1F7A),
  onSecondaryContainer: Color(0xFFEAD4FF),
  tertiary: Color(0xFFFFD89B),          // peach
  onTertiary: Color(0xFF3A2A00),
  tertiaryContainer: Color(0xFF5A4500),
  onTertiaryContainer: Color(0xFFFFE8C4),
  error: Color(0xFFFF6B85),
  onError: Color(0xFF3A0613),
  errorContainer: Color(0xFF6A1A28),
  onErrorContainer: Color(0xFFFFD8DD),
  surface: Color(0xFF1A0F1A),           // warm near-black
  onSurface: Color(0xFFFAF0F5),
  surfaceContainerLowest: Color(0xFF120912),
  surfaceContainerLow: Color(0xFF1F1322),
  surfaceContainer: Color(0xFF26172A),
  surfaceContainerHigh: Color(0xFF2E1D33),
  surfaceContainerHighest: Color(0xFF38233E),
  onSurfaceVariant: Color(0xFFE5D0DD),
  outline: Color(0x55FFB4C2),
  outlineVariant: Color(0x22FFB4C2),
  inverseSurface: Color(0xFFFAF0F5),
  onInverseSurface: Color(0xFF1A0F1A),
  inversePrimary: Color(0xFF7A1B3A),
  shadow: Colors.black,
  scrim: Color(0xCC1A0F1A),
  surfaceTint: Color(0xFFFFB4C2),
);

const _bloomLight = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFFB13355),
  onPrimary: Colors.white,
  primaryContainer: Color(0xFFFFD8E0),
  onPrimaryContainer: Color(0xFF410015),
  secondary: Color(0xFF6B3FA0),
  onSecondary: Colors.white,
  secondaryContainer: Color(0xFFEAD4FF),
  onSecondaryContainer: Color(0xFF26004D),
  tertiary: Color(0xFF7A5A00),
  onTertiary: Colors.white,
  tertiaryContainer: Color(0xFFFFE8C4),
  onTertiaryContainer: Color(0xFF261A00),
  error: Color(0xFFBA1A2A),
  onError: Colors.white,
  errorContainer: Color(0xFFFFDADD),
  onErrorContainer: Color(0xFF41000A),
  surface: Color(0xFFFFF7F9),
  onSurface: Color(0xFF1F1A1C),
  surfaceContainerLowest: Colors.white,
  surfaceContainerLow: Color(0xFFFCEFF3),
  surfaceContainer: Color(0xFFF7E5EB),
  surfaceContainerHigh: Color(0xFFF1DBE3),
  surfaceContainerHighest: Color(0xFFEBD1DB),
  onSurfaceVariant: Color(0xFF52424A),
  outline: Color(0x44000000),
  outlineVariant: Color(0x14000000),
  inverseSurface: Color(0xFF36292D),
  onInverseSurface: Color(0xFFFFF7F9),
  inversePrimary: Color(0xFFFFB4C2),
  shadow: Colors.black,
  scrim: Color(0xCC1A0F1A),
  surfaceTint: Color(0xFFB13355),
);

final _bloom = ThemeVariantPalette(
  darkScheme: _bloomDark,
  lightScheme: _bloomLight,
  risk: NimbusRiskColors(
    safe: const Color(0xFFA8E6CF),       // mint pastel
    watch: const Color(0xFFFFD89B),      // peach
    warn: const Color(0xFFFF8FA8),       // pink alert
    critical: const Color(0xFFFF5577),   // hot pink
    safeSoft: const Color(0xFFA8E6CF).withOpacity(0.20),
    watchSoft: const Color(0xFFFFD89B).withOpacity(0.20),
    warnSoft: const Color(0xFFFF8FA8).withOpacity(0.20),
    criticalSoft: const Color(0xFFFF5577).withOpacity(0.22),
  ),
  // Manrope = mai rotunjit, mai prietenos decât Inter
  headlineFont: GoogleFonts.manrope,
  bodyFont: GoogleFonts.manrope,
  numberFont: GoogleFonts.manrope,
);

// ───────────────────────────── GARAGE ─────────────────────────────
// Industrial. Charcoal profund + accente cupru. Cifrele pe JetBrains Mono.

const _garageDark = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFFE08A4B),           // copper / burnt orange
  onPrimary: Color(0xFF2A1308),
  primaryContainer: Color(0xFF5A3014),
  onPrimaryContainer: Color(0xFFFFD9B8),
  secondary: Color(0xFFB8B0A8),         // gunmetal silver
  onSecondary: Color(0xFF1F1C18),
  secondaryContainer: Color(0xFF3D3833),
  onSecondaryContainer: Color(0xFFE8E2D8),
  tertiary: Color(0xFFFFB300),          // signal amber
  onTertiary: Color(0xFF2D1F00),
  tertiaryContainer: Color(0xFF5A4000),
  onTertiaryContainer: Color(0xFFFFE08A),
  error: Color(0xFFFF5530),
  onError: Color(0xFF2D0500),
  errorContainer: Color(0xFF6A1308),
  onErrorContainer: Color(0xFFFFD0C2),
  surface: Color(0xFF0F0E0D),           // charcoal
  onSurface: Color(0xFFF0EBE0),
  surfaceContainerLowest: Color(0xFF080706),
  surfaceContainerLow: Color(0xFF15130F),
  surfaceContainer: Color(0xFF1C1915),
  surfaceContainerHigh: Color(0xFF24201A),
  surfaceContainerHighest: Color(0xFF2D2822),
  onSurfaceVariant: Color(0xFFC4BAA8),
  outline: Color(0x55E08A4B),
  outlineVariant: Color(0x1FE08A4B),
  inverseSurface: Color(0xFFF0EBE0),
  onInverseSurface: Color(0xFF0F0E0D),
  inversePrimary: Color(0xFF5A3014),
  shadow: Colors.black,
  scrim: Color(0xDD000000),
  surfaceTint: Color(0xFFE08A4B),
);

const _garageLight = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF8A4A1A),
  onPrimary: Colors.white,
  primaryContainer: Color(0xFFFFD9B8),
  onPrimaryContainer: Color(0xFF2A1308),
  secondary: Color(0xFF4D453D),
  onSecondary: Colors.white,
  secondaryContainer: Color(0xFFE8E2D8),
  onSecondaryContainer: Color(0xFF1F1C18),
  tertiary: Color(0xFF7A5500),
  onTertiary: Colors.white,
  tertiaryContainer: Color(0xFFFFE08A),
  onTertiaryContainer: Color(0xFF2D1F00),
  error: Color(0xFFA8341A),
  onError: Colors.white,
  errorContainer: Color(0xFFFFDAD0),
  onErrorContainer: Color(0xFF410000),
  surface: Color(0xFFF5F1EA),
  onSurface: Color(0xFF1C1A17),
  surfaceContainerLowest: Colors.white,
  surfaceContainerLow: Color(0xFFEFEAE0),
  surfaceContainer: Color(0xFFE9E2D5),
  surfaceContainerHigh: Color(0xFFE2DACB),
  surfaceContainerHighest: Color(0xFFDBD2C0),
  onSurfaceVariant: Color(0xFF4D453D),
  outline: Color(0x55000000),
  outlineVariant: Color(0x14000000),
  inverseSurface: Color(0xFF332F2A),
  onInverseSurface: Color(0xFFF5F1EA),
  inversePrimary: Color(0xFFE08A4B),
  shadow: Colors.black,
  scrim: Color(0xDD000000),
  surfaceTint: Color(0xFF8A4A1A),
);

final _garage = ThemeVariantPalette(
  darkScheme: _garageDark,
  lightScheme: _garageLight,
  risk: NimbusRiskColors(
    safe: const Color(0xFF7AE0A0),       // industrial green
    watch: const Color(0xFFFFB300),      // amber
    warn: const Color(0xFFFF7A30),       // signal orange
    critical: const Color(0xFFFF4020),   // alarm red
    safeSoft: const Color(0xFF7AE0A0).withOpacity(0.18),
    watchSoft: const Color(0xFFFFB300).withOpacity(0.18),
    warnSoft: const Color(0xFFFF7A30).withOpacity(0.18),
    criticalSoft: const Color(0xFFFF4020).withOpacity(0.22),
  ),
  // Inter pentru text obișnuit, JetBrains Mono pentru cifre — vibe technical.
  headlineFont: GoogleFonts.spaceGrotesk,
  bodyFont: GoogleFonts.inter,
  numberFont: GoogleFonts.jetBrainsMono,
);
