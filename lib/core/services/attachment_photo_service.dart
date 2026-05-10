import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Salvează poze de tip "atașament" (poze de pe scan-uri de documente,
/// poze de echipament, etc.) într-un folder permanent al aplicației.
///
/// Why a dedicated copy: image_picker / OCR îți dau căi din cache-ul
/// sistemului care pot dispărea. Copiem în app documents directory ca
/// poza să persiste cât trăiește datul lor.
class AttachmentPhotoService {
  AttachmentPhotoService._();
  static final AttachmentPhotoService instance = AttachmentPhotoService._();

  final ImagePicker _picker = ImagePicker();

  Future<Directory> _attachmentsDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'attachments'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Permite alegerea unei poze (cameră sau galerie) și o copiază în
  /// folderul permanent. Returnează calea absolută sau `null` dacă a
  /// renunțat. [scope] — prefix opțional pentru numele fișierului
  /// (e.g. `doc-123` sau `eq-456`), pentru navigare manuală mai ușoară.
  Future<String?> pickAndStore({
    required ImageSource source,
    String scope = 'attachment',
  }) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1800,
      maxHeight: 1800,
      imageQuality: 85,
    );
    if (picked == null) return null;
    return storeFromPath(sourcePath: picked.path, scope: scope);
  }

  /// Copiază un fișier dintr-un path arbitrar (e.g. cache-ul OCR-ului)
  /// în folderul nostru, cu un nume nou. Util pentru pozele rezultate
  /// din scanare cu camera, ca să nu dispară.
  Future<String> storeFromPath({
    required String sourcePath,
    String scope = 'attachment',
  }) async {
    final dir = await _attachmentsDir();
    final ext = p.extension(sourcePath).isNotEmpty
        ? p.extension(sourcePath)
        : '.jpg';
    final ts = DateTime.now().millisecondsSinceEpoch;
    final destPath = p.join(dir.path, '$scope-$ts$ext');
    final destFile = await File(sourcePath).copy(destPath);
    return destFile.path;
  }

  /// Șterge un atașament. No-op dacă nu există.
  Future<void> delete(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {
      // best effort
    }
  }
}
