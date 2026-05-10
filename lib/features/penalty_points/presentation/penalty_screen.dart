import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/nimbus_screen.dart';
import '../../../core/theme/nimbus_tokens.dart';
import '../../../core/theme/nimbus_widgets.dart';
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
    return NimbusScreen(
      appBar: AppBar(title: const Text('Puncte permis')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Adaugă'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          _BigPointsCard(stats: stats),
          const SizedBox(height: 12),
          const _DisclaimerCard(),
          const SizedBox(height: 20),
          Text('Istoric',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (all.isEmpty)
            GlassCard.heavy(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.celebration_rounded,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Niciun punct înregistrat. Bună treabă!',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            )
          else
            for (final p in all) ...[
              _PenaltyTile(entry: p),
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
        child: const _PenaltyForm(),
      ),
    );
  }
}

class _BigPointsCard extends StatelessWidget {
  const _BigPointsCard({required this.stats});
  final PenaltyStats stats;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<NimbusTokens>()!;
    final color = t.riskColor(points: stats.activePoints);
    final tier = t.riskTier(points: stats.activePoints);
    final progress =
        (stats.activePoints / AppConstants.penaltyMaxBeforeSuspension)
            .clamp(0.0, 1.0);

    return GlassCard.heavy(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Eyebrow('Puncte active', color: color),
              RiskPill(tier: tier, label: tier.labelRo),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${stats.activePoints}',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: color,
                    ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '/ ${AppConstants.penaltyMaxBeforeSuspension}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              valueColor: AlwaysStoppedAnimation(color),
              backgroundColor: Colors.white.withOpacity(0.10),
            ),
          ),
        ],
      ),
    );
  }
}

class _DisclaimerCard extends StatelessWidget {
  const _DisclaimerCard();
  @override
  Widget build(BuildContext context) {
    return GlassCard.light(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Datele sunt introduse manual. Aplicația NU se conectează la baza oficială IGPR.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PenaltyTile extends ConsumerWidget {
  const _PenaltyTile({required this.entry});
  final PenaltyEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).extension<NimbusTokens>()!;
    final active = entry.isActive;
    final accent = active ? t.risk.warn : Theme.of(context).colorScheme.outline;
    return GlassCard.heavy(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withOpacity(0.4), width: 1),
            ),
            alignment: Alignment.center,
            child: Text(
              '${entry.points}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.reason ?? 'Sancțiune',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  active
                      ? '${DateUtilsRo.short(entry.date)} · expiră ${DateUtilsRo.short(entry.expiresOn)}'
                      : 'Expirat ${DateUtilsRo.short(entry.expiresOn)}',
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
                ref.read(penaltyProvider.notifier).delete(entry.id),
          ),
        ],
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

  @override
  void dispose() {
    _reason.dispose();
    _fine.dispose();
    _location.dispose();
    super.dispose();
  }

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
    try {
      await ref.read(penaltyProvider.notifier).add(p);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare la salvare: $e')));
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sancțiune salvată')));
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
              Text('Adaugă puncte',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center),
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
                  decoration:
                      const InputDecoration(labelText: 'Data sancțiunii'),
                  child: Text(DateUtilsRo.short(_date)),
                ),
              ),
              const SizedBox(height: 12),
              Text('Număr puncte',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      )),
              const SizedBox(height: 6),
              // Presets uzuale conform Codului Rutier RO (2, 3, 4, 6).
              // Pentru valori diferite, slider-ul rămâne ca opțiune fallback.
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final n in const [2, 3, 4, 6])
                    ChoiceChip(
                      label: Text('$n puncte'),
                      selected: _points == n,
                      onSelected: (sel) {
                        if (sel) setState(() => _points = n);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text('Sau custom: $_points',
                        style: Theme.of(context).textTheme.bodyMedium),
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
                decoration:
                    const InputDecoration(labelText: 'Amendă (lei)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _location,
                decoration: const InputDecoration(labelText: 'Locație'),
              ),
              const SizedBox(height: 20),
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
