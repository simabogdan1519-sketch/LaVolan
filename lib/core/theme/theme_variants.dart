// lib/core/theme/theme_variants.dart
//
// 5 teme LaVolan: Blush, Midnight, Olive & Cream, Carbon Racing, Sky Mint.
// NimbusTheme rămâne shell-ul (layout, padding, glass), iar variantele
// schimbă culorile, fonturile, radii, chrome (paper/soft/glow/block) și
// indicatorul tab-urilor.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/app_settings_service.dart';
import 'nimbus_tokens.dart';

/// Subtilități vizuale care diferențiază temele:
///   • soft  — umbră difuză, fără bordură
///   • glow  — accent ca neon (Midnight)
///   • block — colțuri ascuțite, contraste tari (Carbon Racing)
///   • paper — bordură 1.5px, shadow hard (rezervat, nu folosit de cele 5)
enum LvChrome { soft, glow, block, paper }

enum LvTabIndicator { pill, underline, glow, block }

class ThemeVariantPalette {
  const ThemeVariantPalette({
    required this.darkScheme,
    required this.lightScheme,
    required this.risk,
    required this.headlineFont,
    required this.bodyFont,
    required this.numberFont,
    required this.headingWeight,
    required this.headingItalic,
    required this.headingUppercase,
    required this.headingTracking,
    required this.radiusCard,
    required this.radiusChip,
    required this.radiusFab,
    required this.radiusBtn,
    required this.cardShadow,
    required this.fabShadow,
    required this.chrome,
    required this.tabIndicator,
    required this.accent2,
    required this.surfaceAlt,
    required this.surface2,
    required this.inkSoft,
    required this.inkMute,
  });

  final ColorScheme darkScheme;
  final ColorScheme lightScheme;
  final NimbusRiskColors risk;

  /// Headlines (display, headline). Acceptă fontStyle pentru italic.
  final TextStyle Function({
    double? fontSize,
    FontWeight? fontWeight,
    double? letterSpacing,
    double? height,
    List<FontFeature>? fontFeatures,
    FontStyle? fontStyle,
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

  // tipografie heading
  final FontWeight headingWeight;
  final bool headingItalic;
  final bool headingUppercase;
  final double headingTracking;

  // forme
  final double radiusCard;
  final double radiusChip;
  final double radiusFab;
  final double radiusBtn;

  // umbre
  final List<BoxShadow> cardShadow;
  final List<BoxShadow> fabShadow;

  // chrome
  final LvChrome chrome;
  final LvTabIndicator tabIndicator;

  // tokens auxiliari
  final Color accent2;
  final Color surfaceAlt;
  final Color surface2;
  final Color inkSoft;
  final Color inkMute;

  static ThemeVariantPalette of(AppThemeVariant variant) => switch (variant) {
        AppThemeVariant.blush => _blush,
        AppThemeVariant.midnight => _midnight,
        AppThemeVariant.olive => _olive,
        AppThemeVariant.carbon => _carbon,
        AppThemeVariant.mint => _mint,
      };
}

// ───── helpers pentru google_fonts cu signature compatibilă ─────

/// Adapter peste GoogleFonts pentru heading — acceptă fontStyle.
TextStyle Function({
  double? fontSize,
  FontWeight? fontWeight,
  double? letterSpacing,
  double? height,
  List<FontFeature>? fontFeatures,
  FontStyle? fontStyle,
}) _heading(TextStyle Function({
  Color? color,
  Color? backgroundColor,
  double? fontSize,
  FontWeight? fontWeight,
  FontStyle? fontStyle,
  double? letterSpacing,
  double? wordSpacing,
  TextBaseline? textBaseline,
  double? height,
  Locale? locale,
  Paint? foreground,
  Paint? background,
  List<Shadow>? shadows,
  List<FontFeature>? fontFeatures,
  TextDecoration? decoration,
  Color? decorationColor,
  TextDecorationStyle? decorationStyle,
  double? decorationThickness,
}) source) {
  return ({fontSize, fontWeight, letterSpacing, height, fontFeatures, fontStyle}) =>
      source(
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        height: height,
        fontFeatures: fontFeatures,
        fontStyle: fontStyle,
      );
}

TextStyle Function({
  double? fontSize,
  FontWeight? fontWeight,
  double? letterSpacing,
  double? height,
}) _body(TextStyle Function({
  Color? color,
  Color? backgroundColor,
  double? fontSize,
  FontWeight? fontWeight,
  FontStyle? fontStyle,
  double? letterSpacing,
  double? wordSpacing,
  TextBaseline? textBaseline,
  double? height,
  Locale? locale,
  Paint? foreground,
  Paint? background,
  List<Shadow>? shadows,
  List<FontFeature>? fontFeatures,
  TextDecoration? decoration,
  Color? decorationColor,
  TextDecorationStyle? decorationStyle,
  double? decorationThickness,
}) source) {
  return ({fontSize, fontWeight, letterSpacing, height}) => source(
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        height: height,
      );
}

TextStyle Function({
  double? fontSize,
  FontWeight? fontWeight,
  double? letterSpacing,
  double? height,
  List<FontFeature>? fontFeatures,
}) _number(TextStyle Function({
  Color? color,
  Color? backgroundColor,
  double? fontSize,
  FontWeight? fontWeight,
  FontStyle? fontStyle,
  double? letterSpacing,
  double? wordSpacing,
  TextBaseline? textBaseline,
  double? height,
  Locale? locale,
  Paint? foreground,
  Paint? background,
  List<Shadow>? shadows,
  List<FontFeature>? fontFeatures,
  TextDecoration? decoration,
  Color? decorationColor,
  TextDecorationStyle? decorationStyle,
  double? decorationThickness,
}) source) {
  return ({fontSize, fontWeight, letterSpacing, height, fontFeatures}) => source(
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        height: height,
        fontFeatures: fontFeatures,
      );
}

NimbusRiskColors _risk({
  required Color ok,
  required Color warn,
  required Color danger,
}) {
  // mid = mix între warn și danger pentru tier "warn" (între watch și critical)
  final mid = Color.lerp(warn, danger, 0.5)!;
  return NimbusRiskColors(
    safe: ok,
    watch: warn,
    warn: mid,
    critical: danger,
    safeSoft: ok.withOpacity(0.18),
    watchSoft: warn.withOpacity(0.18),
    warnSoft: mid.withOpacity(0.20),
    criticalSoft: danger.withOpacity(0.22),
  );
}

// ─────────────────────────── 01 · BLUSH ───────────────────────────
// Roz drăguț, serif italic, accente aurii. Light.

const _blushSeed = Color(0xFFE85A96);
const _blushBg = Color(0xFFFDF3EE);
const _blushSurface = Colors.white;
const _blushInk = Color(0xFF3A1830);
const _blushAccent2 = Color(0xFFC9A36B);
const _blushSurfaceAlt = Color(0xFFFBE7E0);
const _blushSurface2 = Color(0xFFF7D9CF);
const _blushInkSoft = Color(0xFF6E3F5B);
const _blushInkMute = Color(0xFFA87B94);
const _blushOk = Color(0xFF7AA86A);
const _blushWarn = Color(0xFFE09B3C);
const _blushDanger = Color(0xFFD6406A);

final _blushLight = ColorScheme(
  brightness: Brightness.light,
  primary: _blushSeed,
  onPrimary: Colors.white,
  primaryContainer: _blushSurface2,
  onPrimaryContainer: _blushInk,
  secondary: _blushAccent2,
  onSecondary: Colors.white,
  secondaryContainer: _blushSurfaceAlt,
  onSecondaryContainer: _blushInk,
  tertiary: _blushAccent2,
  onTertiary: Colors.white,
  tertiaryContainer: _blushSurfaceAlt,
  onTertiaryContainer: _blushInk,
  error: _blushDanger,
  onError: Colors.white,
  errorContainer: const Color(0xFFFFD9DF),
  onErrorContainer: const Color(0xFF410016),
  surface: _blushSurface,
  onSurface: _blushInk,
  surfaceContainerLowest: Colors.white,
  surfaceContainerLow: _blushBg,
  surfaceContainer: _blushSurfaceAlt,
  surfaceContainerHigh: _blushSurfaceAlt,
  surfaceContainerHighest: _blushSurface2,
  onSurfaceVariant: _blushInkSoft,
  outline: _blushInkMute,
  outlineVariant: _blushSurfaceAlt,
  inverseSurface: _blushInk,
  onInverseSurface: _blushBg,
  inversePrimary: _blushSurface2,
  shadow: Colors.black,
  scrim: const Color(0xCC1A0A14),
  surfaceTint: _blushSeed,
);

// Blush e light-only — pentru "dark mode" reutilizăm light-ul. Flutter
// cere oricum un darkScheme valid chiar dacă themeMode e fix.
final _blushDark = _blushLight;

final _blush = ThemeVariantPalette(
  darkScheme: _blushDark,
  lightScheme: _blushLight,
  risk: _risk(ok: _blushOk, warn: _blushWarn, danger: _blushDanger),
  headlineFont: _heading(GoogleFonts.playfairDisplay),
  bodyFont: _body(GoogleFonts.manrope),
  numberFont: _number(GoogleFonts.manrope),
  headingWeight: FontWeight.w500,
  headingItalic: true,
  headingUppercase: false,
  headingTracking: -0.4,
  radiusCard: 24,
  radiusChip: 999,
  radiusFab: 28,
  radiusBtn: 18,
  cardShadow: const [
    BoxShadow(color: Color(0x40E85A96), blurRadius: 24, offset: Offset(0, 6), spreadRadius: -10),
  ],
  fabShadow: const [
    BoxShadow(color: Color(0x8CE85A96), blurRadius: 22, offset: Offset(0, 8), spreadRadius: -6),
  ],
  chrome: LvChrome.soft,
  tabIndicator: LvTabIndicator.pill,
  accent2: _blushAccent2,
  surfaceAlt: _blushSurfaceAlt,
  surface2: _blushSurface2,
  inkSoft: _blushInkSoft,
  inkMute: _blushInkMute,
);

// ─────────────────────────── 02 · MIDNIGHT ───────────────────────────
// OLED dark cu accent verde-neon. Vibe tech.

const _midnightSeed = Color(0xFF7DF9B3);
const _midnightBg = Color(0xFF06070A);
const _midnightSurface = Color(0xFF11141B);
const _midnightInk = Color(0xFFF3F5F9);
const _midnightAccent2 = Color(0xFF7AA9FF);
const _midnightSurfaceAlt = Color(0xFF1A1F2A);
const _midnightSurface2 = Color(0xFF262D3C);
const _midnightInkSoft = Color(0xFFAAB2C2);
const _midnightInkMute = Color(0xFF6C7384);
const _midnightOk = Color(0xFF7DF9B3);
const _midnightWarn = Color(0xFFFFD25A);
const _midnightDanger = Color(0xFFFF7077);

final _midnightDark = ColorScheme(
  brightness: Brightness.dark,
  primary: _midnightSeed,
  onPrimary: const Color(0xFF062014),
  primaryContainer: _midnightSurface2,
  onPrimaryContainer: _midnightInk,
  secondary: _midnightAccent2,
  onSecondary: _midnightInk,
  secondaryContainer: _midnightSurfaceAlt,
  onSecondaryContainer: _midnightInk,
  tertiary: _midnightAccent2,
  onTertiary: _midnightInk,
  tertiaryContainer: _midnightSurfaceAlt,
  onTertiaryContainer: _midnightInk,
  error: _midnightDanger,
  onError: const Color(0xFF3A0B10),
  errorContainer: const Color(0xFF6A1A22),
  onErrorContainer: const Color(0xFFFFD3D5),
  surface: _midnightSurface,
  onSurface: _midnightInk,
  surfaceContainerLowest: _midnightBg,
  surfaceContainerLow: const Color(0xFF0B0E14),
  surfaceContainer: _midnightSurfaceAlt,
  surfaceContainerHigh: _midnightSurface2,
  surfaceContainerHighest: const Color(0xFF2E364A),
  onSurfaceVariant: _midnightInkSoft,
  outline: _midnightInkMute,
  outlineVariant: _midnightSurfaceAlt,
  inverseSurface: _midnightInk,
  onInverseSurface: _midnightSurface,
  inversePrimary: const Color(0xFF005140),
  shadow: Colors.black,
  scrim: const Color(0xDD000000),
  surfaceTint: _midnightSeed,
);

final _midnightLight = _midnightDark; // dark-only

final _midnight = ThemeVariantPalette(
  darkScheme: _midnightDark,
  lightScheme: _midnightLight,
  risk: _risk(ok: _midnightOk, warn: _midnightWarn, danger: _midnightDanger),
  headlineFont: _heading(GoogleFonts.spaceGrotesk),
  bodyFont: _body(GoogleFonts.spaceGrotesk),
  numberFont: _number(GoogleFonts.jetBrainsMono),
  headingWeight: FontWeight.w600,
  headingItalic: false,
  headingUppercase: false,
  headingTracking: -0.4,
  radiusCard: 18,
  radiusChip: 8,
  radiusFab: 18,
  radiusBtn: 12,
  cardShadow: const [
    BoxShadow(color: Color(0xCC000000), blurRadius: 30, offset: Offset(0, 12), spreadRadius: -16),
  ],
  fabShadow: const [
    BoxShadow(color: Color(0x667DF9B3), blurRadius: 24, offset: Offset(0, 0)),
  ],
  chrome: LvChrome.glow,
  tabIndicator: LvTabIndicator.glow,
  accent2: _midnightAccent2,
  surfaceAlt: _midnightSurfaceAlt,
  surface2: _midnightSurface2,
  inkSoft: _midnightInkSoft,
  inkMute: _midnightInkMute,
);

// ─────────────────────────── 03 · OLIVE & CREAM ───────────────────────────
// Earthy, serif Lora, paletă măslinie.

const _oliveSeed = Color(0xFF6C7D3E);
const _oliveBg = Color(0xFFF1ECDF);
const _oliveSurface = Color(0xFFFAF6EC);
const _oliveInk = Color(0xFF2C2A1F);
const _oliveAccent2 = Color(0xFFB56548);
const _oliveSurfaceAlt = Color(0xFFE6DEC8);
const _oliveSurface2 = Color(0xFFD6CDB1);
const _oliveInkSoft = Color(0xFF5A553F);
const _oliveInkMute = Color(0xFF8A8367);
const _oliveOk = Color(0xFF6C7D3E);
const _oliveWarn = Color(0xFFC2902C);
const _oliveDanger = Color(0xFFB54025);

final _oliveLight = ColorScheme(
  brightness: Brightness.light,
  primary: _oliveSeed,
  onPrimary: Colors.white,
  primaryContainer: _oliveSurface2,
  onPrimaryContainer: _oliveInk,
  secondary: _oliveAccent2,
  onSecondary: Colors.white,
  secondaryContainer: _oliveSurfaceAlt,
  onSecondaryContainer: _oliveInk,
  tertiary: _oliveAccent2,
  onTertiary: Colors.white,
  tertiaryContainer: _oliveSurfaceAlt,
  onTertiaryContainer: _oliveInk,
  error: _oliveDanger,
  onError: Colors.white,
  errorContainer: const Color(0xFFFFD8CE),
  onErrorContainer: const Color(0xFF400A00),
  surface: _oliveSurface,
  onSurface: _oliveInk,
  surfaceContainerLowest: Colors.white,
  surfaceContainerLow: _oliveBg,
  surfaceContainer: _oliveSurfaceAlt,
  surfaceContainerHigh: _oliveSurfaceAlt,
  surfaceContainerHighest: _oliveSurface2,
  onSurfaceVariant: _oliveInkSoft,
  outline: _oliveInkMute,
  outlineVariant: _oliveSurfaceAlt,
  inverseSurface: _oliveInk,
  onInverseSurface: _oliveBg,
  inversePrimary: _oliveSurface2,
  shadow: Colors.black,
  scrim: const Color(0xCC2C2A1F),
  surfaceTint: _oliveSeed,
);

final _oliveDark = _oliveLight; // light-only

final _olive = ThemeVariantPalette(
  darkScheme: _oliveDark,
  lightScheme: _oliveLight,
  risk: _risk(ok: _oliveOk, warn: _oliveWarn, danger: _oliveDanger),
  headlineFont: _heading(GoogleFonts.lora),
  bodyFont: _body(GoogleFonts.dmSans),
  numberFont: _number(GoogleFonts.jetBrainsMono),
  headingWeight: FontWeight.w500,
  headingItalic: false,
  headingUppercase: false,
  headingTracking: -0.2,
  radiusCard: 14,
  radiusChip: 999,
  radiusFab: 24,
  radiusBtn: 12,
  cardShadow: const [
    BoxShadow(color: Color(0x402C2A1F), blurRadius: 14, offset: Offset(0, 4), spreadRadius: -8),
  ],
  fabShadow: const [
    BoxShadow(color: Color(0x662C2A1F), blurRadius: 16, offset: Offset(0, 6), spreadRadius: -6),
  ],
  chrome: LvChrome.soft,
  tabIndicator: LvTabIndicator.underline,
  accent2: _oliveAccent2,
  surfaceAlt: _oliveSurfaceAlt,
  surface2: _oliveSurface2,
  inkSoft: _oliveInkSoft,
  inkMute: _oliveInkMute,
);

// ─────────────────────────── 04 · CARBON RACING ───────────────────────────
// Sport, Bebas Neue uppercase, roșu Ferrari. Dark.

const _carbonSeed = Color(0xFFE10600);
const _carbonBg = Color(0xFF0D0D0F);
const _carbonSurface = Color(0xFF16171A);
const _carbonInk = Color(0xFFF5F5F6);
const _carbonAccent2 = Color(0xFFF5F5F6);
const _carbonSurfaceAlt = Color(0xFF1F2125);
const _carbonSurface2 = Color(0xFF2A2C31);
const _carbonInkSoft = Color(0xFFA4A6AB);
const _carbonInkMute = Color(0xFF6A6C72);
const _carbonOk = Color(0xFF7BE58C);
const _carbonWarn = Color(0xFFF5B400);
const _carbonDanger = Color(0xFFE10600);

final _carbonDark = ColorScheme(
  brightness: Brightness.dark,
  primary: _carbonSeed,
  onPrimary: Colors.white,
  primaryContainer: _carbonSurface2,
  onPrimaryContainer: _carbonInk,
  // accent2 e alb — folosim surface2 ca container pentru chip-uri secondary
  // ca să nu pierdem contrast (vezi README #6)
  secondary: _carbonAccent2,
  onSecondary: _carbonBg,
  secondaryContainer: _carbonSurface2,
  onSecondaryContainer: _carbonInk,
  tertiary: _carbonAccent2,
  onTertiary: _carbonBg,
  tertiaryContainer: _carbonSurface2,
  onTertiaryContainer: _carbonInk,
  error: _carbonDanger,
  onError: Colors.white,
  errorContainer: const Color(0xFF6A0D08),
  onErrorContainer: const Color(0xFFFFD0CC),
  surface: _carbonSurface,
  onSurface: _carbonInk,
  surfaceContainerLowest: _carbonBg,
  surfaceContainerLow: const Color(0xFF101113),
  surfaceContainer: _carbonSurfaceAlt,
  surfaceContainerHigh: _carbonSurface2,
  surfaceContainerHighest: const Color(0xFF34363B),
  onSurfaceVariant: _carbonInkSoft,
  outline: _carbonInkMute,
  outlineVariant: _carbonSurfaceAlt,
  inverseSurface: _carbonInk,
  onInverseSurface: _carbonSurface,
  inversePrimary: const Color(0xFF6A0D08),
  shadow: Colors.black,
  scrim: const Color(0xDD000000),
  surfaceTint: _carbonSeed,
);

final _carbonLight = _carbonDark; // dark-only

final _carbon = ThemeVariantPalette(
  darkScheme: _carbonDark,
  lightScheme: _carbonLight,
  risk: _risk(ok: _carbonOk, warn: _carbonWarn, danger: _carbonDanger),
  headlineFont: _heading(GoogleFonts.bebasNeue),
  bodyFont: _body(GoogleFonts.dmSans),
  numberFont: _number(GoogleFonts.jetBrainsMono),
  headingWeight: FontWeight.w400,
  headingItalic: false,
  headingUppercase: true,
  headingTracking: 0.4,
  radiusCard: 4,
  radiusChip: 2,
  radiusFab: 4,
  radiusBtn: 2,
  cardShadow: const [
    BoxShadow(color: Color(0xB3000000), blurRadius: 24, offset: Offset(0, 8), spreadRadius: -10),
  ],
  fabShadow: const [
    BoxShadow(color: Color(0x80E10600), blurRadius: 18, offset: Offset(0, 8), spreadRadius: -4),
  ],
  chrome: LvChrome.block,
  tabIndicator: LvTabIndicator.block,
  accent2: _carbonAccent2,
  surfaceAlt: _carbonSurfaceAlt,
  surface2: _carbonSurface2,
  inkSoft: _carbonInkSoft,
  inkMute: _carbonInkMute,
);

// ─────────────────────────── 05 · SKY MINT ───────────────────────────
// Pastel rotunjit, breezy. Light.

const _mintSeed = Color(0xFF3FB89A);
const _mintBg = Color(0xFFE9F6F1);
const _mintSurface = Colors.white;
const _mintInk = Color(0xFF0E3A36);
const _mintAccent2 = Color(0xFF7CB6E0);
const _mintSurfaceAlt = Color(0xFFD6EDE4);
const _mintSurface2 = Color(0xFFBCE0CF);
const _mintInkSoft = Color(0xFF3F6E69);
const _mintInkMute = Color(0xFF7BA39D);
const _mintOk = Color(0xFF3FB89A);
const _mintWarn = Color(0xFFE0A93F);
const _mintDanger = Color(0xFFE0676A);

final _mintLight = ColorScheme(
  brightness: Brightness.light,
  primary: _mintSeed,
  onPrimary: Colors.white,
  primaryContainer: _mintSurface2,
  onPrimaryContainer: _mintInk,
  secondary: _mintAccent2,
  onSecondary: Colors.white,
  secondaryContainer: _mintSurfaceAlt,
  onSecondaryContainer: _mintInk,
  tertiary: _mintAccent2,
  onTertiary: Colors.white,
  tertiaryContainer: _mintSurfaceAlt,
  onTertiaryContainer: _mintInk,
  error: _mintDanger,
  onError: Colors.white,
  errorContainer: const Color(0xFFFFDADB),
  onErrorContainer: const Color(0xFF410010),
  surface: _mintSurface,
  onSurface: _mintInk,
  surfaceContainerLowest: Colors.white,
  surfaceContainerLow: _mintBg,
  surfaceContainer: _mintSurfaceAlt,
  surfaceContainerHigh: _mintSurfaceAlt,
  surfaceContainerHighest: _mintSurface2,
  onSurfaceVariant: _mintInkSoft,
  outline: _mintInkMute,
  outlineVariant: _mintSurfaceAlt,
  inverseSurface: _mintInk,
  onInverseSurface: _mintBg,
  inversePrimary: _mintSurface2,
  shadow: Colors.black,
  scrim: const Color(0xCC0E3A36),
  surfaceTint: _mintSeed,
);

final _mintDark = _mintLight; // light-only

final _mint = ThemeVariantPalette(
  darkScheme: _mintDark,
  lightScheme: _mintLight,
  risk: _risk(ok: _mintOk, warn: _mintWarn, danger: _mintDanger),
  headlineFont: _heading(GoogleFonts.outfit),
  bodyFont: _body(GoogleFonts.outfit),
  numberFont: _number(GoogleFonts.jetBrainsMono),
  headingWeight: FontWeight.w600,
  headingItalic: false,
  headingUppercase: false,
  headingTracking: -0.4,
  radiusCard: 28,
  radiusChip: 999,
  radiusFab: 28,
  radiusBtn: 999,
  cardShadow: const [
    BoxShadow(color: Color(0x593FB89A), blurRadius: 24, offset: Offset(0, 8), spreadRadius: -12),
  ],
  fabShadow: const [
    BoxShadow(color: Color(0x8C3FB89A), blurRadius: 18, offset: Offset(0, 8), spreadRadius: -6),
  ],
  chrome: LvChrome.soft,
  tabIndicator: LvTabIndicator.pill,
  accent2: _mintAccent2,
  surfaceAlt: _mintSurfaceAlt,
  surface2: _mintSurface2,
  inkSoft: _mintInkSoft,
  inkMute: _mintInkMute,
);
