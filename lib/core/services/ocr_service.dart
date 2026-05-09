import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../features/documents/domain/document.dart';

class OcrResult {
  final DocumentType? detectedType;
  final DateTime? expiryDate;
  final DateTime? issueDate;
  final String? licensePlate;
  final String? issuer;
  final String? policyNumber;
  final String rawText;
  final double confidence;

  OcrResult({
    this.detectedType,
    this.expiryDate,
    this.issueDate,
    this.licensePlate,
    this.issuer,
    this.policyNumber,
    required this.rawText,
    this.confidence = 0,
  });
}

/// Abstract layer so we can swap implementations (cloud OCR, etc.)
abstract class OcrProcessingService {
  Future<OcrResult> processImage(File imageFile);
  Future<void> dispose();
}

class MlKitOcrService implements OcrProcessingService {
  final TextRecognizer _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  @override
  Future<OcrResult> processImage(File imageFile) async {
    final input = InputImage.fromFile(imageFile);
    final result = await _recognizer.processImage(input);
    final text = result.text;
    return _parse(text);
  }

  OcrResult _parse(String raw) {
    final upper = raw.toUpperCase();

    // Detect type by keywords
    DocumentType? type;
    if (RegExp(r'\bRCA\b|RASPUNDERE CIVILA|ASIGURARE OBLIGATORIE').hasMatch(upper)) {
      type = DocumentType.rca;
    } else if (RegExp(r'\bITP\b|INSPEC[TȚ]IE TEHNIC[ĂA]').hasMatch(upper)) {
      type = DocumentType.itp;
    } else if (RegExp(r'ROVINIET').hasMatch(upper)) {
      type = DocumentType.rovinieta;
    } else if (RegExp(r'CERTIFICAT DE [ÎI]NMATRICULARE|TALON').hasMatch(upper)) {
      type = DocumentType.talon;
    }

    // License plate (Romanian format: XX 123 XXX or B 123 XXX)
    final plateMatch = RegExp(
      r'\b([A-Z]{1,2})[\s-]?(\d{2,3})[\s-]?([A-Z]{3})\b',
    ).firstMatch(upper);
    final licensePlate = plateMatch?.group(0)?.replaceAll(RegExp(r'\s+'), ' ');

    // Dates – grab all dd.mm.yyyy / dd/mm/yyyy / dd-mm-yyyy occurrences
    final dateRegex = RegExp(r'(\d{2})[./-](\d{2})[./-](\d{4})');
    final allDates = dateRegex.allMatches(raw).map((m) {
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

    DateTime? issue;
    DateTime? expiry;
    if (allDates.isNotEmpty) {
      allDates.sort();
      // earliest = issue, latest = expiry (heuristic)
      issue = allDates.first;
      expiry = allDates.last;
      if (issue.isAtSameMomentAs(expiry)) issue = null;
    }

    // Issuer (RCA) – simple heuristic: capture company-ish line near 'ASIGURATOR' / 'ALLIANZ' / 'OMNIASIG' etc.
    String? issuer;
    final knownInsurers = [
      'ALLIANZ', 'ASIROM', 'OMNIASIG', 'GROUPAMA', 'CITY INSURANCE',
      'EUROINS', 'GENERALI', 'UNIQA', 'GRAWE', 'POOL ROMÂN',
    ];
    for (final ins in knownInsurers) {
      if (upper.contains(ins)) {
        issuer = ins;
        break;
      }
    }

    // Policy number (sequence of 8+ alphanumerics that includes digits)
    String? policy;
    final polMatch = RegExp(r'\b([A-Z0-9]{8,16})\b').allMatches(upper)
        .where((m) => RegExp(r'\d').hasMatch(m.group(0)!))
        .toList();
    if (polMatch.isNotEmpty) {
      policy = polMatch.first.group(0);
    }

    final hits = [type, expiry, licensePlate].where((e) => e != null).length;
    final confidence = hits / 3.0;

    return OcrResult(
      detectedType: type,
      issueDate: issue,
      expiryDate: expiry,
      licensePlate: licensePlate,
      issuer: issuer,
      policyNumber: policy,
      rawText: raw,
      confidence: confidence,
    );
  }

  @override
  Future<void> dispose() async {
    await _recognizer.close();
  }
}
