// GENERATED-LIKE FILE: hand-written Hive adapters to avoid build_runner step.
// If build_runner is run, replace with generated *.g.dart.
part of 'vehicle.dart';

class FuelTypeAdapter extends TypeAdapter<FuelType> {
  @override
  final int typeId = 0;

  @override
  FuelType read(BinaryReader reader) {
    final i = reader.readByte();
    return FuelType.values[i];
  }

  @override
  void write(BinaryWriter writer, FuelType obj) {
    writer.writeByte(obj.index);
  }
}

class VehicleAdapter extends TypeAdapter<Vehicle> {
  @override
  final int typeId = 1;

  @override
  Vehicle read(BinaryReader reader) {
    final n = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < n; i++) reader.readByte(): reader.read(),
    };
    return Vehicle(
      id: fields[0] as String,
      brand: fields[1] as String,
      model: fields[2] as String,
      year: fields[3] as int,
      licensePlate: fields[4] as String,
      fuelType: fields[5] as FuelType,
      mileage: fields[6] as int,
      vin: fields[7] as String?,
      notes: fields[8] as String?,
      createdAt: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Vehicle obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.brand)
      ..writeByte(2)..write(obj.model)
      ..writeByte(3)..write(obj.year)
      ..writeByte(4)..write(obj.licensePlate)
      ..writeByte(5)..write(obj.fuelType)
      ..writeByte(6)..write(obj.mileage)
      ..writeByte(7)..write(obj.vin)
      ..writeByte(8)..write(obj.notes)
      ..writeByte(9)..write(obj.createdAt);
  }
}
