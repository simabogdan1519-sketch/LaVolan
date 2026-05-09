/// API abstraction for future cloud sync. Today, all storage is local
/// (Hive). When cloud sync ships, implementations of this interface
/// will mirror local writes to a backend.
abstract class VehicleApiService {
  Future<List<Map<String, dynamic>>> fetchVehicles();
  Future<void> pushVehicle(Map<String, dynamic> v);
  Future<void> pushDocument(Map<String, dynamic> d);
}

class MockVehicleApiService implements VehicleApiService {
  @override
  Future<List<Map<String, dynamic>>> fetchVehicles() async => [];

  @override
  Future<void> pushVehicle(Map<String, dynamic> v) async {}

  @override
  Future<void> pushDocument(Map<String, dynamic> d) async {}
}

/// Sync orchestrator — runs in background to push pending writes
/// once the cloud backend is online.
class SyncService {
  SyncService(this._api);
  final VehicleApiService _api;

  Future<void> sync() async {
    // No-op until backend is available.
  }
}
