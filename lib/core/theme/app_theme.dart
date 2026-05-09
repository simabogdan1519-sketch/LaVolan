// lib/core/theme/app_theme.dart
//
// LaVolan — Tema "Nimbus".
// Ideea: surface-urile sunt sticlă translucentă peste un mesh gradient
// care se schimbă cu vehiculul selectat. Material 3 standard nu poate
// reda glass-ul (cere BackdropFilter), așa că:
//   • [Theme] livrează schema de bază (culori, tipografie, padding-uri).
//   • [NimbusTokens] (ThemeExtension) livrează tokeni proprii care nu
//     încap în ColorScheme: tinte per vehicul, scări de glass, risk
//     colors etc.
//   • [GlassCard] și [MeshBackdrop] (în nimbus_widgets.dart) fac
//     compoziția vizuală — folosește-le în locul Card-ului standard.
//
// Mod de folosire:
//   MaterialApp(
//     theme: NimbusTheme.light(),
//     darkTheme: NimbusTheme.dark(), // recomandat — Nimbus e gândit dark
//     themeMode: ThemeMode.dark,
//   );

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'nimbus_tokens.dart';

class NimbusTheme {
  NimbusTheme._();

  // ──────────── primitive culorice ────────────
  // Mint = accent OK / pozitiv / interactiv principal.
  // Coral / red = warn & critical.
  // Amber = watch.
  // Surface-ul "ink" e fallback-ul când nu desenezi mesh sub el.
  static const Color mint    = Color(0xFF41E0B0);
  static const Color coral   = Color(0xFFFF7A6B);
  static const Color amber   = Color(0xFFFFC85A);
  static const Color red     = Color(0xFFFF4D5E);

  static const Color inkDeep = Color(0xFF0A0518); // BMW base — cel mai închis tint
  static const Color inkSoft = Color(0xFF1B2342); // Passat base

  // ──────────── ColorScheme ────────────
  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: mint,
    onPrimary: Color(0xFF003328),
    primaryContainer: Color(0xFF005140),
    onPrimaryContainer: Color(0xFF7CFFD2),

    secondary: coral,
    onSecondary: Color(0xFF3A0A06),
    secondaryContainer: Color(0xFF6A1A12),
    onSecondaryContainer: Color(0xFFFFD9D3),

    tertiary: amber,
    onTertiary: Color(0xFF3A2A00),
    tertiaryContainer: Color(0xFF5A4200),
    onTertiaryContainer: Color(0xFFFFDF94),

    error: red,
    onError: Color(0xFF3A0610),
    errorContainer: Color(0xFF6A1322),
    onErrorContainer: Color(0xFFFFD3D9),

    surface: inkDeep,
    onSurface: Color(0xFFF2EEFF),
    surfaceContainerLowest: Color(0xFF050310),
    surfaceContainerLow:    Color(0xFF0E0A22),
    surfaceContainer:       Color(0xFF14102E),
    surfaceContainerHigh:   Color(0xFF1B1638),
    surfaceContainerHighest:Color(0xFF231D45),

    onSurfaceVariant: Color(0xFFCFC9E5),
    outline: Color(0x4DFFFFFF),         // border-ul de glass (~30% white)
    outlineVariant: Color(0x26FFFFFF),  // hairline (~15% white)

    inverseSurface: Color(0xFFF2EEFF),
    onInverseSurface: inkDeep,
    inversePrimary: Color(0xFF005140),

    shadow: Colors.black,
    scrim: Color(0xCC000000),
    surfaceTint: mint,
  );

  // varianta "light" e mai puțin folosită, dar o livrăm pentru completitudine
  // (când userul forțează light mode, păstrăm vibe-ul soft pastel).
  static const ColorScheme _lightScheme = ColorScheme(
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
    surfaceContainerLow:    Color(0xFFF5F2FB),
    surfaceContainer:       Color(0xFFEFEDF7),
    surfaceContainerHigh:   Color(0xFFE9E7F1),
    surfaceContainerHighest:Color(0xFFE3E1EC),
    onSurfaceVariant: Color(0xFF45464F),
    outline: Color(0x33000000),
    outlineVariant: Color(0x14000000),
    inverseSurface: Color(0xFF2F3038),
    onInverseSurface: Color(0xFFF2EEFF),
    inversePrimary: mint,
    shadow: Colors.black,
    scrim: Color(0xCC000000),
    surfaceTint: Color(0xFF006C56),
  );

  // ──────────── TextTheme (Inter) ────────────
  // Roluri Material 3 (display / headline / title / body / label) mapate
  // la weights & line-heights Inter. tabular-nums pe orice arată cifre.
  static TextTheme _textTheme(Color onSurface) {
    final base = GoogleFonts.interTextTheme(
      Typography.material2021(platform: TargetPlatform.iOS).black,
    );
    final fv = const [FontFeature.tabularFigures()];
    return base.copyWith(
      // headline-uri editoriale (kilometraj uriaș, "12 zile rămase")
      displayLarge:  GoogleFonts.inter(fontSize: 56, fontWeight: FontWeight.w800, letterSpacing: -2.0, height: 1.0,  fontFeatures: fv),
      displayMedium: GoogleFonts.inter(fontSize: 44, fontWeight: FontWeight.w800, letterSpacing: -1.4, height: 1.05, fontFeatures: fv),
      displaySmall:  GoogleFonts.inter(fontSize: 34, fontWeight: FontWeight.w700, letterSpacing: -1.0, height: 1.1,  fontFeatures: fv),

      headlineLarge:  GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.6, height: 1.15),
      headlineMedium: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.5, height: 1.2),
      headlineSmall:  GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.4, height: 1.25),

      // titluri carduri ("Următorul document", "Mentenanță")
      titleLarge:  GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3, height: 1.3),
      titleMedium: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: -0.1, height: 1.35),
      titleSmall:  GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.0,  height: 1.4),

      bodyLarge:  GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, letterSpacing: 0.0, height: 1.5),
      bodyMedium: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: 0.0, height: 1.5),
      bodySmall:  GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.1, height: 1.5),

      // label-uri eyebrow uppercase (metadata, micro-titluri)
      labelLarge:  GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2,  height: 1.3),
      labelMedium: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.1,  height: 1.3),
      labelSmall:  GoogleFonts.inter(fontSize: 9,  fontWeight: FontWeight.w600, letterSpacing: 1.0,  height: 1.3),
    ).apply(bodyColor: onSurface, displayColor: onSurface);
  }

  // ──────────── ThemeData ────────────
  static ThemeData _buildTheme(ColorScheme cs) {
    final txt = _textTheme(cs.onSurface);

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      brightness: cs.brightness,
      textTheme: txt,
      // Scaffold-ul rămâne transparent; mesh-ul îl pictezi tu pe sub.
      // Setează totuși o culoare solidă — fallback când nu există MeshBackdrop.
      scaffoldBackgroundColor: cs.surface,
      canvasColor: cs.surface,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.iOS:     CupertinoPageTransitionsBuilder(),
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
      }),

      // Card-ul standard rămâne disponibil ca fallback (e.g. Dialog),
      // dar pentru carduri vizibile folosește GlassCard direct.
      cardTheme: CardTheme(
        color: cs.surfaceContainer.withOpacity(0.45),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withOpacity(0.18),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 56,
        titleTextStyle: txt.titleLarge,
        foregroundColor: cs.onSurface,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: IconThemeData(color: cs.onSurface, size: 22),
      ),

      // Buton primar = pill mint, butonul "tonal" = glass tinted.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          textStyle: txt.titleSmall,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          minimumSize: const Size(0, 48), // hit target ≥ 44pt
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: cs.primary,
          textStyle: txt.titleSmall,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.onSurface,
          textStyle: txt.titleSmall,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          side: BorderSide(color: cs.outline, width: 0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          minimumSize: const Size(0, 48),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: cs.onSurface,
          backgroundColor: Colors.white.withOpacity(0.10),
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(10),
          minimumSize: const Size(44, 44),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: Colors.white.withOpacity(0.12),
        selectedColor: Colors.white.withOpacity(0.28),
        side: BorderSide(color: cs.outlineVariant, width: 0.5),
        labelStyle: txt.labelLarge?.copyWith(color: cs.onSurface),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),

      dividerTheme: DividerThemeData(
        color: cs.outlineVariant, thickness: 0.5, space: 0,
      ),

      // Bottom nav glass — fundal transparent, indicator pill mint.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        indicatorColor: cs.primary.withOpacity(0.18),
        elevation: 0,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected)
            ? txt.labelMedium!.copyWith(color: cs.primary, fontWeight: FontWeight.w700)
            : txt.labelMedium!.copyWith(color: cs.onSurfaceVariant)),
        iconTheme: WidgetStateProperty.resolveWith((s) =>
          IconThemeData(color: s.contains(WidgetState.selected) ? cs.primary : cs.onSurfaceVariant, size: 22)),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cs.surfaceContainer.withOpacity(0.7),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalBackgroundColor: cs.surfaceContainer.withOpacity(0.7),
        modalElevation: 0,
        showDragHandle: true,
        dragHandleColor: cs.outline,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),

      // Input fields — glass ușor, hairline 0.5px.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: txt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        labelStyle: txt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        floatingLabelStyle: txt.labelLarge?.copyWith(color: cs.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.outlineVariant, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.outlineVariant, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.error, width: 1),
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: cs.primary,
        linearTrackColor: cs.outlineVariant,
        circularTrackColor: cs.outlineVariant,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? Colors.white : cs.onSurfaceVariant),
        trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? cs.primary : cs.surfaceContainerHigh),
      ),

      // Tokenii Nimbus — îi accesezi cu Theme.of(context).extension<NimbusTokens>()!
      extensions: <ThemeExtension<dynamic>>[
        NimbusTokens.fromBrightness(cs.brightness),
      ],
    );
  }

  static ThemeData light() => _buildTheme(_lightScheme);
  static ThemeData dark()  => _buildTheme(_darkScheme);
}
