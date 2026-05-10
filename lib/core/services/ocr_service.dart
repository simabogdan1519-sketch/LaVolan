import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../features/documents/domain/document.dart';

/// What kind of artifact the user is scanning. Drives parsing strategy.
enum ScanMode {
  /// RCA / ITP / Rovinieta / talon — vehicle legal document.
  vehicleDocument,

  /// PECO/fuel station receipt (bon fiscal).
  fuelReceipt,

  /// CI / buletin / permis de conducere.
  personalDocument,

  /// Auto — try every strategy and return the most confident match.
  auto,
}

/// Unified result. Different modes populate different fields.
class OcrResult {
  // Common
  final String rawText;
  final double confidence;
  final ScanMode resolvedMode;

  // Vehicle / personal documents
  final DocumentType? detectedType;
  final DateTime? expiryDate;
  final DateTime? issueDate;
  final String? licensePlate;
  final String? issuer;
  final String? policyNumber;
  final String? personalDocumentNumber;
  final String? personalCnp;

  // Fuel receipts
  final double? fuelLiters;
  final double? fuelPricePerLiter;
  final double? fuelTotalCost;
  final String? fuelStationName;
  final DateTime? fuelDate;

  const OcrResult({
    required this.rawText,
    this.confidence = 0,
    this.resolvedMode = ScanMode.auto,
    this.detectedType,
    this.expiryDate,
    this.issueDate,
    this.licensePlate,
    this.issuer,
    this.policyNumber,
    this.personalDocumentNumber,
    this.personalCnp,
    this.fuelLiters,
    this.fuelPricePerLiter,
    this.fuelTotalCost,
    this.fuelStationName,
    this.fuelDate,
  });
}

abstract class OcrProcessingService {
  Future<OcrResult> processImage(File imageFile, {ScanMode mode});
  Future<void> dispose();
}

class MlKitOcrService implements OcrProcessingService {
  final TextRecognizer _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  @override
  Future<OcrResult> processImage(File imageFile,
      {ScanMode mode = ScanMode.auto}) async {
    final input = InputImage.fromFile(imageFile);
    final result = await _recognizer.processImage(input);
    final text = result.text;
    return _route(text, mode);
  }

  OcrResult _route(String raw, ScanMode mode) {
    if (mode == ScanMode.vehicleDocument) return _parseVehicleDoc(raw);
    if (mode == ScanMode.fuelReceipt) return _parseFuelReceipt(raw);
    if (mode == ScanMode.personalDocument) return _parsePersonalDoc(raw);

    // Auto: try all three and pick the highest confidence.
    final candidates = <OcrResult>[
      _parseVehicleDoc(raw),
      _parseFuelReceipt(raw),
      _parsePersonalDoc(raw),
    ];
    candidates.sort((a, b) => b.confidence.compareTo(a.confidence));
    return candidates.first;
  }

  // ──────────────── Vehicle docs ────────────────

  OcrResult _parseVehicleDoc(String raw) {
    final upper = raw.toUpperCase();

    DocumentType? type;
    if (RegExp(r'\bRCA\b|RASPUNDERE CIVIL|ASIGURARE OBLIGATORIE')
        .hasMatch(upper)) {
      type = DocumentType.rca;
    } else if (RegExp(r'\bITP\b|INSPEC[TȚ]IE TEHNIC').hasMatch(upper)) {
      type = DocumentType.itp;
    } else if (RegExp(r'ROVINIET').hasMatch(upper)) {
      type = DocumentType.rovinieta;
    } else if (RegExp(r'CERTIFICAT DE [ÎI]NMATRICULARE|TALON')
        .hasMatch(upper)) {
      type = DocumentType.talon;
    }

    final plateMatch = RegExp(
      r'\b([A-Z]{1,2})[\s-]?(\d{2,3})[\s-]?([A-Z]{3})\b',
    ).firstMatch(upper);
    final licensePlate =
        plateMatch?.group(0)?.replaceAll(RegExp(r'\s+'), ' ');

    final allDates = _extractDates(raw);
    DateTime? issue;
    DateTime? expiry;
    if (allDates.isNotEmpty) {
      allDates.sort();
      issue = allDates.first;
      expiry = allDates.last;
      if (issue.isAtSameMomentAs(expiry)) issue = null;
    }

    String? issuer;
    const knownInsurers = [
      'ALLIANZ', 'ASIROM', 'OMNIASIG', 'GROUPAMA', 'CITY INSURANCE',
      'EUROINS', 'GENERALI', 'UNIQA', 'GRAWE', 'POOL ROMÂN',
    ];
    for (final ins in knownInsurers) {
      if (upper.contains(ins)) {
        issuer = ins;
        break;
      }
    }

    String? policy;
    final polMatch = RegExp(r'\b([A-Z0-9]{8,16})\b')
        .allMatches(upper)
        .where((m) => RegExp(r'\d').hasMatch(m.group(0)!))
        .toList();
    if (polMatch.isNotEmpty) {
      policy = polMatch.first.group(0);
    }

    final hits = [type, expiry, licensePlate].where((e) => e != null).length;
    return OcrResult(
      rawText: raw,
      resolvedMode: ScanMode.vehicleDocument,
      detectedType: type,
      issueDate: issue,
      expiryDate: expiry,
      licensePlate: licensePlate,
      issuer: issuer,
      policyNumber: policy,
      confidence: hits / 3.0,
    );
  }

  // ──────────────── Fuel receipts ────────────────

  OcrResult _parseFuelReceipt(String raw) {
    final upper = raw.toUpperCase();

    // Station detection
    String? station;
    const knownStations = [
      'OMV', 'PETROM', 'OMV PETROM', 'ROMPETROL', 'LUKOIL', 'MOL',
      'GAZPROM', 'NIS', 'SOCAR', 'AVIA', 'EVRON',
    ];
    for (final st in knownStations) {
      if (upper.contains(st)) {
        station = st;
        break;
      }
    }

    // Liters: look for patterns like "12.34 L" or "12,34 LITRI" or "L 12.34"
    double? liters;
    final litersRegex = RegExp(
      r'(\d{1,3}[.,]\d{1,3})\s*L(?:ITRI|TR|\b)',
      caseSensitive: false,
    );
    final litersAlt = RegExp(r'L(?:ITRI)?[\s:]*(\d{1,3}[.,]\d{1,3})',
        caseSensitive: false);
    final lm = litersRegex.firstMatch(upper) ?? litersAlt.firstMatch(upper);
    if (lm != null) {
      liters = _parseNumber(lm.group(1));
    }

    // Price per liter: "6.85 LEI/L" or "PRET UNITAR 6,85"
    double? ppl;
    final pplRegex = RegExp(
      r'(\d{1,2}[.,]\d{2,3})\s*(?:LEI\s*)?[/]\s*L',
      caseSensitive: false,
    );
    final pplAlt = RegExp(
      r'PRET\s*UNITAR[\s:]*(\d{1,2}[.,]\d{2,3})',
      caseSensitive: false,
    );
    final pm = pplRegex.firstMatch(upper) ?? pplAlt.firstMatch(upper);
    if (pm != null) {
      ppl = _parseNumber(pm.group(1));
    }

    // Total: "TOTAL 234,56" or "TOTAL DE PLATA 234.56" or "234.56 LEI" near TOTAL
    double? total;
    final totalRegex = RegExp(
      r'TOTAL(?:\s*DE\s*PLAT[ĂA])?[\s:]*(\d{1,5}[.,]\d{1,2})',
      caseSensitive: false,
    );
    final tm = totalRegex.firstMatch(upper);
    if (tm != null) {
      total = _parseNumber(tm.group(1));
    } else if (liters != null && ppl != null) {
      total = double.parse((liters * ppl).toStringAsFixed(2));
    }

    // Date — pick the latest plausible date
    final dates = _extractDates(raw);
    DateTime? date;
    if (dates.isNotEmpty) {
      dates.sort();
      date = dates.last;
    }

    final hits = [station, liters, total].where((e) => e != null).length;
    return OcrResult(
      rawText: raw,
      resolvedMode: ScanMode.fuelReceipt,
      fuelLiters: liters,
      fuelPricePerLiter: ppl,
      fuelTotalCost: total,
      fuelStationName: station,
      fuelDate: date,
      confidence: hits / 3.0,
    );
  }

  // ──────────────── Personal documents (CI / permis) ────────────────

  OcrResult _parsePersonalDoc(String raw) {
    final upper = raw.toUpperCase();

    DocumentType? type;
    if (RegExp(r'CARTE DE IDENTITATE|CARD DE IDENTITATE|BULETIN')
        .hasMatch(upper)) {
      type = DocumentType.buletin;
    } else if (RegExp(r'PERMIS DE CONDUCERE|DRIVING LICEN[SC]E')
        .hasMatch(upper)) {
      type = DocumentType.permis;
    }

    // CNP: 13 digits
    String? cnp;
    final cnpMatch = RegExp(r'\b(\d{13})\b').firstMatch(raw);
    if (cnpMatch != null) cnp = cnpMatch.group(1);

    // Document number: 6-9 alphanumeric (CI: 2 letters + 6 digits, e.g. TM 123456)
    String? docNumber;
    final docNumMatch =
        RegExp(r'\b([A-Z]{2})[\s-]?(\d{6})\b').firstMatch(upper);
    if (docNumMatch != null) {
      docNumber = '${docNumMatch.group(1)} ${docNumMatch.group(2)}';
    }

    final dates = _extractDates(raw);
    DateTime? issue;
    DateTime? expiry;
    if (dates.isNotEmpty) {
      dates.sort();
      // For an ID, expiry is usually the future-most date.
      final now = DateTime.now();
      final future = dates.where((d) => d.isAfter(now)).toList();
      if (future.isNotEmpty) {
        expiry = future.last;
      } else {
        expiry = dates.last;
      }
      issue = dates.first;
      if (issue.isAtSameMomentAs(expiry)) issue = null;
    }

    final hits =
        [type, cnp, docNumber, expiry].where((e) => e != null).length;
    return OcrResult(
      rawText: raw,
      resolvedMode: ScanMode.personalDocument,
      detectedType: type,
      issueDate: issue,
      expiryDate: expiry,
      personalDocumentNumber: docNumber,
      personalCnp: cnp,
      confidence: hits / 4.0,
    );
  }

  // ──────────────── Helpers ────────────────

  List<DateTime> _extractDates(String raw) {
    final dateRegex = RegExp(r'(\d{2})[./-](\d{2})[./-](\d{4})');
    return dateRegex.allMatches(raw).map((m) {
      try {
        return DateTime(
          int.parse(m.group(3)!),
          int.parse(m.group(2)!),
          int.parse(m.group(1)!),
        );
      } catch (_) {
        return null;
      }
    }).whereType<DateTime>().toList();
  }

  double? _parseNumber(String? raw) {
    if (raw == null) return null;
    return double.tryParse(raw.replaceAll(',', '.'));
  }

  @override
  Future<void> dispose() async {
    await _recognizer.close();
  }
}
