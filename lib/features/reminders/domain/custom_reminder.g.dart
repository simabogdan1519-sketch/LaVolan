part of 'custom_reminder.dart';

class ReminderIntervalAdapter extends TypeAdapter<ReminderInterval> {
  @override
  final int typeId = 10;

  @override
  ReminderInterval read(BinaryReader reader) =>
      ReminderInterval.values[reader.readByte()];

  @override
  void write(BinaryWriter writer, ReminderInterval obj) =>
      writer.writeByte(obj.index);
}

class CustomReminderAdapter extends TypeAdapter<CustomReminder> {
  @override
  final int typeId = 11;

  @override
  CustomReminder read(BinaryReader reader) {
    final n = reader.readByte();
    final f = <int, dynamic>{
      for (var i = 0; i < n; i++) reader.readByte(): reader.read(),
    };
    return CustomReminder(
      id: f[0] as String,
      title: f[1] as String,
      body: f[2] as String?,
      startDate: f[3] as DateTime,
      hour: f[4] as int,
      minute: f[5] as int,
      interval: f[6] as ReminderInterval,
      customIntervalDays: f[7] as int,
      occurrencesCount: f[8] as int?,
      firedCount: f[9] as int,
      enabled: f[10] as bool,
      vehicleId: f[11] as String?,
      createdAt: f[12] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, CustomReminder o) {
    writer
      ..writeByte(13)
      ..writeByte(0)..write(o.id)
      ..writeByte(1)..write(o.title)
      ..writeByte(2)..write(o.body)
      ..writeByte(3)..write(o.startDate)
      ..writeByte(4)..write(o.hour)
      ..writeByte(5)..write(o.minute)
      ..writeByte(6)..write(o.interval)
      ..writeByte(7)..write(o.customIntervalDays)
      ..writeByte(8)..write(o.occurrencesCount)
      ..writeByte(9)..write(o.firedCount)
      ..writeByte(10)..write(o.enabled)
      ..writeByte(11)..write(o.vehicleId)
      ..writeByte(12)..write(o.createdAt);
  }
}
