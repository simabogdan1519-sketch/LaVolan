import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import 'app.dart';
import 'core/services/notification_service.dart';
import 'core/services/storage_service.dart';
import 'core/services/background_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Timezone init for scheduled notifications
  tz.initializeTimeZones();

  // Hive offline-first DB
  await Hive.initFlutter();
  await StorageService.instance.init();

  // Notifications
  await NotificationService.instance.init();

  // Background tasks (workmanager)
  await BackgroundService.instance.init();

  runApp(const ProviderScope(child: LaVolanApp()));
}
