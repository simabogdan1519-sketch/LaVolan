/// Telemetry interface — independent of physical transport (Bluetooth ELM327,
/// WiFi OBD, USB, etc.). All future OBD2 implementations conform to this.
abstract class VehicleTelemetryService {
  Future<bool> connect();
  Future<void> disconnect();
  bool get isConnected;

  Future<TelemetrySnapshot> read();
  Stream<TelemetrySnapshot> watch();
}

class TelemetrySnapshot {
  final DateTime at;
  final double? speedKmh;
  final double? rpm;
  final double? engineTempC;
  final double? batteryVoltage;
  final double? fuelLevelPct;
  final List<String> dtcCodes;

  const TelemetrySnapshot({
    required this.at,
    this.speedKmh,
    this.rpm,
    this.engineTempC,
    this.batteryVoltage,
    this.fuelLevelPct,
    this.dtcCodes = const [],
  });
}

/// Placeholder mock implementation — will be replaced by an ELM327
/// Bluetooth driver in a future release.
class MockTelemetryService implements VehicleTelemetryService {
  bool _connected = false;

  @override
  bool get isConnected => _connected;

  @override
  Future<bool> connect() async {
    _connected = true;
    return true;
  }

  @override
  Future<void> disconnect() async => _connected = false;

  @override
  Future<TelemetrySnapshot> read() async {
    if (!_connected) {
      throw StateError('Telemetry service not connected');
    }
    return TelemetrySnapshot(
      at: DateTime.now(),
      speedKmh: 0,
      rpm: 800,
      engineTempC: 90,
      batteryVoltage: 12.6,
      fuelLevelPct: 50,
    );
  }

  @override
  Stream<TelemetrySnapshot> watch() async* {
    while (_connected) {
      yield await read();
      await Future.delayed(const Duration(seconds: 1));
    }
  }
}
