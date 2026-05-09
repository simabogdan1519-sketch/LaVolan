import 'package:hive/hive.dart';

part 'vehicle.g.dart';

@HiveType(typeId: 0)
enum FuelType {
  @HiveField(0)
  benzina,
  @HiveField(1)
  motorina,
  @HiveField(2)
  hibrid,
  @HiveField(3)
  electric,
  @HiveField(4)
  gpl,
}

@HiveType(typeId: 1)
class Vehicle extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  String brand;
  @HiveField(2)
  String model;
  @HiveField(3)
  int year;
  @HiveField(4)
  String licensePlate;
  @HiveField(5)
  FuelType fuelType;
  @HiveField(6)
  int mileage;
  @HiveField(7)
  String? vin;
  @HiveField(8)
  String? notes;
  @HiveField(9)
  DateTime createdAt;
  @HiveField(10)
  String? photoPath;

  Vehicle({
    required this.id,
    required this.brand,
    required this.model,
    required this.year,
    required this.licensePlate,
    required this.fuelType,
    required this.mileage,
    this.vin,
    this.notes,
    DateTime? createdAt,
    this.photoPath,
  }) : createdAt = createdAt ?? DateTime.now();

  String get displayName => '$brand $model ($year)';

  String get fuelLabelRo {
    switch (fuelType) {
      case FuelType.benzina:
        return 'Benzină';
      case FuelType.motorina:
        return 'Motorină';
      case FuelType.hibrid:
        return 'Hibrid';
      case FuelType.electric:
        return 'Electric';
      case FuelType.gpl:
        return 'GPL';
    }
  }
}
