import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/notification_service.dart';
import '../../../core/services/storage_service.dart';
import '../data/custom_reminder_repository.dart';
import '../domain/custom_reminder.dart';

final customReminderRepositoryProvider =
    Provider<CustomReminderRepository>((ref) {
  return CustomReminderRepository(StorageService.instance);
});

final customRemindersProvider =
    StateNotifierProvider<CustomRemindersNotifier, List<CustomReminder>>(
        (ref) {
  return CustomRemindersNotifier(ref.watch(customReminderRepositoryProvider));
});

class CustomRemindersNotifier extends StateNotifier<List<CustomReminder>> {
  CustomRemindersNotifier(this._repo) : super(_repo.getAll());
  final CustomReminderRepository _repo;

  Future<void> add(CustomReminder r) async {
    await _repo.add(r);
    if (r.enabled) {
      await NotificationService.instance.scheduleCustomRecurring(
        baseId: 'custom-${r.id}',
        title: r.title,
        body: r.body ?? r.title,
        occurrences: r.upcomingOccurrences(count: 24),
      );
    }
    state = _repo.getAll();
  }

  Future<void> update(CustomReminder r) async {
    await NotificationService.instance
        .cancelCustomRecurring(baseId: 'custom-${r.id}');
    await _repo.update(r);
    if (r.enabled) {
      await NotificationService.instance.scheduleCustomRecurring(
        baseId: 'custom-${r.id}',
        title: r.title,
        body: r.body ?? r.title,
        occurrences: r.upcomingOccurrences(count: 24),
      );
    }
    state = _repo.getAll();
  }

  Future<void> toggle(String id, bool enabled) async {
    final r = state.firstWhere((x) => x.id == id);
    r.enabled = enabled;
    await update(r);
  }

  Future<void> delete(String id) async {
    await NotificationService.instance
        .cancelCustomRecurring(baseId: 'custom-$id');
    await _repo.delete(id);
    state = _repo.getAll();
  }
}
