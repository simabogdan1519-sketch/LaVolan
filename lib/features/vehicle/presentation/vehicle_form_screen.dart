import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/nimbus_screen.dart';
import '../data/vehicle_photo_service.dart';
import '../domain/vehicle.dart';
import 'vehicle_providers.dart';

class VehicleFormScreen extends ConsumerStatefulWidget {
  const VehicleFormScreen({super.key, this.vehicleId});
  final String? vehicleId;

  @override
  ConsumerState<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends ConsumerState<VehicleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _brand = TextEditingController();
  final _model = TextEditingController();
  final _year = TextEditingController(text: DateTime.now().year.toString());
  final _plate = TextEditingController();
  final _mileage = TextEditingController(text: '0');
  final _vin = TextEditingController();
  final _notes = TextEditingController();
  FuelType _fuel = FuelType.benzina;

  Vehicle? _existing;
  String? _photoPath;
  String? _originalPhotoPath;
  late String _photoVehicleId;

  @override
  void initState() {
    super.initState();
    final id = widget.vehicleId;
    if (id != null) {
      final list = ref.read(vehiclesProvider);
      _existing = list.where((v) => v.id == id).cast<Vehicle?>().firstOrNull;
      final v = _existing;
      if (v != null) {
        _brand.text = v.brand;
        _model.text = v.model;
        _year.text = v.year.toString();
        _plate.text = v.licensePlate;
        _mileage.text = v.mileage.toString();
        _vin.text = v.vin ?? '';
        _notes.text = v.notes ?? '';
        _fuel = v.fuelType;
        _photoPath = v.photoPath;
        _originalPhotoPath = v.photoPath;
        _photoVehicleId = v.id;
        return;
      }
    }
    _photoVehicleId = const Uuid().v4();
  }

  @override
  void dispose() {
    for (final c in [_brand, _model, _year, _plate, _mileage, _vin, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final newPath = await VehiclePhotoService.instance.pickAndStore(
      vehicleId: _photoVehicleId,
      source: source,
    );
    if (newPath == null) return;
    final replacing = _photoPath;
    if (replacing != null && replacing != _originalPhotoPath) {
      await VehiclePhotoService.instance.delete(replacing);
    }
    if (!mounted) return;
    setState(() => _photoPath = newPath);
  }

  Future<void> _removePhoto() async {
    final current = _photoPath;
    if (current != null && current != _originalPhotoPath) {
      await VehiclePhotoService.instance.delete(current);
    }
    if (!mounted) return;
    setState(() => _photoPath = null);
  }

  void _showPhotoSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('Fă o poză'),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Alege din galerie'),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.gallery);
              },
            ),
            if (_photoPath != null)
              ListTile(
                leading: Icon(Icons.delete_rounded,
                    color: Theme.of(context).colorScheme.error),
                title: Text('Șterge poza',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error)),
                onTap: () {
                  Navigator.pop(ctx);
                  _removePhoto();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Verifică câmpurile obligatorii')));
      return;
    }
    final notifier = ref.read(vehiclesProvider.notifier);

    final shouldDeleteOriginalAfterSave =
        _originalPhotoPath != null && _originalPhotoPath != _photoPath;

    try {
      if (_existing != null) {
        _existing!
          ..brand = _brand.text.trim()
          ..model = _model.text.trim()
          ..year = int.tryParse(_year.text.trim()) ?? _existing!.year
          ..licensePlate = _plate.text.trim().toUpperCase()
          ..mileage = int.tryParse(_mileage.text.trim()) ?? 0
          ..fuelType = _fuel
          ..vin = _vin.text.trim().isEmpty ? null : _vin.text.trim()
          ..notes = _notes.text.trim().isEmpty ? null : _notes.text.trim()
          ..photoPath = _photoPath;
        await notifier.update(_existing!);
      } else {
        final v = Vehicle(
          id: _photoVehicleId,
          brand: _brand.text.trim(),
          model: _model.text.trim(),
          year: int.tryParse(_year.text.trim()) ?? DateTime.now().year,
          licensePlate: _plate.text.trim().toUpperCase(),
          fuelType: _fuel,
          mileage: int.tryParse(_mileage.text.trim()) ?? 0,
          vin: _vin.text.trim().isEmpty ? null : _vin.text.trim(),
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
          photoPath: _photoPath,
        );
        await notifier.add(v);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare la salvare: $e')));
      return;
    }

    if (shouldDeleteOriginalAfterSave) {
      await VehiclePhotoService.instance.delete(_originalPhotoPath);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_existing == null
            ? 'Vehicul adăugat'
            : 'Modificări salvate')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return NimbusScreen(
      appBar: AppBar(
        title: Text(_existing == null ? 'Adaugă vehicul' : 'Editează vehicul'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
                child: _PhotoPicker(
              path: _photoPath,
              onTap: _showPhotoSheet,
            )),
            const SizedBox(height: 24),
            _field(_brand, 'Marcă', required: true),
            _field(_model, 'Model', required: true),
            Row(
              children: [
                Expanded(
                    child: _yearField()),
                const SizedBox(width: 12),
                Expanded(
                    child: _field(_mileage, 'Kilometraj',
                        keyboard: TextInputType.number, required: true)),
              ],
            ),
            _field(_plate, 'Număr înmatriculare', required: true),
            const SizedBox(height: 8),
            DropdownButtonFormField<FuelType>(
              value: _fuel,
              decoration: const InputDecoration(labelText: 'Combustibil'),
              items: FuelType.values
                  .map((f) => DropdownMenuItem(
                        value: f,
                        child: Text(_fuelLabel(f)),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _fuel = v ?? FuelType.benzina),
            ),
            const SizedBox(height: 12),
            _field(_vin, 'VIN (opțional)'),
            _field(_notes, 'Note (opțional)', maxLines: 3),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_rounded),
              label: Text(_existing == null ? 'Adaugă' : 'Salvează'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label, {
    bool required = false,
    TextInputType? keyboard,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: c,
        keyboardType: keyboard,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'Obligatoriu' : null
            : null,
      ),
    );
  }

  Widget _yearField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: _year,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'An'),
        validator: (v) {
          final s = v?.trim() ?? '';
          if (s.isEmpty) return 'Obligatoriu';
          final n = int.tryParse(s);
          if (n == null) return 'Doar cifre';
          final maxYear = DateTime.now().year + 1;
          if (n < 1900 || n > maxYear) {
            return 'Între 1900 și $maxYear';
          }
          return null;
        },
      ),
    );
  }

  String _fuelLabel(FuelType f) {
    switch (f) {
      case FuelType.benzina:
        return 'Benzină';
      case FuelType.motorina:
        return 'Motorină';
      case FuelType.hibrid:
        return 'Hibrid';
      case FuelType.electric:
        return 'Electric';
      case FuelType.gpl:
        return 'GPL';
    }
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({required this.path, required this.onTap});
  final String? path;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final has = path != null && path!.isNotEmpty;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Align(
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              width: 132,
              height: 132,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.primary.withOpacity(0.10),
                border: Border.all(
                    color: cs.primary.withOpacity(0.35), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: cs.shadow.withOpacity(0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: has
                    ? Image.file(
                        File(path!),
                        fit: BoxFit.cover,
                        width: 132,
                        height: 132,
                        errorBuilder: (_, __, ___) => Icon(
                            Icons.directions_car_rounded,
                            size: 56,
                            color: cs.onSurfaceVariant),
                      )
                    : Icon(Icons.add_a_photo_rounded,
                        size: 44, color: cs.primary),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: onTap,
          icon: Icon(has ? Icons.edit_rounded : Icons.add_a_photo_rounded),
          label: Text(has ? 'Schimbă poza' : 'Adaugă poză'),
        ),
      ],
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
