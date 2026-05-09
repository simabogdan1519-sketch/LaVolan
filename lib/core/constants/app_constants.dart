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
}
