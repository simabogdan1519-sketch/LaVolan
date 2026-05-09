import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/storage_service.dart';
import '../../../core/theme/nimbus_tokens.dart';
import '../data/vehicle_repository.dart';
import '../data/vehicle_tint_service.dart';
import '../domain/vehicle.dart';

final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  return VehicleRepository(StorageService.instance);
});

final vehiclesProvider =
    StateNotifierProvider<VehiclesNotifier, List<Vehicle>>((ref) {
  return VehiclesNotifier(ref.watch(vehicleRepositoryProvider));
});

class VehiclesNotifier extends StateNotifier<List<Vehicle>> {
  VehiclesNotifier(this._repo) : super(_repo.getAll());

  final VehicleRepository _repo;

  Future<void> add(Vehicle v) async {
    await _repo.add(v);
    state = _repo.getAll();
  }

  Future<void> update(Vehicle v) async {
    await _repo.update(v);
    state = _repo.getAll();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    state = _repo.getAll();
  }
}

final selectedVehicleIdProvider = StateProvider<String?>((ref) {
  final list = ref.watch(vehiclesProvider);
  return list.isEmpty ? null : list.first.id;
});

final selectedVehicleProvider = Provider<Vehicle?>((ref) {
  final id = ref.watch(selectedVehicleIdProvider);
  final list = ref.watch(vehiclesProvider);
  if (id == null) return null;
  for (final v in list) {
    if (v.id == id) return v;
  }
  return list.isEmpty ? null : list.first;
});

/// Async tint extracted from the selected vehicle's photo. Falls back to
/// brand-keyed defaults if there is no photo or extraction fails.
final selectedVehicleTintProvider =
    FutureProvider.autoDispose<NimbusVehicleTint>((ref) async {
  final v = ref.watch(selectedVehicleProvider);
  if (v == null) {
    return const NimbusVehicleTint(
      a: Color(0xFF9CC4DA),
      b: Color(0xFF5687AA),
      c: Color(0xFF3D4F7E),
      d: Color(0xFF1B2342),
    );
  }
  // Synchronous fallback (brand) is shown immediately while we warm up
  // the photo-based tint in the background.
  final svc = VehicleTintService.instance;
  final fromPhoto = await svc.warmUp(v);
  return fromPhoto ?? svc.tintFor(v);
});

/// Synchronous tint resolver — useful when you need a tint *now* (no
/// FutureProvider) and don't mind the brand-fallback during the first frame.
final vehicleTintResolverProvider =
    Provider<NimbusVehicleTint Function(Vehicle?)>((ref) {
  return (Vehicle? v) {
    if (v == null) {
      return const NimbusVehicleTint(
        a: Color(0xFF9CC4DA),
        b: Color(0xFF5687AA),
        c: Color(0xFF3D4F7E),
        d: Color(0xFF1B2342),
      );
    }
    return VehicleTintService.instance.tintFor(v);
  };
});
