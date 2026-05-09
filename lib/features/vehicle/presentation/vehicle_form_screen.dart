import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

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
      }
    }
  }

  @override
  void dispose() {
    for (final c in [_brand, _model, _year, _plate, _mileage, _vin, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(vehiclesProvider.notifier);
    if (_existing != null) {
      _existing!
        ..brand = _brand.text.trim()
        ..model = _model.text.trim()
        ..year = int.tryParse(_year.text.trim()) ?? _existing!.year
        ..licensePlate = _plate.text.trim().toUpperCase()
        ..mileage = int.tryParse(_mileage.text.trim()) ?? 0
        ..fuelType = _fuel
        ..vin = _vin.text.trim().isEmpty ? null : _vin.text.trim()
        ..notes = _notes.text.trim().isEmpty ? null : _notes.text.trim();
      await notifier.update(_existing!);
    } else {
      final v = Vehicle(
        id: const Uuid().v4(),
        brand: _brand.text.trim(),
        model: _model.text.trim(),
        year: int.tryParse(_year.text.trim()) ?? DateTime.now().year,
        licensePlate: _plate.text.trim().toUpperCase(),
        fuelType: _fuel,
        mileage: int.tryParse(_mileage.text.trim()) ?? 0,
        vin: _vin.text.trim().isEmpty ? null : _vin.text.trim(),
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      );
      await notifier.add(v);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_existing == null ? 'Adaugă vehicul' : 'Editează vehicul'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field(_brand, 'Marcă', required: true),
            _field(_model, 'Model', required: true),
            Row(
              children: [
                Expanded(
                    child: _field(_year, 'An',
                        keyboard: TextInputType.number, required: true)),
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

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
