import '../../../core/services/storage_service.dart';
import '../domain/fuel_entry.dart';

class FuelStats {
  final double avgConsumption; // L/100km
  final double costPerKm;
  final double totalSpent;
  final int totalLiters;

  FuelStats({
    required this.avgConsumption,
    required this.costPerKm,
    required this.totalSpent,
    required this.totalLiters,
  });
}

class FuelRepository {
  FuelRepository(this._storage);
  final StorageService _storage;

  List<FuelEntry> getAll() => _storage.fuel.values.toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  List<FuelEntry> getByVehicle(String vehicleId) =>
      _storage.fuel.values.where((f) => f.vehicleId == vehicleId).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  Future<void> add(FuelEntry f) async => _storage.fuel.put(f.id, f);
  Future<void> update(FuelEntry f) async => _storage.fuel.put(f.id, f);
  Future<void> delete(String id) async => _storage.fuel.delete(id);

  FuelStats statsFor(String vehicleId) {
    final entries = getByVehicle(vehicleId)..sort((a, b) => a.date.compareTo(b.date));
    if (entries.length < 2) {
      final totalSpent = entries.fold(0.0, (s, e) => s + e.totalCost);
      final totalLiters = entries.fold(0.0, (s, e) => s + e.liters).round();
      return FuelStats(
        avgConsumption: 0,
        costPerKm: 0,
        totalSpent: totalSpent,
        totalLiters: totalLiters,
      );
    }
    final first = entries.first;
    final last = entries.last;
    final kmDriven = last.mileage - first.mileage;
    final litersUsed = entries
        .skip(1)
        .where((e) => e.fullTank)
        .fold(0.0, (s, e) => s + e.liters);
    final totalCost = entries.fold(0.0, (s, e) => s + e.totalCost);
    final avg = (kmDriven > 0 && litersUsed > 0)
        ? (litersUsed / kmDriven) * 100
        : 0.0;
    final cpk = kmDriven > 0 ? totalCost / kmDriven : 0.0;
    return FuelStats(
      avgConsumption: avg,
      costPerKm: cpk,
      totalSpent: totalCost,
      totalLiters: entries.fold(0.0, (s, e) => s + e.liters).round(),
    );
  }
}
