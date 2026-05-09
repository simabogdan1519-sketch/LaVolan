import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/app_router.dart';
import '../data/vehicle_photo_service.dart';
import '../domain/vehicle.dart';
import 'vehicle_providers.dart';

class VehicleListScreen extends ConsumerWidget {
  const VehicleListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicles = ref.watch(vehiclesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Vehicule')),
      body: vehicles.isEmpty
          ? const Center(child: Text('Niciun vehicul adăugat'))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: vehicles.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (_, i) {
                final v = vehicles[i];
                return Card(
                  child: ListTile(
                    leading: _VehicleAvatar(vehicle: v),
                    title: Text(v.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                        '${v.licensePlate} · ${v.fuelLabelRo} · ${v.mileage} km'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (action) async {
                        if (action == 'edit') {
                          Navigator.pushNamed(context, AppRouter.vehicleForm,
                              arguments: v.id);
                        } else if (action == 'delete') {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Șterge vehicul'),
                              content: Text('Sigur ștergi ${v.displayName}?'),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(_, false),
                                    child: const Text('Anulează')),
                                FilledButton(
                                    onPressed: () => Navigator.pop(_, true),
                                    child: const Text('Șterge')),
                              ],
                            ),
                          );
                          if (ok == true) {
                            // Clean up the photo file before removing the row.
                            await VehiclePhotoService.instance
                                .delete(v.photoPath);
                            await ref
                                .read(vehiclesProvider.notifier)
                                .delete(v.id);
                          }
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Editează')),
                        PopupMenuItem(value: 'delete', child: Text('Șterge')),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            Navigator.pushNamed(context, AppRouter.vehicleForm),
        child: const Icon(Icons.add),
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
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              _fallback(cs),
        ),
      );
    }
    return _fallback(cs);
  }

  Widget _fallback(ColorScheme cs) => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: cs.primaryContainer,
        ),
        child: Icon(Icons.directions_car_rounded,
            color: cs.onPrimaryContainer, size: 24),
      );
}
