class AppConstants {
  static const String appName = 'LaVolan';
  static const String appTagline = 'Asistentul tău digital auto';

  // Hive box names
  static const String vehicleBox = 'vehicles_box';
  static const String documentBox = 'documents_box';
  static const String maintenanceBox = 'maintenance_box';
  static const String fuelBox = 'fuel_box';
  static const String penaltyBox = 'penalty_box';
  static const String reminderBox = 'reminders_box';
  static const String equipmentBox = 'equipment_box';
  static const String customReminderBox = 'custom_reminders_box';
  static const String settingsBox = 'settings_box';

  // Notification channels
  static const String notifChannelId = 'lavolan_main_channel';
  static const String notifChannelName = 'LaVolan Notificări';
  static const String notifChannelDesc = 'Notificări pentru documente și mentenanță';

  // Penalty points (RO)
  static const int penaltyMaxBeforeSuspension = 15;
  static const int penaltyExpiryMonths = 6;

  // Reminder offsets
  static const List<int> reminderDaysBefore = [30, 14, 7, 1];

  // Document validity presets (RO).
  // RCA — 6 sau 12 luni; ITP — 1 an (mașini >12 ani) sau 2 ani; rovinietă —
  // 1 zi, 7 zile, 10 zile (turist), 30 zile, 60 zile, 12 luni; buletin —
  // 10 ani; permis cat. B — 10 ani.
  static const List<int> rcaValidityMonths = [6, 12];
  static const List<int> itpValidityMonths = [12, 24];
  static const List<int> rovinietaValidityDays = [1, 7, 10, 30, 60, 90, 365];
  static const int buletinValidityYears = 10;
  static const int permisValidityYears = 10;
}
