import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/storage_service.dart';
import '../data/maintenance_repository.dart';
import '../domain/maintenance_entry.dart';

final maintenanceRepositoryProvider = Provider<MaintenanceRepository>((ref) {
  return MaintenanceRepository(StorageService.instance);
});

final maintenanceProvider =
    StateNotifierProvider<MaintenanceNotifier, List<MaintenanceEntry>>((ref) {
  return MaintenanceNotifier(ref.watch(maintenanceRepositoryProvider));
});

class MaintenanceNotifier extends StateNotifier<List<MaintenanceEntry>> {
  MaintenanceNotifier(this._repo) : super(_repo.getAll());
  final MaintenanceRepository _repo;

  Future<void> add(MaintenanceEntry m) async {
    await _repo.add(m);
    state = _repo.getAll();
  }

  Future<void> update(MaintenanceEntry m) async {
    await _repo.update(m);
    state = _repo.getAll();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    state = _repo.getAll();
  }
}
