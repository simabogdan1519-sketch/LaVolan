import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/notification_service.dart';
import '../../../core/services/storage_service.dart';
import '../data/equipment_repository.dart';
import '../domain/equipment_item.dart';

final equipmentRepositoryProvider = Provider<EquipmentRepository>((ref) {
  return EquipmentRepository(StorageService.instance);
});

final equipmentProvider =
    StateNotifierProvider<EquipmentNotifier, List<EquipmentItem>>((ref) {
  return EquipmentNotifier(ref.watch(equipmentRepositoryProvider));
});

class EquipmentNotifier extends StateNotifier<List<EquipmentItem>> {
  EquipmentNotifier(this._repo) : super(_repo.getAll());
  final EquipmentRepository _repo;

  Future<void> add(EquipmentItem e) async {
    await _repo.add(e);
    if (e.expiryDate != null) {
      await NotificationService.instance.scheduleExpiryReminders(
        baseId: 'equip-${e.id}',
        title: 'Echipament expiră',
        body: '${e.type.labelRo} expiră curând',
        expiry: e.expiryDate!,
      );
    }
    state = _repo.getAll();
  }

  Future<void> update(EquipmentItem e) async {
    await _repo.update(e);
    if (e.expiryDate != null) {
      await NotificationService.instance.scheduleExpiryReminders(
        baseId: 'equip-${e.id}',
        title: 'Echipament expiră',
        body: '${e.type.labelRo} expiră curând',
        expiry: e.expiryDate!,
      );
    }
    state = _repo.getAll();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    state = _repo.getAll();
  }
}
