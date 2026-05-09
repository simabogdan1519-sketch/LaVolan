import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/storage_service.dart';
import '../data/vehicle_repository.dart';
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
