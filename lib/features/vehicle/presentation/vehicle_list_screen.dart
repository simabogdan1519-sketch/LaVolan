import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/nimbus_screen.dart';
import '../../../core/theme/nimbus_widgets.dart';
import '../data/vehicle_photo_service.dart';
import '../domain/vehicle.dart';
import 'vehicle_providers.dart';

class VehicleListScreen extends ConsumerWidget {
  const VehicleListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicles = ref.watch(vehiclesProvider);
    return NimbusScreen(
      appBar: AppBar(title: const Text('Vehicule')),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            Navigator.pushNamed(context, AppRouter.vehicleForm),
        child: const Icon(Icons.add),
      ),
      body: vehicles.isEmpty
          ? _Empty(
              onAdd: () =>
                  Navigator.pushNamed(context, AppRouter.vehicleForm))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: vehicles.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final v = vehicles[i];
                return GlassCard.heavy(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      _VehicleAvatar(vehicle: v),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(v.displayName,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium),
                            const SizedBox(height: 2),
                            Text(
                              '${v.licensePlate} · ${v.fuelLabelRo} · ${v.mileage} km',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (action) async {
                          if (action == 'edit') {
                            Navigator.pushNamed(
                                context, AppRouter.vehicleForm,
                                arguments: v.id);
                          } else if (action == 'delete') {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Șterge vehicul'),
                                content: Text(
                                    'Sigur ștergi ${v.displayName}?'),
                                actions: [
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.pop(_, false),
                                      child: const Text('Anulează')),
                                  FilledButton(
                                      onPressed: () =>
                                          Navigator.pop(_, true),
                                      child: const Text('Șterge')),
                                ],
                              ),
                            );
                            if (ok == true) {
                              await VehiclePhotoService.instance
                                  .delete(v.photoPath);
                              await ref
                                  .read(vehiclesProvider.notifier)
                                  .delete(v.id);
                            }
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                              value: 'edit', child: Text('Editează')),
                          PopupMenuItem(
                              value: 'delete', child: Text('Șterge')),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onAdd});
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.primary.withOpacity(0.18),
                border: Border.all(
                    color: cs.primary.withOpacity(0.4), width: 1.5),
              ),
              child: Icon(Icons.directions_car_filled_rounded,
                  size: 40, color: cs.primary),
            ),
            const SizedBox(height: 24),
            Text('Niciun vehicul',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Adaugă prima mașină ca să începi.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Adaugă vehicul'),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleAvatar extends StatelessWidget {
  const _VehicleAvatar({required this.vehicle});
  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final p = vehicle.photoPath;
    if (p != null && p.isNotEmpty) {
      return ClipOval(
        child: Image.file(
          File(p),
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(cs),
        ),
      );
    }
    return _fallback(cs);
  }

  Widget _fallback(ColorScheme cs) => Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: cs.primaryContainer,
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        child: Icon(Icons.directions_car_rounded,
            color: cs.onPrimaryContainer, size: 24),
      );
}
