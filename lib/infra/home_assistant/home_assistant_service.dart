import 'dart:convert';

import '../../core/services/storage_service.dart';
import '../../features/documents/domain/document.dart';
import '../../features/penalty_points/data/penalty_repository.dart';
import '../../features/vehicle/domain/vehicle.dart';

/// Stub service that prepares vehicle / document / maintenance state
/// for Home Assistant ingestion. The data model below maps cleanly to
/// MQTT topics or HA REST sensor payloads.
///
/// Topic conventions (suggested):
///   lavolan/vehicle/<id>/state
///   lavolan/vehicle/<id>/document/<type>
///   lavolan/vehicle/<id>/maintenance
///   lavolan/penalty/state
class HomeAssistantService {
  HomeAssistantService._();
  static final HomeAssistantService instance = HomeAssistantService._();

  Map<String, dynamic> buildVehiclePayload(Vehicle v) {
    return {
      'id': v.id,
      'name': v.displayName,
      'license_plate': v.licensePlate,
      'fuel_type': v.fuelLabelRo,
      'mileage_km': v.mileage,
    };
  }

  Map<String, dynamic> buildDocumentPayload(VehicleDocument d) {
    return {
      'id': d.id,
      'vehicle_id': d.vehicleId,
      'type': d.typeLabelRo,
      'expiry_iso': d.expiryDate.toIso8601String(),
      'days_until_expiry':
          d.expiryDate.difference(DateTime.now()).inDays,
      'status': d.status.name,
      if (d.issuer != null) 'issuer': d.issuer,
    };
  }

  /// Aggregated JSON state, ready to be POSTed to a Home Assistant
  /// REST sensor or published to MQTT as a single retained message.
  Future<String> exportState() async {
    final storage = StorageService.instance;
    final vehicles = storage.vehicles.values
        .map(buildVehiclePayload)
        .toList(growable: false);
    final docs = storage.documents.values
        .map(buildDocumentPayload)
        .toList(growable: false);

    final penaltyStats =
        PenaltyRepository(storage).stats();

    final state = {
      'app': 'lavolan',
      'generated_at': DateTime.now().toIso8601String(),
      'vehicles': vehicles,
      'documents': docs,
      'penalty': {
        'active_points': penaltyStats.activePoints,
        'risk': penaltyStats.risk.name,
        'entries': penaltyStats.totalEntries,
      },
    };
    return const JsonEncoder.withIndent('  ').convert(state);
  }

  /// Future: actual POST to HA REST API
  Future<bool> publishState({required String url, required String token}) async {
    // Real implementation will use http.post with bearer token.
    // Stubbed here to keep the app offline-first.
    return true;
  }
}
