part of 'equipment_item.dart';

class EquipmentTypeAdapter extends TypeAdapter<EquipmentType> {
  @override
  final int typeId = 8;

  @override
  EquipmentType read(BinaryReader reader) =>
      EquipmentType.values[reader.readByte()];

  @override
  void write(BinaryWriter writer, EquipmentType obj) =>
      writer.writeByte(obj.index);
}

class EquipmentItemAdapter extends TypeAdapter<EquipmentItem> {
  @override
  final int typeId = 9;

  @override
  EquipmentItem read(BinaryReader reader) {
    final n = reader.readByte();
    final f = <int, dynamic>{
      for (var i = 0; i < n; i++) reader.readByte(): reader.read(),
    };
    return EquipmentItem(
      id: f[0] as String,
      vehicleId: f[1] as String,
      type: f[2] as EquipmentType,
      expiryDate: f[3] as DateTime?,
      purchaseDate: f[4] as DateTime?,
      brand: f[5] as String?,
      imagePath: f[6] as String?,
      notes: f[7] as String?,
      createdAt: f[8] as DateTime?,
      // Backward compat: items saved before the quantity field default to 1.
      quantity: (f[9] as int?) ?? 1,
    );
  }

  @override
  void write(BinaryWriter writer, EquipmentItem o) {
    writer
      ..writeByte(10)
      ..writeByte(0)..write(o.id)
      ..writeByte(1)..write(o.vehicleId)
      ..writeByte(2)..write(o.type)
      ..writeByte(3)..write(o.expiryDate)
      ..writeByte(4)..write(o.purchaseDate)
      ..writeByte(5)..write(o.brand)
      ..writeByte(6)..write(o.imagePath)
      ..writeByte(7)..write(o.notes)
      ..writeByte(8)..write(o.createdAt)
      ..writeByte(9)..write(o.quantity);
  }
}
