import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/date_utils.dart';
import '../../vehicle/presentation/vehicle_providers.dart';
import '../domain/maintenance_entry.dart';
import 'maintenance_providers.dart';

class MaintenanceScreen extends ConsumerWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(maintenanceProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Mentenanță')),
      body: entries.isEmpty
          ? const Center(child: Text('Nicio intrare de mentenanță'))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (_, i) {
                final m = entries[i];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.build_rounded)),
                    title: Text(m.categoryLabelRo,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      '${DateUtilsRo.short(m.date)} · ${m.mileageAtService} km'
                      '${m.cost != null ? " · ${m.cost!.toStringAsFixed(0)} lei" : ""}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: () =>
                          ref.read(maintenanceProvider.notifier).delete(m.id),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => Padding(
            padding:
                EdgeInsets.only(bottom: MediaQuery.of(_).viewInsets.bottom),
            child: const _MaintenanceForm(),
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Adaugă'),
      ),
    );
  }
}

class _MaintenanceForm extends ConsumerStatefulWidget {
  const _MaintenanceForm();
  @override
  ConsumerState<_MaintenanceForm> createState() => _MaintenanceFormState();
}

class _MaintenanceFormState extends ConsumerState<_MaintenanceForm> {
  final _formKey = GlobalKey<FormState>();
  MaintenanceCategory _cat = MaintenanceCategory.ulei;
  DateTime _date = DateTime.now();
  final _mileage = TextEditingController();
  final _cost = TextEditingController();
  final _provider = TextEditingController();
  final _notes = TextEditingController();
  DateTime? _nextDate;
  final _nextKm = TextEditingController();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final selected = ref.read(selectedVehicleProvider);
    if (selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Adaugă întâi un vehicul')));
      return;
    }
    final m = MaintenanceEntry(
      id: const Uuid().v4(),
      vehicleId: selected.id,
      category: _cat,
      date: _date,
      mileageAtService: int.tryParse(_mileage.text.trim()) ?? selected.mileage,
      cost: double.tryParse(_cost.text.trim()),
      serviceProvider:
          _provider.text.trim().isEmpty ? null : _provider.text.trim(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      nextDueDate: _nextDate,
      nextDueMileage: int.tryParse(_nextKm.text.trim()),
    );
    await ref.read(maintenanceProvider.notifier).add(m);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Înregistrare mentenanță',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            DropdownButtonFormField<MaintenanceCategory>(
              value: _cat,
              decoration: const InputDecoration(labelText: 'Categorie'),
              items: MaintenanceCategory.values
                  .map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(MaintenanceEntry(
                              id: '',
                              vehicleId: '',
                              category: c,
                              date: DateTime.now(),
                              mileageAtService: 0)
                          .categoryLabelRo)))
                  .toList(),
              onChanged: (v) => setState(() => _cat = v ?? _cat),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final p = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                  locale: const Locale('ro', 'RO'),
                );
                if (p != null) setState(() => _date = p);
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Data'),
                child: Text(DateUtilsRo.short(_date)),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _mileage,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Kilometraj la service'),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Obligatoriu' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cost,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Cost (lei)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _provider,
              decoration: const InputDecoration(labelText: 'Service (opțional)'),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final p = await showDatePicker(
                  context: context,
                  initialDate: _nextDate ?? DateTime.now().add(const Duration(days: 180)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                  locale: const Locale('ro', 'RO'),
                );
                if (p != null) setState(() => _nextDate = p);
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Următoare data (opțional)'),
                child: Text(_nextDate == null ? '—' : DateUtilsRo.short(_nextDate!)),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nextKm,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Următoare la km (opțional)'),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_rounded),
              label: const Text('Salvează'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
