part of 'fuel_entry.dart';

class FuelEntryAdapter extends TypeAdapter<FuelEntry> {
  @override
  final int typeId = 6;

  @override
  FuelEntry read(BinaryReader r) {
    final n = r.readByte();
    final f = <int, dynamic>{for (var i = 0; i < n; i++) r.readByte(): r.read()};
    return FuelEntry(
      id: f[0] as String,
      vehicleId: f[1] as String,
      date: f[2] as DateTime,
      liters: f[3] as double,
      pricePerLiter: f[4] as double,
      totalCost: f[5] as double,
      mileage: f[6] as int,
      fullTank: f[7] as bool? ?? true,
      station: f[8] as String?,
      notes: f[9] as String?,
    );
  }

  @override
  void write(BinaryWriter w, FuelEntry o) {
    w
      ..writeByte(10)
      ..writeByte(0)..write(o.id)
      ..writeByte(1)..write(o.vehicleId)
      ..writeByte(2)..write(o.date)
      ..writeByte(3)..write(o.liters)
      ..writeByte(4)..write(o.pricePerLiter)
      ..writeByte(5)..write(o.totalCost)
      ..writeByte(6)..write(o.mileage)
      ..writeByte(7)..write(o.fullTank)
      ..writeByte(8)..write(o.station)
      ..writeByte(9)..write(o.notes);
  }
}
