import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/nimbus_screen.dart';
import '../../../core/theme/nimbus_tokens.dart';
import '../../../core/theme/nimbus_widgets.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/require_vehicle.dart';
import '../../vehicle/presentation/vehicle_providers.dart';
import '../domain/fuel_entry.dart';
import 'fuel_providers.dart';

class FuelScreen extends ConsumerWidget {
  const FuelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedVehicleProvider);
    final all = ref.watch(fuelProvider);
    final forVehicle = selected == null
        ? <FuelEntry>[]
        : all.where((f) => f.vehicleId == selected.id).toList();

    return NimbusScreen(
      appBar: AppBar(title: const Text('Combustibil')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Realimentare'),
      ),
      body: selected == null
          ? const _NoVehicle()
          : forVehicle.isEmpty
              ? _Empty(onAdd: () => _openSheet(context))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  children: [
                    if (forVehicle.length >= 2)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: GlassCard.heavy(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Eyebrow('Consum mediu (L/100km)'),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 160,
                                child: _ConsumptionChart(
                                    entries: forVehicle.reversed.toList()),
                              ),
                            ],
                          ),
                        ),
                      ),
                    for (final f in forVehicle) ...[
                      _Tile(entry: f),
                      const SizedBox(height: 10),
                    ],
                  ],
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
        child: const _FuelForm(),
      ),
    );
  }
}

class _NoVehicle extends StatelessWidget {
  const _NoVehicle();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_car_outlined,
                size: 64, color: cs.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('Adaugă întâi un vehicul',
                style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
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
              child: Icon(Icons.local_gas_station_rounded,
                  size: 40, color: cs.primary),
            ),
            const SizedBox(height: 24),
            Text('Nicio realimentare',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Adaugă realimentări și calculăm consum, cost/km și total.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Prima realimentare'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends ConsumerWidget {
  const _Tile({required this.entry});
  final FuelEntry entry;

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
            child: Icon(Icons.local_gas_station_rounded, color: t.risk.safe),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.liters.toStringAsFixed(2)} L · ${entry.totalCost.toStringAsFixed(2)} lei',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  '${DateUtilsRo.short(entry.date)} · ${entry.mileage} km · ${entry.pricePerLiter.toStringAsFixed(2)} lei/L',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () => ref.read(fuelProvider.notifier).delete(entry.id),
          ),
        ],
      ),
    );
  }
}

class _ConsumptionChart extends StatelessWidget {
  const _ConsumptionChart({required this.entries});
  final List<FuelEntry> entries;

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    for (var i = 1; i < entries.length; i++) {
      final prev = entries[i - 1];
      final cur = entries[i];
      final km = cur.mileage - prev.mileage;
      if (km > 0 && cur.fullTank) {
        final cons = (cur.liters / km) * 100;
        spots.add(FlSpot(i.toDouble(), cons));
      }
    }
    if (spots.isEmpty) {
      return Center(
        child: Text(
          'Date insuficiente pentru grafic',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
    }
    final cs = Theme.of(context).colorScheme;
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 3,
            color: cs.primary,
            dotData: FlDotData(
              show: true,
              getDotPainter: (s, p, b, idx) => FlDotCirclePainter(
                radius: 3,
                color: cs.primary,
                strokeWidth: 0,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: cs.primary.withOpacity(0.15),
            ),
          ),
        ],
      ),
    );
  }
}

class _FuelForm extends ConsumerStatefulWidget {
  const _FuelForm();
  @override
  ConsumerState<_FuelForm> createState() => _FuelFormState();
}

class _FuelFormState extends ConsumerState<_FuelForm> {
  final _formKey = GlobalKey<FormState>();
  DateTime _date = DateTime.now();
  final _liters = TextEditingController();
  final _ppl = TextEditingController();
  final _total = TextEditingController();
  final _mileage = TextEditingController();
  final _station = TextEditingController();
  bool _full = true;

  @override
  void initState() {
    super.initState();
    _liters.addListener(_recalc);
    _ppl.addListener(_recalc);
  }

  @override
  void dispose() {
    _liters.dispose();
    _ppl.dispose();
    _total.dispose();
    _mileage.dispose();
    _station.dispose();
    super.dispose();
  }

  void _recalc() {
    final l = double.tryParse(_liters.text);
    final p = double.tryParse(_ppl.text);
    if (l != null && p != null) {
      _total.text = (l * p).toStringAsFixed(2);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Completează câmpurile obligatorii')));
      return;
    }
    final selected = await requireVehicle(context, ref);
    if (selected == null) return;
    final mileage = int.tryParse(_mileage.text.trim());
    if (mileage == null || mileage <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Kilometrajul curent este obligatoriu')));
      return;
    }
    // Realism check — dacă diferența e enormă, întreabă utilizatorul
    final diff = mileage - selected.mileage;
    if (diff > 5000) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Verifică kilometrajul'),
          content: Text(
              'Ai introdus $mileage km, dar mașina avea ${selected.mileage} km. '
              'Diferența e ${diff} km — sigur?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(_, false),
              child: const Text('Corectez'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(_, true),
              child: const Text('Da, corect'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    final f = FuelEntry(
      id: const Uuid().v4(),
      vehicleId: selected.id,
      date: _date,
      liters: double.tryParse(_liters.text) ?? 0,
      pricePerLiter: double.tryParse(_ppl.text) ?? 0,
      totalCost: double.tryParse(_total.text) ?? 0,
      mileage: mileage,
      fullTank: _full,
      station: _station.text.trim().isEmpty ? null : _station.text.trim(),
    );
    try {
      await ref.read(fuelProvider.notifier).add(f);
      if (mileage > selected.mileage) {
        selected.mileage = mileage;
        await ref.read(vehiclesProvider.notifier).update(selected);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare la salvare: $e')));
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Realimentare salvată')));
    Navigator.pop(context);
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
              Text('Realimentare',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final p = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
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
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _liters,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: const InputDecoration(labelText: 'Litri'),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Obligatoriu' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _ppl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: const InputDecoration(labelText: 'Lei / L'),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              TextFormField(
                controller: _total,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Total (lei)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _mileage,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Kilometraj curent *',
                  helperText: 'Obligatoriu pentru calcul consum',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Obligatoriu';
                  final n = int.tryParse(v.trim());
                  if (n == null || n <= 0) return 'Kilometraj invalid';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _station,
                decoration: const InputDecoration(
                    labelText: 'Benzinărie (opțional)'),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                value: _full,
                onChanged: (v) => setState(() => _full = v),
                title: const Text('Plin complet'),
                subtitle: Text(
                  'Bifează doar dacă ai făcut plinul la maximum — necesar pentru calcul consum (L/100 km).',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 12),
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
}
