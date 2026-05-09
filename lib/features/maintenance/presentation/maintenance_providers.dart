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

/// The next maintenance entry due across all vehicles (or for the selected
/// vehicle if you prefer — currently global to keep dashboard simple).
final nextMaintenanceProvider = Provider<MaintenanceEntry?>((ref) {
  final list = ref.watch(maintenanceProvider);
  final pending = list
      .where((m) => m.nextDueDate != null || m.nextDueMileage != null)
      .toList()
    ..sort((a, b) {
      final aDate = a.nextDueDate ?? DateTime(2999);
      final bDate = b.nextDueDate ?? DateTime(2999);
      return aDate.compareTo(bDate);
    });
  return pending.isEmpty ? null : pending.first;
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
