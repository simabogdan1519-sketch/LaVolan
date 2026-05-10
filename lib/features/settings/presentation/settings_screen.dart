import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/app_router.dart';
import '../../../core/services/app_settings_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/nimbus_tokens.dart';
import '../../../core/theme/nimbus_widgets.dart';
import '../../../infra/home_assistant/home_assistant_service.dart';
import '../../vehicle/presentation/vehicle_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final tintAsync = ref.watch(selectedVehicleTintProvider);
    final tint = tintAsync.maybeWhen(
      data: (t) => t,
      orElse: () => const NimbusVehicleTint(
        a: Color(0xFF9CC4DA),
        b: Color(0xFF5687AA),
        c: Color(0xFF3D4F7E),
        d: Color(0xFF1B2342),
      ),
    );

    return Stack(
      children: [
        Positioned.fill(child: AnimatedMeshBackdrop(tint: tint)),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(title: const Text('Setări')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
            children: [
              if (settings.userName != null && settings.userName!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: GlassCard.heavy(
                    child: Row(
                      children: [
                        Icon(Icons.person_rounded,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Salut, ${settings.userName}!',
                                  style: Theme.of(context).textTheme.titleMedium),
                              Text('Bun venit înapoi.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              const _SectionHeader('Aspect'),
              ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: const Text('Temă'),
                subtitle: Text(settings.themeVariant.labelRo),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () =>
                    Navigator.pushNamed(context, AppRouter.themePicker),
              ),
              const Divider(height: 0),

              const _SectionHeader('Vehicule și date'),
              ListTile(
                leading: const Icon(Icons.directions_car_rounded),
                title: const Text('Vehicule'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.pushNamed(context, AppRouter.vehicles),
              ),
              const Divider(height: 0),
              ListTile(
                leading: const Icon(Icons.fire_extinguisher_outlined),
                title: const Text('Echipament obligatoriu'),
                subtitle:
                    const Text('Extinctor, trusă, vestă, triunghi'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () =>
                    Navigator.pushNamed(context, AppRouter.equipment),
              ),
              const Divider(height: 0),
              ListTile(
                leading: const Icon(Icons.badge_rounded),
                title: const Text('Documente personale'),
                subtitle: const Text('Buletin, permis'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.pushNamed(
                    context, AppRouter.personalDocuments),
              ),
              const Divider(height: 0),

              const _SectionHeader('Remindere'),
              ListTile(
                leading: const Icon(Icons.alarm_rounded),
                title: const Text('Remindere personalizate'),
                subtitle:
                    const Text('Anvelope, antigel, spălare, etc.'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () =>
                    Navigator.pushNamed(context, AppRouter.reminders),
              ),
              const Divider(height: 0),

              const _SectionHeader('Notificări'),
              ListTile(
                leading: const Icon(Icons.notifications_active_outlined),
                title: const Text('Test notificare'),
                subtitle:
                    const Text('Trimite o notificare locală de test'),
                onTap: () => NotificationService.instance.showNow(
                  id: 9999,
                  title: 'LaVolan',
                  body: 'Notificările funcționează corect',
                ),
              ),
              const Divider(height: 0),

              const _SectionHeader('Integrări'),
              ListTile(
                leading: const Icon(Icons.home_rounded),
                title: const Text('Home Assistant'),
                subtitle: const Text('Stare integrare (preview)'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () async {
                  final state =
                      await HomeAssistantService.instance.exportState();
                  if (!context.mounted) return;
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Stare HA exportabilă'),
                      content: SingleChildScrollView(
                        child: SelectableText(state),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(_),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const Divider(height: 0),
              const ListTile(
                leading: Icon(Icons.cable_rounded),
                title: Text('OBD2 (în dezvoltare)'),
                subtitle: Text('Conectare la diagnoză vehicul'),
                enabled: false,
              ),

              const _SectionHeader('Despre'),
              ListTile(
                leading: const Icon(Icons.replay_rounded),
                title: const Text('Reia tutorialul'),
                subtitle: const Text('Arată din nou ecranele de bun venit'),
                onTap: () async {
                  await ref
                      .read(appSettingsProvider.notifier)
                      .resetOnboarding();
                  if (!context.mounted) return;
                  Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRouter.onboarding, (_) => false);
                },
              ),
              const Divider(height: 0),
              const ListTile(
                leading: Icon(Icons.info_outline_rounded),
                title: Text('LaVolan'),
                subtitle: Text('Versiune 1.0.0 · ro_RO'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
