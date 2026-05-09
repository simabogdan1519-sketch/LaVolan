import 'package:hive_flutter/hive_flutter.dart';

import '../../features/documents/domain/document.dart';
import '../../features/fuel/domain/fuel_entry.dart';
import '../../features/maintenance/domain/maintenance_entry.dart';
import '../../features/penalty_points/domain/penalty_entry.dart';
import '../../features/vehicle/domain/vehicle.dart';
import '../constants/app_constants.dart';

class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  late Box<Vehicle> vehicles;
  late Box<VehicleDocument> documents;
  late Box<MaintenanceEntry> maintenance;
  late Box<FuelEntry> fuel;
  late Box<PenaltyEntry> penalties;
  late Box settings;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    Hive.registerAdapter(FuelTypeAdapter());
    Hive.registerAdapter(VehicleAdapter());
    Hive.registerAdapter(DocumentTypeAdapter());
    Hive.registerAdapter(VehicleDocumentAdapter());
    Hive.registerAdapter(MaintenanceCategoryAdapter());
    Hive.registerAdapter(MaintenanceEntryAdapter());
    Hive.registerAdapter(FuelEntryAdapter());
    Hive.registerAdapter(PenaltyEntryAdapter());

    vehicles = await Hive.openBox<Vehicle>(AppConstants.vehicleBox);
    documents = await Hive.openBox<VehicleDocument>(AppConstants.documentBox);
    maintenance = await Hive.openBox<MaintenanceEntry>(AppConstants.maintenanceBox);
    fuel = await Hive.openBox<FuelEntry>(AppConstants.fuelBox);
    penalties = await Hive.openBox<PenaltyEntry>(AppConstants.penaltyBox);
    settings = await Hive.openBox(AppConstants.settingsBox);

    _initialized = true;
  }

  Future<void> close() async {
    await Hive.close();
    _initialized = false;
  }
}
