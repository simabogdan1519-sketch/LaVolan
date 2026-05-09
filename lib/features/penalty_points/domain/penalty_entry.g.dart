part of 'penalty_entry.dart';

class PenaltyEntryAdapter extends TypeAdapter<PenaltyEntry> {
  @override
  final int typeId = 7;

  @override
  PenaltyEntry read(BinaryReader r) {
    final n = r.readByte();
    final f = <int, dynamic>{for (var i = 0; i < n; i++) r.readByte(): r.read()};
    return PenaltyEntry(
      id: f[0] as String,
      date: f[1] as DateTime,
      points: f[2] as int,
      reason: f[3] as String?,
      fineAmount: f[4] as double?,
      location: f[5] as String?,
    );
  }

  @override
  void write(BinaryWriter w, PenaltyEntry o) {
    w
      ..writeByte(6)
      ..writeByte(0)..write(o.id)
      ..writeByte(1)..write(o.date)
      ..writeByte(2)..write(o.points)
      ..writeByte(3)..write(o.reason)
      ..writeByte(4)..write(o.fineAmount)
      ..writeByte(5)..write(o.location);
  }
}
