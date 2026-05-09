import 'package:workmanager/workmanager.dart';

import 'notification_service.dart';
import 'storage_service.dart';

const String kBgTaskCheckExpiry = 'lavolan.checkExpiry';

@pragma('vm:entry-point')
void backgroundDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // Re-init storage in isolate
      await StorageService.instance.init();
      await NotificationService.instance.init();

      switch (task) {
        case kBgTaskCheckExpiry:
          await _checkDocumentExpiry();
          break;
      }
      return true;
    } catch (_) {
      return false;
    }
  });
}

Future<void> _checkDocumentExpiry() async {
  final docs = StorageService.instance.documents.values.toList();
  final now = DateTime.now();
  for (final d in docs) {
    final daysLeft = d.expiryDate.difference(now).inDays;
    if (daysLeft == 7 || daysLeft == 1 || daysLeft == 0) {
      await NotificationService.instance.showNow(
        id: ('expiry-${d.id}-$daysLeft').hashCode,
        title: 'Document apropiat de expirare',
        body: '${d.typeLabelRo} expiră în $daysLeft zile',
      );
    }
  }
}

class BackgroundService {
  BackgroundService._();
  static final BackgroundService instance = BackgroundService._();

  Future<void> init() async {
    await Workmanager().initialize(
      backgroundDispatcher,
      isInDebugMode: false,
    );
    await Workmanager().registerPeriodicTask(
      'lavolan-daily-expiry',
      kBgTaskCheckExpiry,
      frequency: const Duration(hours: 24),
      existingWorkPolicy: ExistingWorkPolicy.keep,
      constraints: Constraints(networkType: NetworkType.not_required),
    );
  }
}
