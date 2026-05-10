import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/services/app_settings_service.dart';
import 'core/theme/app_theme.dart';

class LaVolanApp extends ConsumerWidget {
  const LaVolanApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    return MaterialApp(
      title: 'LaVolan',
      debugShowCheckedModeBanner: false,
      theme: NimbusTheme.light(settings.themeVariant),
      darkTheme: NimbusTheme.dark(settings.themeVariant),
      themeMode: NimbusTheme.themeModeFor(settings.themeVariant),
      locale: const Locale('ro', 'RO'),
      supportedLocales: const [
        Locale('ro', 'RO'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute:
          settings.hasOnboarded ? AppRouter.dashboard : AppRouter.onboarding,
    );
  }
}
