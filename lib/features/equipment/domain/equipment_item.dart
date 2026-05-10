import 'package:hive/hive.dart';

part 'equipment_item.g.dart';

@HiveType(typeId: 8)
enum EquipmentType {
  @HiveField(0)
  extinctor,
  @HiveField(1)
  trusaMedicala,
  @HiveField(2)
  triunghiReflectorizant,
  @HiveField(3)
  vestaReflectorizanta,
  @HiveField(4)
  rotiRezerva,
  @HiveField(5)
  altul,
}

extension EquipmentTypeInfo on EquipmentType {
  String get labelRo {
    switch (this) {
      case EquipmentType.extinctor:
        return 'Extinctor';
      case EquipmentType.trusaMedicala:
        return 'Trusă medicală';
      case EquipmentType.triunghiReflectorizant:
        return 'Triunghi reflectorizant';
      case EquipmentType.vestaReflectorizanta:
        return 'Vestă reflectorizantă';
      case EquipmentType.rotiRezerva:
        return 'Roată de rezervă';
      case EquipmentType.altul:
        return 'Altul';
    }
  }

  /// Whether this kind of equipment can expire (extinguisher, first-aid kit).
  bool get canExpire {
    switch (this) {
      case EquipmentType.extinctor:
      case EquipmentType.trusaMedicala:
        return true;
      default:
        return false;
    }
  }
}

@HiveType(typeId: 9)
class EquipmentItem extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String vehicleId;
  @HiveField(2)
  EquipmentType type;
  @HiveField(3)
  DateTime? expiryDate;
  @HiveField(4)
  DateTime? purchaseDate;
  @HiveField(5)
  String? brand;
  @HiveField(6)
  String? imagePath;
  @HiveField(7)
  String? notes;
  @HiveField(8)
  DateTime createdAt;

  EquipmentItem({
    required this.id,
    required this.vehicleId,
    required this.type,
    this.expiryDate,
    this.purchaseDate,
    this.brand,
    this.imagePath,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isExpired =>
      expiryDate != null && expiryDate!.isBefore(DateTime.now());

  int? get daysUntilExpiry =>
      expiryDate?.difference(DateTime.now()).inDays;
}
