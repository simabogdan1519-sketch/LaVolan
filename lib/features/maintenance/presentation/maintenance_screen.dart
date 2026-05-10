import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/nimbus_screen.dart';
import '../../../core/theme/nimbus_tokens.dart';
import '../../../core/theme/nimbus_widgets.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/require_vehicle.dart';
import '../../vehicle/presentation/vehicle_providers.dart';
import '../domain/maintenance_entry.dart';
import 'maintenance_providers.dart';

class MaintenanceScreen extends ConsumerWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(maintenanceProvider);
    return NimbusScreen(
      appBar: AppBar(title: const Text('Mentenanță')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Adaugă'),
      ),
      body: entries.isEmpty
          ? _Empty(onAdd: () => _openSheet(context))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _Tile(entry: entries[i]),
            ),
    );
  }

  void _openSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(_).viewInsets.bottom,
          left: 12,
          right: 12,
          top: 12,
        ),
        child: const _MaintenanceForm(),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onAdd});
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.primary.withOpacity(0.18),
                border:
                    Border.all(color: cs.primary.withOpacity(0.4), width: 1.5),
              ),
              child: Icon(Icons.build_rounded, size: 40, color: cs.primary),
            ),
            const SizedBox(height: 24),
            Text('Niciun service încă',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Înregistrează ulei, frâne, anvelope și revizii. Te alertăm când e timpul.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Adaugă serviciu'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends ConsumerWidget {
  const _Tile({required this.entry});
  final MaintenanceEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).extension<NimbusTokens>()!;
    return GlassCard.heavy(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: t.risk.safe.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_iconFor(entry.category), color: t.risk.safe),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.categoryLabelRo,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  '${DateUtilsRo.short(entry.date)} · ${entry.mileageAtService} km'
                  '${entry.cost != null ? " · ${entry.cost!.toStringAsFixed(0)} lei" : ""}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () =>
                ref.read(maintenanceProvider.notifier).delete(entry.id),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(MaintenanceCategory c) {
    switch (c) {
      case MaintenanceCategory.ulei:
        return Icons.oil_barrel_rounded;
      case MaintenanceCategory.placute:
        return Icons.do_not_step_rounded;
      case MaintenanceCategory.filtre:
        return Icons.filter_alt_rounded;
      case MaintenanceCategory.anvelope:
        return Icons.tire_repair_rounded;
      case MaintenanceCategory.baterie:
        return Icons.battery_charging_full_rounded;
      case MaintenanceCategory.revizie:
        return Icons.checklist_rounded;
      case MaintenanceCategory.altele:
        return Icons.build_rounded;
    }
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

  @override
  void dispose() {
    _mileage.dispose();
    _cost.dispose();
    _provider.dispose();
    _notes.dispose();
    _nextKm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final selected = await requireVehicle(context, ref);
    if (selected == null) return;
    final mileageInt = int.tryParse(_mileage.text.trim()) ?? selected.mileage;
    final m = MaintenanceEntry(
      id: const Uuid().v4(),
      vehicleId: selected.id,
      category: _cat,
      date: _date,
      mileageAtService: mileageInt,
      cost: double.tryParse(_cost.text.trim()),
      serviceProvider:
          _provider.text.trim().isEmpty ? null : _provider.text.trim(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      nextDueDate: _nextDate,
      nextDueMileage: int.tryParse(_nextKm.text.trim()),
    );
    try {
      await ref.read(maintenanceProvider.notifier).add(m);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare la salvare: $e')));
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Salvat')));
    Navigator.pop(context);
  }

  /// Apelat la schimbarea categoriei — sugerează km/dată următoare bazat
  /// pe intervalul tipic. Utilizatorul poate suprascrie ulterior.
  void _applyCategoryDefaults() {
    final mileageNow = int.tryParse(_mileage.text.trim());
    final km = _cat.suggestedKmInterval;
    final days = _cat.suggestedDayInterval;
    if (km != null && mileageNow != null) {
      _nextKm.text = (mileageNow + km).toString();
    } else if (km != null) {
      _nextKm.text = '';
    }
    if (days != null) {
      _nextDate = _date.add(Duration(days: days));
    } else {
      _nextDate = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard.ultra(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 4),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .outline
                        .withOpacity(0.6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Înregistrare mentenanță',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              DropdownButtonFormField<MaintenanceCategory>(
                value: _cat,
                decoration: const InputDecoration(labelText: 'Categorie'),
                items: MaintenanceCategory.values
                    .map((c) => DropdownMenuItem(
                        value: c, child: Text(_categoryLabel(c))))
                    .toList(),
                onChanged: (v) => setState(() {
                  _cat = v ?? _cat;
                  _applyCategoryDefaults();
                }),
              ),
              const SizedBox(height: 12),
              _date_('Data', _date, (d) => setState(() => _date = d)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _mileage,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Kilometraj la service'),
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
                decoration:
                    const InputDecoration(labelText: 'Service (opțional)'),
              ),
              const SizedBox(height: 12),
              _date_('Următoare data (opțional)',
                  _nextDate ?? DateTime.now().add(const Duration(days: 180)),
                  (d) => setState(() => _nextDate = d),
                  hint: _nextDate == null ? '—' : null),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nextKm,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Următoare la km (opțional)'),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_rounded),
                label: const Text('Salvează'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _date_(String label, DateTime value, ValueChanged<DateTime> on,
      {String? hint}) {
    return InkWell(
      onTap: () async {
        final p = await showDatePicker(
            context: context,
            initialDate: value,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
            locale: const Locale('ro', 'RO'));
        if (p != null) on(p);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(hint ?? DateUtilsRo.short(value)),
      ),
    );
  }

  String _categoryLabel(MaintenanceCategory c) {
    return MaintenanceEntry(
            id: '',
            vehicleId: '',
            category: c,
            date: DateTime.now(),
            mileageAtService: 0)
        .categoryLabelRo;
  }
}
