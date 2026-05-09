import '../../../core/services/storage_service.dart';
import '../domain/document.dart';

class DocumentRepository {
  DocumentRepository(this._storage);
  final StorageService _storage;

  List<VehicleDocument> getAll() => _storage.documents.values.toList()
    ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

  List<VehicleDocument> getByVehicle(String vehicleId) =>
      _storage.documents.values.where((d) => d.vehicleId == vehicleId).toList()
        ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

  VehicleDocument? nextExpiring() {
    final all = getAll().where((d) => d.status != DocumentStatus.expired);
    return all.isEmpty ? null : all.first;
  }

  Future<void> add(VehicleDocument d) async => _storage.documents.put(d.id, d);
  Future<void> update(VehicleDocument d) async =>
      _storage.documents.put(d.id, d);
  Future<void> delete(String id) async => _storage.documents.delete(id);
}
