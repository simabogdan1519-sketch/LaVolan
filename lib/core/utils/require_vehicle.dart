import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../router/app_router.dart';
import '../../features/vehicle/domain/vehicle.dart';
import '../../features/vehicle/presentation/vehicle_providers.dart';

/// Shows a friendly dialog when no vehicle is selected and offers to
/// jump to the vehicle form. Returns the resolved vehicle or `null` if
/// the user cancelled.
///
/// Use this before any flow that requires a vehicle (saving documents,
/// fuel, maintenance, scanning).
Future<Vehicle?> requireVehicle(BuildContext context, WidgetRef ref) async {
  final v = ref.read(selectedVehicleProvider);
  if (v != null) return v;

  final goAdd = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Niciun vehicul'),
      content: const Text(
          'Trebuie să ai cel puțin un vehicul înainte să adaugi documente sau alte intrări.\n\nSă creezi unul acum?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(_, false),
          child: const Text('Anulează'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(_, true),
          child: const Text('Adaugă vehicul'),
        ),
      ],
    ),
  );
  if (!context.mounted) return null;
  if (goAdd == true) {
    await Navigator.pushNamed(context, AppRouter.vehicleForm);
    if (!context.mounted) return null;
    return ref.read(selectedVehicleProvider);
  }
  return null;
}
