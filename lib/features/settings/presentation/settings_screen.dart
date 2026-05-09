import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/app_router.dart';
import '../../../core/services/notification_service.dart';
import '../../../infra/home_assistant/home_assistant_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setări')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.directions_car_rounded),
            title: const Text('Vehicule'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.pushNamed(context, AppRouter.vehicles),
          ),
          const Divider(height: 0),
          ListTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: const Text('Test notificare'),
            subtitle: const Text('Trimite o notificare locală de test'),
            onTap: () => NotificationService.instance.showNow(
              id: 9999,
              title: 'LaVolan',
              body: 'Notificările funcționează corect',
            ),
          ),
          const Divider(height: 0),
          ListTile(
            leading: const Icon(Icons.home_rounded),
            title: const Text('Home Assistant'),
            subtitle: const Text('Stare integrare (preview)'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () async {
              final state = await HomeAssistantService.instance.exportState();
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
          const Divider(height: 0),
          const ListTile(
            leading: Icon(Icons.info_outline_rounded),
            title: Text('LaVolan'),
            subtitle: Text('Versiune 1.0.0 · ro_RO'),
          ),
        ],
      ),
    );
  }
}
