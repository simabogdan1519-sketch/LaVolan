import 'package:hive/hive.dart';

part 'maintenance_entry.g.dart';

@HiveType(typeId: 4)
enum MaintenanceCategory {
  @HiveField(0)
  ulei,
  @HiveField(1)
  filtre,
  @HiveField(2)
  placute,
  @HiveField(3)
  anvelope,
  @HiveField(4)
  baterie,
  @HiveField(5)
  revizie,
  @HiveField(6)
  altele,
}

@HiveType(typeId: 5)
class MaintenanceEntry extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String vehicleId;
  @HiveField(2)
  MaintenanceCategory category;
  @HiveField(3)
  DateTime date;
  @HiveField(4)
  int mileageAtService;
  @HiveField(5)
  double? cost;
  @HiveField(6)
  String? serviceProvider;
  @HiveField(7)
  String? notes;
  @HiveField(8)
  DateTime? nextDueDate;
  @HiveField(9)
  int? nextDueMileage;

  MaintenanceEntry({
    required this.id,
    required this.vehicleId,
    required this.category,
    required this.date,
    required this.mileageAtService,
    this.cost,
    this.serviceProvider,
    this.notes,
    this.nextDueDate,
    this.nextDueMileage,
  });

  String get categoryLabelRo {
    switch (category) {
      case MaintenanceCategory.ulei:
        return 'Schimb ulei';
      case MaintenanceCategory.filtre:
        return 'Filtre';
      case MaintenanceCategory.placute:
        return 'Plăcuțe frână';
      case MaintenanceCategory.anvelope:
        return 'Anvelope';
      case MaintenanceCategory.baterie:
        return 'Baterie';
      case MaintenanceCategory.revizie:
        return 'Revizie';
      case MaintenanceCategory.altele:
        return 'Altele';
    }
  }
}
