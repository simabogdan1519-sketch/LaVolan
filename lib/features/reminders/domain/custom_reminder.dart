import 'package:hive/hive.dart';

part 'custom_reminder.g.dart';

@HiveType(typeId: 10)
enum ReminderInterval {
  @HiveField(0)
  daily,
  @HiveField(1)
  weekly,
  @HiveField(2)
  monthly,
  @HiveField(3)
  yearly,
  @HiveField(4)
  custom,
}

extension ReminderIntervalInfo on ReminderInterval {
  String get labelRo {
    switch (this) {
      case ReminderInterval.daily:
        return 'Zilnic';
      case ReminderInterval.weekly:
        return 'Săptămânal';
      case ReminderInterval.monthly:
        return 'Lunar';
      case ReminderInterval.yearly:
        return 'Anual';
      case ReminderInterval.custom:
        return 'Personalizat';
    }
  }
}

@HiveType(typeId: 11)
class CustomReminder extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  String title;
  @HiveField(2)
  String? body;
  @HiveField(3)
  DateTime startDate;

  /// Hour of day (0-23) when the reminder fires.
  @HiveField(4)
  int hour;
  @HiveField(5)
  int minute;

  @HiveField(6)
  ReminderInterval interval;

  /// Days between repeats when [interval] == custom (or used as multiplier
  /// for daily). Ignored for weekly/monthly/yearly.
  @HiveField(7)
  int customIntervalDays;

  /// Total number of occurrences. `null` means infinite (until disabled).
  @HiveField(8)
  int? occurrencesCount;

  /// How many notifications have already been scheduled/fired.
  @HiveField(9)
  int firedCount;

  @HiveField(10)
  bool enabled;

  @HiveField(11)
  String? vehicleId; // optional link to a vehicle

  @HiveField(12)
  DateTime createdAt;

  CustomReminder({
    required this.id,
    required this.title,
    this.body,
    required this.startDate,
    this.hour = 9,
    this.minute = 0,
    this.interval = ReminderInterval.monthly,
    this.customIntervalDays = 30,
    this.occurrencesCount,
    this.firedCount = 0,
    this.enabled = true,
    this.vehicleId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Computes the next N occurrences from [startDate], starting at
  /// occurrence index [firedCount].
  List<DateTime> upcomingOccurrences({int count = 8}) {
    final out = <DateTime>[];
    final maxOccurrences = occurrencesCount ?? 1000;
    for (var i = firedCount;
        i < maxOccurrences && out.length < count;
        i++) {
      out.add(_nthOccurrence(i));
    }
    return out;
  }

  DateTime _nthOccurrence(int index) {
    final base = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
      hour,
      minute,
    );
    switch (interval) {
      case ReminderInterval.daily:
        return base.add(Duration(days: index));
      case ReminderInterval.weekly:
        return base.add(Duration(days: 7 * index));
      case ReminderInterval.monthly:
        return DateTime(
            base.year, base.month + index, base.day, hour, minute);
      case ReminderInterval.yearly:
        return DateTime(
            base.year + index, base.month, base.day, hour, minute);
      case ReminderInterval.custom:
        return base.add(Duration(days: customIntervalDays * index));
    }
  }
}
