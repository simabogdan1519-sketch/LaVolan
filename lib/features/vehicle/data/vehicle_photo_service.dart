import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Persists vehicle profile photos in the app documents directory.
///
/// Why copy: when image_picker returns a path from the gallery or camera
/// cache, that path can be deleted by the OS at any time. We copy into
/// our own folder so the file survives.
class VehiclePhotoService {
  VehiclePhotoService._();
  static final VehiclePhotoService instance = VehiclePhotoService._();

  final ImagePicker _picker = ImagePicker();

  Future<Directory> _photosDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'vehicle_photos'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Lets the user pick a photo from camera or gallery and copies it
  /// into permanent storage. Returns the absolute path of the stored
  /// copy, or `null` if the user cancelled.
  Future<String?> pickAndStore({
    required String vehicleId,
    required ImageSource source,
  }) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (picked == null) return null;
    return _storeFromPath(vehicleId: vehicleId, sourcePath: picked.path);
  }

  Future<String> _storeFromPath({
    required String vehicleId,
    required String sourcePath,
  }) async {
    final dir = await _photosDir();
    final ext = p.extension(sourcePath).isNotEmpty
        ? p.extension(sourcePath)
        : '.jpg';
    final ts = DateTime.now().millisecondsSinceEpoch;
    final destPath = p.join(dir.path, '${vehicleId}_$ts$ext');
    final destFile = await File(sourcePath).copy(destPath);
    return destFile.path;
  }

  /// Deletes a previously stored photo. No-op if the file is missing.
  Future<void> delete(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final f = File(path);
      if (await f.exists()) {
        await f.delete();
      }
    } catch (_) {
      // ignore — best effort
    }
  }
}
