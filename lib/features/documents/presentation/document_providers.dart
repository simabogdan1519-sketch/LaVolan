import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/notification_service.dart';
import '../../../core/services/storage_service.dart';
import '../data/document_repository.dart';
import '../domain/document.dart';

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  return DocumentRepository(StorageService.instance);
});

final documentsProvider =
    StateNotifierProvider<DocumentsNotifier, List<VehicleDocument>>((ref) {
  return DocumentsNotifier(ref.watch(documentRepositoryProvider));
});

class DocumentsNotifier extends StateNotifier<List<VehicleDocument>> {
  DocumentsNotifier(this._repo) : super(_repo.getAll());
  final DocumentRepository _repo;

  Future<void> add(VehicleDocument d) async {
    await _repo.add(d);
    // Notification scheduling can fail (e.g. SCHEDULE_EXACT_ALARM not
    // granted on Android 12+, or plugin not initialised yet) — we don't
    // want a missing reminder to block the save itself.
    try {
      await NotificationService.instance.scheduleExpiryReminders(
        baseId: 'doc-${d.id}',
        title: 'Document ${d.typeLabelRo}',
        body: '${d.typeLabelRo} expiră curând',
        expiry: d.expiryDate,
      );
    } catch (e) {
      // ignore — document is saved, reminders just won't fire
    }
    state = _repo.getAll();
  }

  Future<void> update(VehicleDocument d) async {
    await _repo.update(d);
    try {
      await NotificationService.instance.scheduleExpiryReminders(
        baseId: 'doc-${d.id}',
        title: 'Document ${d.typeLabelRo}',
        body: '${d.typeLabelRo} expiră curând',
        expiry: d.expiryDate,
      );
    } catch (_) {}
    state = _repo.getAll();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    state = _repo.getAll();
  }
}

final nextExpiringDocumentProvider = Provider<VehicleDocument?>((ref) {
  ref.watch(documentsProvider);
  return ref.watch(documentRepositoryProvider).nextExpiring();
});
