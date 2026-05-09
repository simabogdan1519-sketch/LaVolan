import '../../../core/constants/app_constants.dart';
import '../../../core/services/storage_service.dart';
import '../domain/penalty_entry.dart';

enum PenaltyRiskLevel { safe, caution, warning, critical }

class PenaltyStats {
  final int activePoints;
  final int totalEntries;
  final List<PenaltyEntry> active;
  final PenaltyRiskLevel risk;

  PenaltyStats({
    required this.activePoints,
    required this.totalEntries,
    required this.active,
    required this.risk,
  });
}

class PenaltyRepository {
  PenaltyRepository(this._storage);
  final StorageService _storage;

  List<PenaltyEntry> getAll() => _storage.penalties.values.toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  Future<void> add(PenaltyEntry p) async => _storage.penalties.put(p.id, p);
  Future<void> update(PenaltyEntry p) async => _storage.penalties.put(p.id, p);
  Future<void> delete(String id) async => _storage.penalties.delete(id);

  PenaltyStats stats() {
    final all = getAll();
    final active = all.where((p) => p.isActive).toList();
    final activePoints = active.fold(0, (s, p) => s + p.points);
    PenaltyRiskLevel risk;
    final max = AppConstants.penaltyMaxBeforeSuspension;
    if (activePoints >= max) {
      risk = PenaltyRiskLevel.critical;
    } else if (activePoints >= max - 3) {
      risk = PenaltyRiskLevel.warning;
    } else if (activePoints >= 6) {
      risk = PenaltyRiskLevel.caution;
    } else {
      risk = PenaltyRiskLevel.safe;
    }
    return PenaltyStats(
      activePoints: activePoints,
      totalEntries: all.length,
      active: active,
      risk: risk,
    );
  }
}
