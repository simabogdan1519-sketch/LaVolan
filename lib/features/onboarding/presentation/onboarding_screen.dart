import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/router/app_router.dart';
import '../../../core/services/app_settings_service.dart';
import '../../../core/theme/nimbus_widgets.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  final _nameController = TextEditingController();
  int _index = 0;
  bool _busy = false;

  static const _pages = [
    _OnboardPageData(
      icon: Icons.directions_car_filled_rounded,
      eyebrow: 'Bun venit',
      title: 'LaVolan',
      body:
          'Asistentul tău digital pentru mașină. RCA, ITP, rovinieta, mentenanță, combustibil — toate într-un loc.',
    ),
    _OnboardPageData(
      icon: Icons.notifications_active_rounded,
      eyebrow: 'Documente',
      title: 'Niciodată cu actele expirate',
      body:
          'Adaugă RCA, ITP și rovinieta. Te anunțăm cu 30, 14, 7 și 1 zi înainte de expirare.',
    ),
    _OnboardPageData(
      icon: Icons.document_scanner_rounded,
      eyebrow: 'Scanner',
      title: 'Scanează polița în 3 secunde',
      body:
          'Camera + OCR detectează automat tipul documentului, data expirării și asiguratorul. Tu doar confirmi.',
    ),
    _OnboardPageData(
      icon: Icons.local_gas_station_rounded,
      eyebrow: 'Mai mult',
      title: 'Combustibil, mentenanță, puncte',
      body:
          'Calcul automat al consumului în L/100 km, planificare oil change, tracker pentru punctele de penalizare.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_busy) return;
    setState(() => _busy = true);

    // Best-effort permission ask. We don't block onboarding if denied —
    // user can grant from settings later.
    try {
      await Permission.notification.request();
    } catch (_) {}

    final name = _nameController.text.trim();
    await ref
        .read(appSettingsProvider.notifier)
        .completeOnboarding(name: name.isEmpty ? null : name);

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRouter.dashboard,
      (_) => false,
    );
  }

  void _next() {
    if (_index >= _pages.length) return;
    if (_index == _pages.length - 1) {
      // Already on the last "info" slide — go to the config slide.
      _pageController.animateToPage(_pages.length,
          duration: const Duration(milliseconds: 320), curve: Curves.easeOut);
      return;
    }
    _pageController.nextPage(
        duration: const Duration(milliseconds: 320), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final isConfigPage = _index == _pages.length;
    final isLast = _index == _pages.length - 1;

    return Stack(
      children: [
        const Positioned.fill(child: LvBackdrop()),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                _topBar(context, isConfigPage),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _index = i),
                    children: [
                      for (final p in _pages) _InfoPage(data: p),
                      _ConfigPage(controller: _nameController),
                    ],
                  ),
                ),
                _dotsAndCta(context, isConfigPage, isLast),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _topBar(BuildContext context, bool isConfig) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          if (_index > 0)
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => _pageController.previousPage(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOut),
            )
          else
            const SizedBox(width: 48),
          const Spacer(),
          if (!isConfig)
            TextButton(onPressed: _finish, child: const Text('Sari')),
        ],
      ),
    );
  }

  Widget _dotsAndCta(BuildContext context, bool isConfig, bool isLast) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_pages.length + 1, (i) {
              final selected = _index == i;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: selected ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: selected
                      ? cs.primary
                      : cs.onSurface.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          if (isConfig)
            FilledButton.icon(
              onPressed: _busy ? null : _finish,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded),
              label: const Text('Începe'),
            )
          else
            FilledButton(
              onPressed: _next,
              child: Text(isLast ? 'Aproape gata' : 'Continuă'),
            ),
        ],
      ),
    );
  }
}

// ────────────────────── pieces ──────────────────────

class _OnboardPageData {
  const _OnboardPageData({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String eyebrow;
  final String title;
  final String body;
}

class _InfoPage extends StatelessWidget {
  const _InfoPage({required this.data});
  final _OnboardPageData data;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Center(
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.primary.withOpacity(0.18),
                border: Border.all(
                    color: cs.primary.withOpacity(0.4), width: 1.5),
              ),
              child: Icon(data.icon, size: 44, color: cs.primary),
            ),
          ),
          const SizedBox(height: 28),
          Eyebrow(data.eyebrow, color: cs.primary),
          const SizedBox(height: 8),
          Text(data.title,
              style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 14),
          Text(
            data.body,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.55,
                ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _ConfigPage extends StatelessWidget {
  const _ConfigPage({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
      child: ListView(
        children: [
          const SizedBox(height: 16),
          Center(
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.primary.withOpacity(0.18),
                border: Border.all(
                    color: cs.primary.withOpacity(0.4), width: 1.5),
              ),
              child: Icon(Icons.tune_rounded, size: 44, color: cs.primary),
            ),
          ),
          const SizedBox(height: 24),
          Eyebrow('Configurare rapidă', color: cs.primary),
          const SizedBox(height: 8),
          Text('Aproape gata',
              style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 12),
          Text(
            'Cum vrei să-ți spunem? (opțional, rămâne pe telefonul tău)',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: controller,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Prenume',
              hintText: 'ex. Bogdan',
            ),
          ),
          const SizedBox(height: 24),
          GlassCard.light(
            child: Row(
              children: [
                Icon(Icons.shield_outlined, color: cs.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Datele rămân pe telefonul tău. Fără cloud, fără tracking.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GlassCard.light(
            child: Row(
              children: [
                Icon(Icons.notifications_outlined, color: cs.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'O să-ți cerem permisiunea pentru notificări — astfel te putem alerta înainte să expire RCA-ul.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
