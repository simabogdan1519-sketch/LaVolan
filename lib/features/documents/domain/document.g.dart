part of 'document.dart';

class DocumentTypeAdapter extends TypeAdapter<DocumentType> {
  @override
  final int typeId = 2;

  @override
  DocumentType read(BinaryReader reader) => DocumentType.values[reader.readByte()];

  @override
  void write(BinaryWriter writer, DocumentType obj) => writer.writeByte(obj.index);
}

class VehicleDocumentAdapter extends TypeAdapter<VehicleDocument> {
  @override
  final int typeId = 3;

  @override
  VehicleDocument read(BinaryReader reader) {
    final n = reader.readByte();
    final f = <int, dynamic>{
      for (var i = 0; i < n; i++) reader.readByte(): reader.read(),
    };
    return VehicleDocument(
      id: f[0] as String,
      vehicleId: f[1] as String,
      type: f[2] as DocumentType,
      issueDate: f[3] as DateTime,
      expiryDate: f[4] as DateTime,
      issuer: f[5] as String?,
      policyNumber: f[6] as String?,
      cost: f[7] as double?,
      imagePath: f[8] as String?,
      notes: f[9] as String?,
      createdAt: f[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, VehicleDocument o) {
    writer
      ..writeByte(11)
      ..writeByte(0)..write(o.id)
      ..writeByte(1)..write(o.vehicleId)
      ..writeByte(2)..write(o.type)
      ..writeByte(3)..write(o.issueDate)
      ..writeByte(4)..write(o.expiryDate)
      ..writeByte(5)..write(o.issuer)
      ..writeByte(6)..write(o.policyNumber)
      ..writeByte(7)..write(o.cost)
      ..writeByte(8)..write(o.imagePath)
      ..writeByte(9)..write(o.notes)
      ..writeByte(10)..write(o.createdAt);
  }
}
