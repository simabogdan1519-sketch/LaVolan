import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/storage_service.dart';
import '../data/penalty_repository.dart';
import '../domain/penalty_entry.dart';

final penaltyRepositoryProvider = Provider<PenaltyRepository>((ref) {
  return PenaltyRepository(StorageService.instance);
});

final penaltyProvider =
    StateNotifierProvider<PenaltyNotifier, List<PenaltyEntry>>((ref) {
  return PenaltyNotifier(ref.watch(penaltyRepositoryProvider));
});

class PenaltyNotifier extends StateNotifier<List<PenaltyEntry>> {
  PenaltyNotifier(this._repo) : super(_repo.getAll());
  final PenaltyRepository _repo;

  Future<void> add(PenaltyEntry p) async {
    await _repo.add(p);
    state = _repo.getAll();
  }

  Future<void> update(PenaltyEntry p) async {
    await _repo.update(p);
    state = _repo.getAll();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    state = _repo.getAll();
  }
}

final penaltyStatsProvider = Provider<PenaltyStats>((ref) {
  ref.watch(penaltyProvider);
  return ref.watch(penaltyRepositoryProvider).stats();
});
