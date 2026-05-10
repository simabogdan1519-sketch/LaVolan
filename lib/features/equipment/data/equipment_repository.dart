import '../../../core/services/storage_service.dart';
import '../domain/equipment_item.dart';

class EquipmentRepository {
  EquipmentRepository(this._storage);
  final StorageService _storage;

  List<EquipmentItem> getAll() => _storage.equipment.values.toList()
    ..sort((a, b) {
      // Items with expiry first, then by expiry date.
      final ae = a.expiryDate;
      final be = b.expiryDate;
      if (ae == null && be == null) return 0;
      if (ae == null) return 1;
      if (be == null) return -1;
      return ae.compareTo(be);
    });

  List<EquipmentItem> getByVehicle(String vehicleId) => _storage
      .equipment.values
      .where((e) => e.vehicleId == vehicleId)
      .toList();

  Future<void> add(EquipmentItem e) async =>
      _storage.equipment.put(e.id, e);
  Future<void> update(EquipmentItem e) async =>
      _storage.equipment.put(e.id, e);
  Future<void> delete(String id) async => _storage.equipment.delete(id);
}
