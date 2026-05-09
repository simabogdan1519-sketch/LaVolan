import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/storage_service.dart';
import '../data/fuel_repository.dart';
import '../domain/fuel_entry.dart';

final fuelRepositoryProvider = Provider<FuelRepository>((ref) {
  return FuelRepository(StorageService.instance);
});

final fuelProvider =
    StateNotifierProvider<FuelNotifier, List<FuelEntry>>((ref) {
  return FuelNotifier(ref.watch(fuelRepositoryProvider));
});

class FuelNotifier extends StateNotifier<List<FuelEntry>> {
  FuelNotifier(this._repo) : super(_repo.getAll());
  final FuelRepository _repo;

  Future<void> add(FuelEntry f) async {
    await _repo.add(f);
    state = _repo.getAll();
  }

  Future<void> update(FuelEntry f) async {
    await _repo.update(f);
    state = _repo.getAll();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    state = _repo.getAll();
  }
}

final fuelStatsProvider = Provider.family<FuelStats, String>((ref, vehicleId) {
  ref.watch(fuelProvider);
  return ref.watch(fuelRepositoryProvider).statsFor(vehicleId);
});
