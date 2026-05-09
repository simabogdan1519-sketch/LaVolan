import 'dart:io';

import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

import '../../../core/theme/nimbus_tokens.dart';
import '../domain/vehicle.dart';

/// Builds a [NimbusVehicleTint] for the mesh backdrop. Strategy:
///   1. If the vehicle has a photo → extract a 4-stop palette from it.
///   2. Otherwise fall back to a brand-keyed default.
///   3. Otherwise a neutral indigo tint.
///
/// Cached per vehicle id to avoid re-decoding the image on every rebuild.
class VehicleTintService {
  VehicleTintService._();
  static final VehicleTintService instance = VehicleTintService._();

  final Map<String, NimbusVehicleTint> _cache = {};

  static const NimbusVehicleTint _neutral = NimbusVehicleTint(
    a: Color(0xFF9CC4DA),
    b: Color(0xFF5687AA),
    c: Color(0xFF3D4F7E),
    d: Color(0xFF1B2342),
  );

  /// Brand → tint fallback. Keys are lowercased & stripped.
  static const Map<String, NimbusVehicleTint> _brandTints = {
    'dacia': NimbusVehicleTint(
      a: Color(0xFFF4D9B8),
      b: Color(0xFFE89F7A),
      c: Color(0xFFA66B8C),
      d: Color(0xFF3E4868),
    ),
    'volkswagen': NimbusVehicleTint(
      a: Color(0xFF9CC4DA),
      b: Color(0xFF5687AA),
      c: Color(0xFF3D4F7E),
      d: Color(0xFF1B2342),
    ),
    'vw': NimbusVehicleTint(
      a: Color(0xFF9CC4DA),
      b: Color(0xFF5687AA),
      c: Color(0xFF3D4F7E),
      d: Color(0xFF1B2342),
    ),
    'bmw': NimbusVehicleTint(
      a: Color(0xFF5B6FA8),
      b: Color(0xFF3A2E5C),
      c: Color(0xFF1A1430),
      d: Color(0xFF0A0518),
    ),
    'audi': NimbusVehicleTint(
      a: Color(0xFFD9D9D9),
      b: Color(0xFF8A8E94),
      c: Color(0xFF3F4350),
      d: Color(0xFF15171D),
    ),
    'mercedes': NimbusVehicleTint(
      a: Color(0xFFE8E2D0),
      b: Color(0xFFA29B8A),
      c: Color(0xFF4D4A44),
      d: Color(0xFF1A1916),
    ),
    'mercedes-benz': NimbusVehicleTint(
      a: Color(0xFFE8E2D0),
      b: Color(0xFFA29B8A),
      c: Color(0xFF4D4A44),
      d: Color(0xFF1A1916),
    ),
    'ford': NimbusVehicleTint(
      a: Color(0xFF7FB3E0),
      b: Color(0xFF2E78C8),
      c: Color(0xFF1B3F6B),
      d: Color(0xFF0A1A2E),
    ),
    'opel': NimbusVehicleTint(
      a: Color(0xFFFFD66E),
      b: Color(0xFFE0791F),
      c: Color(0xFF6B2D14),
      d: Color(0xFF1A0F08),
    ),
    'renault': NimbusVehicleTint(
      a: Color(0xFFFFE066),
      b: Color(0xFFFFA42E),
      c: Color(0xFF6B3F14),
      d: Color(0xFF1A1208),
    ),
    'toyota': NimbusVehicleTint(
      a: Color(0xFFFF9F8A),
      b: Color(0xFFE03A2E),
      c: Color(0xFF6B1B14),
      d: Color(0xFF1A0908),
    ),
    'hyundai': NimbusVehicleTint(
      a: Color(0xFFA8D8E0),
      b: Color(0xFF4A8A9E),
      c: Color(0xFF22404D),
      d: Color(0xFF0A1418),
    ),
    'skoda': NimbusVehicleTint(
      a: Color(0xFFA8E0C8),
      b: Color(0xFF4A9E78),
      c: Color(0xFF1F4D3A),
      d: Color(0xFF0A1812),
    ),
  };

  /// Resolves the tint for a vehicle synchronously from cache or fallback.
  /// If the cache miss + photo exists, kick off [warmUp] separately.
  NimbusVehicleTint tintFor(Vehicle vehicle) {
    final cached = _cache[vehicle.id];
    if (cached != null) return cached;
    return _brandFallback(vehicle.brand);
  }

  NimbusVehicleTint _brandFallback(String brand) {
    final key = brand.trim().toLowerCase();
    return _brandTints[key] ?? _neutral;
  }

  /// Extracts a 4-stop palette from the vehicle's photo and stores it.
  /// Safe to call multiple times — no-ops if cached or photo missing.
  Future<NimbusVehicleTint?> warmUp(Vehicle vehicle) async {
    if (_cache.containsKey(vehicle.id)) return _cache[vehicle.id];
    final path = vehicle.photoPath;
    if (path == null || path.isEmpty) return null;
    final file = File(path);
    if (!await file.exists()) return null;

    try {
      final palette = await PaletteGenerator.fromImageProvider(
        FileImage(file),
        size: const Size(120, 120),
        maximumColorCount: 12,
      );
      final tint = _tintFromPalette(palette) ?? _brandFallback(vehicle.brand);
      _cache[vehicle.id] = tint;
      return tint;
    } catch (_) {
      return null;
    }
  }

  /// Picks 4 stops out of the generated palette, ordered light→dark.
  /// Falls back to brand if the photo doesn't yield enough usable colors.
  NimbusVehicleTint? _tintFromPalette(PaletteGenerator p) {
    final pool = <Color>{};
    void addNonNull(PaletteColor? c) {
      if (c != null) pool.add(c.color);
    }

    addNonNull(p.lightVibrantColor);
    addNonNull(p.vibrantColor);
    addNonNull(p.mutedColor);
    addNonNull(p.darkMutedColor);
    addNonNull(p.darkVibrantColor);
    addNonNull(p.lightMutedColor);
    pool.addAll(p.colors);

    if (pool.length < 3) return null;

    final sorted = pool.toList()
      ..sort((x, y) =>
          HSLColor.fromColor(y).lightness.compareTo(HSLColor.fromColor(x).lightness));

    Color pick(int idx) => sorted[idx.clamp(0, sorted.length - 1)];
    final a = pick(0);
    final b = pick(sorted.length ~/ 3);
    final c = pick((sorted.length * 2) ~/ 3);
    // The deepest stop is darkened further so the mesh feels grounded.
    final dRaw = pick(sorted.length - 1);
    final dHsl = HSLColor.fromColor(dRaw);
    final d = dHsl.withLightness((dHsl.lightness * 0.4).clamp(0.04, 0.14)).toColor();

    return NimbusVehicleTint(a: a, b: b, c: c, d: d);
  }

  void invalidate(String vehicleId) => _cache.remove(vehicleId);
}
