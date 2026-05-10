import '../../../core/services/storage_service.dart';
import '../domain/custom_reminder.dart';

class CustomReminderRepository {
  CustomReminderRepository(this._storage);
  final StorageService _storage;

  List<CustomReminder> getAll() => _storage.customReminders.values.toList()
    ..sort((a, b) => a.startDate.compareTo(b.startDate));

  Future<void> add(CustomReminder r) async =>
      _storage.customReminders.put(r.id, r);
  Future<void> update(CustomReminder r) async =>
      _storage.customReminders.put(r.id, r);
  Future<void> delete(String id) async =>
      _storage.customReminders.delete(id);
}
