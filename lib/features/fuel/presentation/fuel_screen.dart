import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/date_utils.dart';
import '../../vehicle/presentation/vehicle_providers.dart';
import '../domain/fuel_entry.dart';
import 'fuel_providers.dart';

class FuelScreen extends ConsumerWidget {
  const FuelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedVehicleProvider);
    final all = ref.watch(fuelProvider);
    final forVehicle =
        selected == null ? <FuelEntry>[] : all.where((f) => f.vehicleId == selected.id).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Combustibil')),
      body: selected == null
          ? const Center(child: Text('Adaugă un vehicul'))
          : Column(
              children: [
                if (forVehicle.length >= 2)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      height: 180,
                      child: _ConsumptionChart(entries: forVehicle.reversed.toList()),
                    ),
                  ),
                Expanded(
                  child: forVehicle.isEmpty
                      ? const Center(child: Text('Nicio realimentare înregistrată'))
                      : ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: forVehicle.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 4),
                          itemBuilder: (_, i) {
                            final f = forVehicle[i];
                            return Card(
                              child: ListTile(
                                leading: const CircleAvatar(
                                    child: Icon(Icons.local_gas_station_rounded)),
                                title: Text(
                                    '${f.liters.toStringAsFixed(2)} L · ${f.totalCost.toStringAsFixed(2)} lei'),
                                subtitle: Text(
                                    '${DateUtilsRo.short(f.date)} · ${f.mileage} km · ${f.pricePerLiter.toStringAsFixed(2)} lei/L'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded),
                                  onPressed: () =>
                                      ref.read(fuelProvider.notifier).delete(f.id),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => Padding(
            padding:
                EdgeInsets.only(bottom: MediaQuery.of(_).viewInsets.bottom),
            child: const _FuelForm(),
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Realimentare'),
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
      return const Center(child: Text('Date insuficiente pentru grafic'));
    }
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
            color: Theme.of(context).colorScheme.primary,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
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

  void _recalc() {
    final l = double.tryParse(_liters.text);
    final p = double.tryParse(_ppl.text);
    if (l != null && p != null) {
      _total.text = (l * p).toStringAsFixed(2);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final selected = ref.read(selectedVehicleProvider);
    if (selected == null) return;
    final f = FuelEntry(
      id: const Uuid().v4(),
      vehicleId: selected.id,
      date: _date,
      liters: double.tryParse(_liters.text) ?? 0,
      pricePerLiter: double.tryParse(_ppl.text) ?? 0,
      totalCost: double.tryParse(_total.text) ?? 0,
      mileage: int.tryParse(_mileage.text) ?? selected.mileage,
      fullTank: _full,
      station: _station.text.trim().isEmpty ? null : _station.text.trim(),
    );
    await ref.read(fuelProvider.notifier).add(f);
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
            Text('Realimentare', style: Theme.of(context).textTheme.titleLarge),
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
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Litri'),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Obligatoriu' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _ppl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Lei / L'),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            TextFormField(
              controller: _total,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Total (lei)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _mileage,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Kilometraj curent'),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Obligatoriu' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _station,
              decoration: const InputDecoration(labelText: 'Benzinărie (opțional)'),
            ),
            SwitchListTile(
              value: _full,
              onChanged: (v) => setState(() => _full = v),
              title: const Text('Plin complet'),
              contentPadding: EdgeInsets.zero,
            ),
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
