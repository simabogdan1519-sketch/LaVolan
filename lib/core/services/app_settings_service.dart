import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/storage_service.dart';

/// Visual theme variants. Each one swaps colors, fonts, glass behavior.
enum AppThemeVariant {
  /// Default — neutral, mesh-dynamic per vehicle.
  nimbus,

  /// Soft, warm pastels — coral / lavender / cream. Friendlier feel.
  bloom,

  /// Industrial — deep charcoal, copper accents, monospaced numbers.
  garage,
}

extension AppThemeVariantInfo on AppThemeVariant {
  String get labelRo => switch (this) {
        AppThemeVariant.nimbus => 'Nimbus',
        AppThemeVariant.bloom => 'Bloom',
        AppThemeVariant.garage => 'Garage',
      };

  String get descriptionRo => switch (this) {
        AppThemeVariant.nimbus =>
          'Default. Mesh dinamic, accente mint, paletă rece.',
        AppThemeVariant.bloom =>
          'Pasteluri calde, coral și lavandă. Mai jucăuș.',
        AppThemeVariant.garage =>
          'Industrial, accente cupru, cifre monospace. Auto.',
      };

  IconData get iconData => switch (this) {
        AppThemeVariant.nimbus => Icons.cloud_outlined,
        AppThemeVariant.bloom => Icons.local_florist_outlined,
        AppThemeVariant.garage => Icons.build_outlined,
      };
}

// ────────────────────────── Service ──────────────────────────

class AppSettingsService {
  AppSettingsService._();
  static final AppSettingsService instance = AppSettingsService._();

  static const _kOnboarded = 'onboarded';
  static const _kUserName = 'user_name';
  static const _kThemeVariant = 'theme_variant';

  bool get hasOnboarded =>
      StorageService.instance.settings.get(_kOnboarded, defaultValue: false)
          as bool;

  Future<void> setOnboarded(bool value) async =>
      StorageService.instance.settings.put(_kOnboarded, value);

  String? get userName =>
      StorageService.instance.settings.get(_kUserName) as String?;

  Future<void> setUserName(String? value) async {
    if (value == null || value.trim().isEmpty) {
      await StorageService.instance.settings.delete(_kUserName);
    } else {
      await StorageService.instance.settings.put(_kUserName, value.trim());
    }
  }

  AppThemeVariant get themeVariant {
    final raw = StorageService.instance.settings
        .get(_kThemeVariant, defaultValue: AppThemeVariant.nimbus.name) as String;
    return AppThemeVariant.values.firstWhere(
      (v) => v.name == raw,
      orElse: () => AppThemeVariant.nimbus,
    );
  }

  Future<void> setThemeVariant(AppThemeVariant variant) async =>
      StorageService.instance.settings.put(_kThemeVariant, variant.name);
}

// ────────────────────────── Riverpod state ──────────────────────────

class AppSettings {
  const AppSettings({
    required this.hasOnboarded,
    required this.themeVariant,
    required this.userName,
  });
  final bool hasOnboarded;
  final AppThemeVariant themeVariant;
  final String? userName;

  AppSettings copyWith({
    bool? hasOnboarded,
    AppThemeVariant? themeVariant,
    String? userName,
    bool clearUserName = false,
  }) =>
      AppSettings(
        hasOnboarded: hasOnboarded ?? this.hasOnboarded,
        themeVariant: themeVariant ?? this.themeVariant,
        userName: clearUserName ? null : (userName ?? this.userName),
      );
}

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  AppSettingsNotifier()
      : super(AppSettings(
          hasOnboarded: AppSettingsService.instance.hasOnboarded,
          themeVariant: AppSettingsService.instance.themeVariant,
          userName: AppSettingsService.instance.userName,
        ));

  Future<void> completeOnboarding({String? name}) async {
    await AppSettingsService.instance.setOnboarded(true);
    if (name != null) await AppSettingsService.instance.setUserName(name);
    state = state.copyWith(hasOnboarded: true, userName: name);
  }

  Future<void> setThemeVariant(AppThemeVariant variant) async {
    await AppSettingsService.instance.setThemeVariant(variant);
    state = state.copyWith(themeVariant: variant);
  }

  Future<void> setUserName(String? name) async {
    await AppSettingsService.instance.setUserName(name);
    state = state.copyWith(userName: name, clearUserName: name == null);
  }

  /// Dev / debug only — clears the onboarded flag so the flow shows again.
  Future<void> resetOnboarding() async {
    await AppSettingsService.instance.setOnboarded(false);
    state = state.copyWith(hasOnboarded: false);
  }
}

final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
  return AppSettingsNotifier();
});
