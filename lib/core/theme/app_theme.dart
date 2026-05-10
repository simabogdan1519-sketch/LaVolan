// lib/core/theme/app_theme.dart
//
// LaVolan — Tema "Nimbus" cu 5 variante (Blush, Midnight, Olive & Cream,
// Carbon Racing, Sky Mint).
//
// Folosire:
//   final variant = ref.watch(appSettingsProvider).themeVariant;
//   MaterialApp(
//     theme: NimbusTheme.light(variant),
//     darkTheme: NimbusTheme.dark(variant),
//     themeMode: NimbusTheme.themeModeFor(variant),
//   );

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/app_settings_service.dart';
import 'nimbus_tokens.dart';
import 'theme_variants.dart';

class NimbusTheme {
  NimbusTheme._();

  static ThemeData light([AppThemeVariant variant = AppThemeVariant.midnight]) {
    final palette = ThemeVariantPalette.of(variant);
    return _buildTheme(palette.lightScheme, palette);
  }

  static ThemeData dark([AppThemeVariant variant = AppThemeVariant.midnight]) {
    final palette = ThemeVariantPalette.of(variant);
    return _buildTheme(palette.darkScheme, palette);
  }

  /// Modul preferat pentru fiecare temă (Blush/Olive/Mint sunt light, restul
  /// sunt dark).
  static ThemeMode themeModeFor(AppThemeVariant variant) {
    switch (variant) {
      case AppThemeVariant.blush:
      case AppThemeVariant.olive:
      case AppThemeVariant.mint:
        return ThemeMode.light;
      case AppThemeVariant.midnight:
      case AppThemeVariant.carbon:
        return ThemeMode.dark;
    }
  }

  // ──────────── TextTheme ────────────
  static TextTheme _textTheme(Color onSurface, ThemeVariantPalette p) {
    final h = p.headlineFont;
    final b = p.bodyFont;
    final n = p.numberFont;
    final fv = const [FontFeature.tabularFigures()];

    final headingWeight = p.headingWeight;
    final headingStyle = p.headingItalic ? FontStyle.italic : FontStyle.normal;
    final tracking = p.headingTracking;

    TextStyle heading({required double size, double height = 1.1}) => h(
          fontSize: size,
          fontWeight: headingWeight,
          letterSpacing: tracking,
          height: height,
          fontStyle: headingStyle,
        );

    final theme = TextTheme(
      // numerele rămân pe numberFont (mono pentru cifre tabulare)
      displayLarge: n(fontSize: 56, fontWeight: FontWeight.w800, letterSpacing: -2.0, height: 1.0, fontFeatures: fv),
      displayMedium: n(fontSize: 44, fontWeight: FontWeight.w800, letterSpacing: -1.4, height: 1.05, fontFeatures: fv),
      displaySmall: n(fontSize: 34, fontWeight: FontWeight.w700, letterSpacing: -1.0, height: 1.1, fontFeatures: fv),

      // headlines pe fontul de heading + weight/italic/tracking din paletă
      headlineLarge: heading(size: 28, height: 1.15),
      headlineMedium: heading(size: 24, height: 1.2),
      headlineSmall: heading(size: 20, height: 1.25),
      titleLarge: heading(size: 18, height: 1.3),

      titleMedium: b(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: -0.1, height: 1.35),
      titleSmall: b(fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.0, height: 1.4),
      bodyLarge: b(fontSize: 15, fontWeight: FontWeight.w500, letterSpacing: 0.0, height: 1.5),
      bodyMedium: b(fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: 0.0, height: 1.5),
      bodySmall: b(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.1, height: 1.5),
      labelLarge: b(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, height: 1.3),
      labelMedium: b(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.1, height: 1.3),
      labelSmall: b(fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1.0, height: 1.3),
    );
    return theme.apply(bodyColor: onSurface, displayColor: onSurface);
  }

  // ──────────── ThemeData ────────────
  static ThemeData _buildTheme(ColorScheme cs, ThemeVariantPalette palette) {
    final txt = _textTheme(cs.onSurface, palette);
    final tokens = NimbusTokens.fromBrightness(cs.brightness)
        .copyWith(risk: palette.risk);

    final isDark = cs.brightness == Brightness.dark;
    final isBlock = palette.chrome == LvChrome.block;
    final isPaper = palette.chrome == LvChrome.paper;

    // Border subtil pe carduri/inputs în temele block/paper.
    final BorderSide chromeBorder = (isBlock || isPaper)
        ? BorderSide(color: cs.onSurface.withOpacity(isPaper ? 1 : 0.18), width: isPaper ? 1.5 : 0.8)
        : BorderSide.none;

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      brightness: cs.brightness,
      textTheme: txt,
      scaffoldBackgroundColor: cs.surface,
      canvasColor: cs.surface,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
      }),

      cardTheme: CardTheme(
        color: cs.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withOpacity(isDark ? 0.6 : 0.18),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(palette.radiusCard),
          side: chromeBorder,
        ),
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
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(color: cs.onSurface, size: 22),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          textStyle: txt.titleSmall,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(palette.radiusBtn),
          ),
          minimumSize: const Size(0, 48),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          elevation: 0,
          textStyle: txt.titleSmall,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(palette.radiusBtn),
          ),
          minimumSize: const Size(0, 48),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: cs.primary,
          textStyle: txt.titleSmall,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(palette.radiusBtn),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.onSurface,
          textStyle: txt.titleSmall,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          side: BorderSide(color: cs.outline.withOpacity(0.4), width: 0.8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(palette.radiusBtn),
          ),
          minimumSize: const Size(0, 48),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: cs.onSurface,
          backgroundColor: (isDark ? Colors.white : Colors.black).withOpacity(isDark ? 0.10 : 0.05),
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(10),
          minimumSize: const Size(44, 44),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: palette.surfaceAlt,
        selectedColor: cs.primary.withOpacity(0.18),
        side: BorderSide(color: cs.outlineVariant, width: 0.5),
        labelStyle: txt.labelLarge?.copyWith(color: cs.onSurface),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(palette.radiusChip),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: cs.outlineVariant, thickness: 0.5, space: 0,
      ),

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
        backgroundColor: cs.surface.withOpacity(isDark ? 0.85 : 0.96),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalBackgroundColor: cs.surface.withOpacity(isDark ? 0.85 : 0.96),
        modalElevation: 0,
        showDragHandle: true,
        dragHandleColor: cs.outline,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(palette.radiusCard * 1.2)),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(palette.radiusFab),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surfaceAlt.withOpacity(isDark ? 1 : 0.6),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: txt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        labelStyle: txt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        floatingLabelStyle: txt.labelLarge?.copyWith(color: cs.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(palette.radiusBtn),
          borderSide: BorderSide(color: cs.outlineVariant, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(palette.radiusBtn),
          borderSide: BorderSide(color: cs.outlineVariant, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(palette.radiusBtn),
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(palette.radiusBtn),
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

      extensions: <ThemeExtension<dynamic>>[tokens],
    );
  }
}
