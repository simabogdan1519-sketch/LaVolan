import '../../../core/services/storage_service.dart';
import '../domain/vehicle.dart';

class VehicleRepository {
  VehicleRepository(this._storage);
  final StorageService _storage;

  List<Vehicle> getAll() => _storage.vehicles.values.toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  Vehicle? getById(String id) =>
      _storage.vehicles.values.cast<Vehicle?>().firstWhere(
            (v) => v?.id == id,
            orElse: () => null,
          );

  Future<void> add(Vehicle v) async => _storage.vehicles.put(v.id, v);

  Future<void> update(Vehicle v) async => _storage.vehicles.put(v.id, v);

  Future<void> delete(String id) async => _storage.vehicles.delete(id);
}
