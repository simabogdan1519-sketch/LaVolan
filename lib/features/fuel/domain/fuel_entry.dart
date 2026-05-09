import 'package:hive/hive.dart';

part 'fuel_entry.g.dart';

@HiveType(typeId: 6)
class FuelEntry extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String vehicleId;
  @HiveField(2)
  DateTime date;
  @HiveField(3)
  double liters;
  @HiveField(4)
  double pricePerLiter;
  @HiveField(5)
  double totalCost;
  @HiveField(6)
  int mileage;
  @HiveField(7)
  bool fullTank;
  @HiveField(8)
  String? station;
  @HiveField(9)
  String? notes;

  FuelEntry({
    required this.id,
    required this.vehicleId,
    required this.date,
    required this.liters,
    required this.pricePerLiter,
    required this.totalCost,
    required this.mileage,
    this.fullTank = true,
    this.station,
    this.notes,
  });
}
