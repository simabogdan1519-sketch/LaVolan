// lib/core/theme/app_theme.dart
//
// LaVolan — Tema "Nimbus" cu variante (Nimbus / Bloom / Garage).
//
// Folosire:
//   final variant = ref.watch(appSettingsProvider).themeVariant;
//   MaterialApp(
//     theme: NimbusTheme.light(variant),
//     darkTheme: NimbusTheme.dark(variant),
//     themeMode: ThemeMode.dark,
//   );

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/app_settings_service.dart';
import 'nimbus_tokens.dart';
import 'theme_variants.dart';

class NimbusTheme {
  NimbusTheme._();

  static ThemeData light([AppThemeVariant variant = AppThemeVariant.nimbus]) {
    final palette = ThemeVariantPalette.of(variant);
    return _buildTheme(palette.lightScheme, palette);
  }

  static ThemeData dark([AppThemeVariant variant = AppThemeVariant.nimbus]) {
    final palette = ThemeVariantPalette.of(variant);
    return _buildTheme(palette.darkScheme, palette);
  }

  // ──────────── TextTheme ────────────
  static TextTheme _textTheme(Color onSurface, ThemeVariantPalette p) {
    final h = p.headlineFont;
    final b = p.bodyFont;
    final n = p.numberFont;
    final fv = const [FontFeature.tabularFigures()];

    final theme = TextTheme(
      displayLarge: n(fontSize: 56, fontWeight: FontWeight.w800, letterSpacing: -2.0, height: 1.0, fontFeatures: fv),
      displayMedium: n(fontSize: 44, fontWeight: FontWeight.w800, letterSpacing: -1.4, height: 1.05, fontFeatures: fv),
      displaySmall: n(fontSize: 34, fontWeight: FontWeight.w700, letterSpacing: -1.0, height: 1.1, fontFeatures: fv),
      headlineLarge: h(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.6, height: 1.15),
      headlineMedium: h(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.5, height: 1.2),
      headlineSmall: h(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.4, height: 1.25),
      titleLarge: h(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3, height: 1.3),
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
        systemOverlayStyle: cs.brightness == Brightness.dark
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          minimumSize: const Size(0, 48),
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

      extensions: <ThemeExtension<dynamic>>[tokens],
    );
  }
}
