import 'package:hive/hive.dart';

part 'document.g.dart';

@HiveType(typeId: 2)
enum DocumentType {
  @HiveField(0)
  rca,
  @HiveField(1)
  itp,
  @HiveField(2)
  rovinieta,
  @HiveField(3)
  talon,
  @HiveField(4)
  altul,
  @HiveField(5)
  buletin,
  @HiveField(6)
  permis,
}

extension DocumentTypeKind on DocumentType {
  /// Whether this document belongs to a vehicle (as opposed to a person).
  bool get isVehicleDocument {
    switch (this) {
      case DocumentType.buletin:
      case DocumentType.permis:
        return false;
      case DocumentType.rca:
      case DocumentType.itp:
      case DocumentType.rovinieta:
      case DocumentType.talon:
      case DocumentType.altul:
        return true;
    }
  }

  bool get isPersonalDocument => !isVehicleDocument;
}

enum DocumentStatus { valid, expiringSoon, expired }

@HiveType(typeId: 3)
class VehicleDocument extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String vehicleId;
  @HiveField(2)
  DocumentType type;
  @HiveField(3)
  DateTime issueDate;
  @HiveField(4)
  DateTime expiryDate;
  @HiveField(5)
  String? issuer;
  @HiveField(6)
  String? policyNumber;
  @HiveField(7)
  double? cost;
  @HiveField(8)
  String? imagePath;
  @HiveField(9)
  String? notes;
  @HiveField(10)
  DateTime createdAt;

  VehicleDocument({
    required this.id,
    required this.vehicleId,
    required this.type,
    required this.issueDate,
    required this.expiryDate,
    this.issuer,
    this.policyNumber,
    this.cost,
    this.imagePath,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  DocumentStatus get status {
    final now = DateTime.now();
    if (expiryDate.isBefore(DateTime(now.year, now.month, now.day))) {
      return DocumentStatus.expired;
    }
    final diff = expiryDate.difference(now).inDays;
    if (diff <= 30) return DocumentStatus.expiringSoon;
    return DocumentStatus.valid;
  }

  String get typeLabelRo {
    switch (type) {
      case DocumentType.rca:
        return 'RCA';
      case DocumentType.itp:
        return 'ITP';
      case DocumentType.rovinieta:
        return 'Rovinietă';
      case DocumentType.talon:
        return 'Talon';
      case DocumentType.altul:
        return 'Altul';
      case DocumentType.buletin:
        return 'Buletin';
      case DocumentType.permis:
        return 'Permis';
    }
  }
}
