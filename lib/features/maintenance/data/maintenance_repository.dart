import '../../../core/services/storage_service.dart';
import '../domain/maintenance_entry.dart';

class MaintenanceRepository {
  MaintenanceRepository(this._storage);
  final StorageService _storage;

  List<MaintenanceEntry> getAll() => _storage.maintenance.values.toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  List<MaintenanceEntry> getByVehicle(String vehicleId) => _storage
      .maintenance.values
      .where((m) => m.vehicleId == vehicleId)
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  MaintenanceEntry? nextDue(String vehicleId, int currentMileage) {
    final list = getByVehicle(vehicleId).where((m) =>
        m.nextDueDate != null || m.nextDueMileage != null).toList();
    if (list.isEmpty) return null;
    list.sort((a, b) {
      final aDate = a.nextDueDate ?? DateTime(2999);
      final bDate = b.nextDueDate ?? DateTime(2999);
      return aDate.compareTo(bDate);
    });
    return list.first;
  }

  Future<void> add(MaintenanceEntry m) async =>
      _storage.maintenance.put(m.id, m);
  Future<void> update(MaintenanceEntry m) async =>
      _storage.maintenance.put(m.id, m);
  Future<void> delete(String id) async => _storage.maintenance.delete(id);
}
