import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_utils.dart';
import '../data/penalty_repository.dart';
import '../domain/penalty_entry.dart';
import 'penalty_providers.dart';

class PenaltyScreen extends ConsumerWidget {
  const PenaltyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(penaltyStatsProvider);
    final all = ref.watch(penaltyProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Puncte permis')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _BigPointsCard(stats: stats),
          const SizedBox(height: 8),
          _DisclaimerCard(),
          const SizedBox(height: 16),
          Text('Istoric',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (all.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Niciun punct înregistrat. Bună treabă! 🎉'),
              ),
            ),
          for (final p in all) _PenaltyTile(entry: p),
          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => Padding(
            padding:
                EdgeInsets.only(bottom: MediaQuery.of(_).viewInsets.bottom),
            child: const _PenaltyForm(),
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Adaugă'),
      ),
    );
  }
}

class _BigPointsCard extends StatelessWidget {
  const _BigPointsCard({required this.stats});
  final PenaltyStats stats;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (stats.risk) {
      case PenaltyRiskLevel.safe:
        color = Colors.green;
        label = 'Sigur';
        break;
      case PenaltyRiskLevel.caution:
        color = Colors.orange;
        label = 'Atenție';
        break;
      case PenaltyRiskLevel.warning:
        color = Colors.deepOrange;
        label = 'Risc ridicat';
        break;
      case PenaltyRiskLevel.critical:
        color = Colors.red;
        label = 'Risc suspendare';
        break;
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Puncte active',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${stats.activePoints}',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.w800, color: color),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text('/ ${AppConstants.penaltyMaxBeforeSuspension}',
                      style: Theme.of(context).textTheme.titleLarge),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(label,
                      style: TextStyle(
                          color: color, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (stats.activePoints / AppConstants.penaltyMaxBeforeSuspension)
                    .clamp(0.0, 1.0),
                minHeight: 8,
                color: color,
                backgroundColor: color.withOpacity(0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DisclaimerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Datele sunt introduse manual. Aplicația NU se conectează la baza oficială IGPR.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PenaltyTile extends ConsumerWidget {
  const _PenaltyTile({required this.entry});
  final PenaltyEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final active = entry.isActive;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: (active ? scheme.error : scheme.outline)
              .withOpacity(0.15),
          child: Text('${entry.points}',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: active ? scheme.error : scheme.outline)),
        ),
        title: Text(entry.reason ?? 'Sancțiune',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          active
              ? '${DateUtilsRo.short(entry.date)} · expiră ${DateUtilsRo.short(entry.expiresOn)}'
              : 'Expirat ${DateUtilsRo.short(entry.expiresOn)}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded),
          onPressed: () => ref.read(penaltyProvider.notifier).delete(entry.id),
        ),
      ),
    );
  }
}

class _PenaltyForm extends ConsumerStatefulWidget {
  const _PenaltyForm();
  @override
  ConsumerState<_PenaltyForm> createState() => _PenaltyFormState();
}

class _PenaltyFormState extends ConsumerState<_PenaltyForm> {
  final _formKey = GlobalKey<FormState>();
  DateTime _date = DateTime.now();
  int _points = 2;
  final _reason = TextEditingController();
  final _fine = TextEditingController();
  final _location = TextEditingController();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final p = PenaltyEntry(
      id: const Uuid().v4(),
      date: _date,
      points: _points,
      reason: _reason.text.trim().isEmpty ? null : _reason.text.trim(),
      fineAmount: double.tryParse(_fine.text.trim()),
      location:
          _location.text.trim().isEmpty ? null : _location.text.trim(),
    );
    await ref.read(penaltyProvider.notifier).add(p);
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
            Text('Adaugă puncte',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final p = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2010),
                  lastDate: DateTime.now(),
                  locale: const Locale('ro', 'RO'),
                );
                if (p != null) setState(() => _date = p);
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Data sancțiunii'),
                child: Text(DateUtilsRo.short(_date)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text('Număr puncte: $_points',
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                IconButton(
                  onPressed: _points > 1
                      ? () => setState(() => _points--)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                IconButton(
                  onPressed: _points < 9
                      ? () => setState(() => _points++)
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _reason,
              decoration:
                  const InputDecoration(labelText: 'Motiv (opțional)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _fine,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amendă (lei)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _location,
              decoration: const InputDecoration(labelText: 'Locație'),
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
