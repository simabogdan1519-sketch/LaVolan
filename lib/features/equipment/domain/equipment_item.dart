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

  /// Whether this kind of equipment can expire (extinguisher needs
  /// recertification, first-aid kit medicines expire).
  bool get canExpire {
    switch (this) {
      case EquipmentType.extinctor:
      case EquipmentType.trusaMedicala:
        return true;
      default:
        return false;
    }
  }

  /// Cantitate minimă recomandată/cerută de lege pentru un autoturism.
  /// Triunghi: 1 (2 pentru remorci/camion). Vestă: minim 1. Roată: 1.
  int get minRequiredQuantity {
    switch (this) {
      case EquipmentType.extinctor:
      case EquipmentType.trusaMedicala:
      case EquipmentType.triunghiReflectorizant:
      case EquipmentType.vestaReflectorizanta:
      case EquipmentType.rotiRezerva:
        return 1;
      case EquipmentType.altul:
        return 0;
    }
  }

  /// Hint scurt afișat sub câmpul cantitate.
  String get quantityHintRo {
    switch (this) {
      case EquipmentType.extinctor:
        return 'Necesar: minim 1 (recertificat la 5 ani)';
      case EquipmentType.trusaMedicala:
        return 'Necesar: minim 1 (medicamentele expiră)';
      case EquipmentType.triunghiReflectorizant:
        return 'Necesar: minim 1 (2 pentru remorci/camion)';
      case EquipmentType.vestaReflectorizanta:
        return 'Necesar: minim 1 (recomandat câte una per ocupant)';
      case EquipmentType.rotiRezerva:
        return 'Recomandat: 1 (roată de rezervă sau kit reparat)';
      case EquipmentType.altul:
        return '';
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
  @HiveField(9)
  int quantity;

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
    this.quantity = 1,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isExpired =>
      expiryDate != null && expiryDate!.isBefore(DateTime.now());

  int? get daysUntilExpiry =>
      expiryDate?.difference(DateTime.now()).inDays;

  /// Has the user enough of this kind?
  bool get isQuantityOk => quantity >= type.minRequiredQuantity;
}
