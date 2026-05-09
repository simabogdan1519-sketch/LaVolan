part of 'maintenance_entry.dart';

class MaintenanceCategoryAdapter extends TypeAdapter<MaintenanceCategory> {
  @override
  final int typeId = 4;

  @override
  MaintenanceCategory read(BinaryReader r) => MaintenanceCategory.values[r.readByte()];

  @override
  void write(BinaryWriter w, MaintenanceCategory o) => w.writeByte(o.index);
}

class MaintenanceEntryAdapter extends TypeAdapter<MaintenanceEntry> {
  @override
  final int typeId = 5;

  @override
  MaintenanceEntry read(BinaryReader r) {
    final n = r.readByte();
    final f = <int, dynamic>{for (var i = 0; i < n; i++) r.readByte(): r.read()};
    return MaintenanceEntry(
      id: f[0] as String,
      vehicleId: f[1] as String,
      category: f[2] as MaintenanceCategory,
      date: f[3] as DateTime,
      mileageAtService: f[4] as int,
      cost: f[5] as double?,
      serviceProvider: f[6] as String?,
      notes: f[7] as String?,
      nextDueDate: f[8] as DateTime?,
      nextDueMileage: f[9] as int?,
    );
  }

  @override
  void write(BinaryWriter w, MaintenanceEntry o) {
    w
      ..writeByte(10)
      ..writeByte(0)..write(o.id)
      ..writeByte(1)..write(o.vehicleId)
      ..writeByte(2)..write(o.category)
      ..writeByte(3)..write(o.date)
      ..writeByte(4)..write(o.mileageAtService)
      ..writeByte(5)..write(o.cost)
      ..writeByte(6)..write(o.serviceProvider)
      ..writeByte(7)..write(o.notes)
      ..writeByte(8)..write(o.nextDueDate)
      ..writeByte(9)..write(o.nextDueMileage);
  }
}
