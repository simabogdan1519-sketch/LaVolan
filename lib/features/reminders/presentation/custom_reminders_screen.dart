import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/nimbus_screen.dart';
import '../../../core/theme/nimbus_widgets.dart';
import '../../../core/utils/date_utils.dart';
import '../domain/custom_reminder.dart';
import 'custom_reminder_providers.dart';

class CustomRemindersScreen extends ConsumerWidget {
  const CustomRemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(customRemindersProvider);
    return NimbusScreen(
      appBar: AppBar(title: const Text('Remindere')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _open(context),
        icon: const Icon(Icons.add),
        label: const Text('Adaugă'),
      ),
      body: list.isEmpty
          ? _Empty(onAdd: () => _open(context))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                Text('Sezoniere — sugestii rapide',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                _PresetGrid(),
                const SizedBox(height: 20),
                Text('Reminderele tale',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final r in list) ...[
                  _Tile(reminder: r),
                  const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }

  void _open(BuildContext context, {CustomReminder? prefill}) {
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
        child: _ReminderForm(prefill: prefill),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.primary.withOpacity(0.18),
              border: Border.all(
                  color: cs.primary.withOpacity(0.4), width: 1.5),
            ),
            child: Icon(Icons.alarm_rounded, size: 40, color: cs.primary),
          ),
          const SizedBox(height: 24),
          Text('Niciun reminder',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            'Setează remindere recurente pentru anvelope, antigel, sau orice altceva.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          Text('Sugestii rapide',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _PresetGrid(),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Reminder personalizat'),
          ),
        ],
      ),
    );
  }
}

class _PresetGrid extends ConsumerWidget {
  static final _presets = <_Preset>[
    _Preset(
      title: 'Anvelope iarnă',
      body: 'Schimbă pe anvelope de iarnă',
      month: 11,
      day: 1,
      interval: ReminderInterval.yearly,
      icon: Icons.ac_unit_rounded,
    ),
    _Preset(
      title: 'Anvelope vară',
      body: 'Schimbă pe anvelope de vară',
      month: 4,
      day: 1,
      interval: ReminderInterval.yearly,
      icon: Icons.wb_sunny_rounded,
    ),
    _Preset(
      title: 'Verificare baterie iarna',
      body: 'Verifică starea bateriei înainte de îngheț',
      month: 10,
      day: 15,
      interval: ReminderInterval.yearly,
      icon: Icons.battery_alert_rounded,
    ),
    _Preset(
      title: 'Antigel & lichide',
      body: 'Verifică antigel, lichid frână, ulei',
      month: 10,
      day: 1,
      interval: ReminderInterval.yearly,
      icon: Icons.invert_colors_rounded,
    ),
    _Preset(
      title: 'Spălare săptămânală',
      body: 'Mașina merită o spălare',
      interval: ReminderInterval.weekly,
      icon: Icons.local_car_wash_rounded,
    ),
    _Preset(
      title: 'Verificare presiune',
      body: 'Presiune în anvelope',
      interval: ReminderInterval.monthly,
      icon: Icons.compress_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.6,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        for (final p in _presets)
          GlassCard.light(
            onTap: () => _addPreset(context, ref, p),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(p.icon,
                    size: 22, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(p.title,
                      style: Theme.of(context).textTheme.labelLarge,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _addPreset(
      BuildContext context, WidgetRef ref, _Preset p) async {
    final now = DateTime.now();
    final start = (p.month != null && p.day != null)
        ? DateTime(
            DateTime(now.year, p.month!, p.day!).isBefore(now)
                ? now.year + 1
                : now.year,
            p.month!,
            p.day!)
        : now;
    final reminder = CustomReminder(
      id: const Uuid().v4(),
      title: p.title,
      body: p.body,
      startDate: start,
      hour: 9,
      minute: 0,
      interval: p.interval,
      occurrencesCount: p.interval == ReminderInterval.yearly ? 5 : null,
    );
    await ref.read(customRemindersProvider.notifier).add(reminder);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reminder "${p.title}" activat')),
      );
    }
  }
}

class _Preset {
  _Preset({
    required this.title,
    required this.body,
    this.month,
    this.day,
    required this.interval,
    required this.icon,
  });
  final String title;
  final String body;
  final int? month;
  final int? day;
  final ReminderInterval interval;
  final IconData icon;
}

class _Tile extends ConsumerWidget {
  const _Tile({required this.reminder});
  final CustomReminder reminder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final next = reminder
        .upcomingOccurrences(count: 1)
        .firstOrNull;
    return GlassCard.heavy(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.alarm_rounded, color: cs.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reminder.title,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  next == null
                      ? 'Nicio ocurență viitoare'
                      : '${reminder.interval.labelRo} · următor: ${DateUtilsRo.short(next)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          Switch(
            value: reminder.enabled,
            onChanged: (v) => ref
                .read(customRemindersProvider.notifier)
                .toggle(reminder.id, v),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () => ref
                .read(customRemindersProvider.notifier)
                .delete(reminder.id),
          ),
        ],
      ),
    );
  }
}

class _ReminderForm extends ConsumerStatefulWidget {
  const _ReminderForm({this.prefill});
  final CustomReminder? prefill;
  @override
  ConsumerState<_ReminderForm> createState() => _ReminderFormState();
}

class _ReminderFormState extends ConsumerState<_ReminderForm> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  DateTime _start = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  ReminderInterval _interval = ReminderInterval.monthly;
  int _customDays = 30;
  int? _occurrences;

  @override
  void initState() {
    super.initState();
    final p = widget.prefill;
    if (p != null) {
      _title.text = p.title;
      _body.text = p.body ?? '';
      _start = p.startDate;
      _time = TimeOfDay(hour: p.hour, minute: p.minute);
      _interval = p.interval;
      _customDays = p.customIntervalDays;
      _occurrences = p.occurrencesCount;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final r = CustomReminder(
      id: widget.prefill?.id ?? const Uuid().v4(),
      title: _title.text.trim(),
      body: _body.text.trim().isEmpty ? null : _body.text.trim(),
      startDate: _start,
      hour: _time.hour,
      minute: _time.minute,
      interval: _interval,
      customIntervalDays: _customDays,
      occurrencesCount: _occurrences,
    );
    if (widget.prefill == null) {
      await ref.read(customRemindersProvider.notifier).add(r);
    } else {
      await ref.read(customRemindersProvider.notifier).update(r);
    }
    if (mounted) Navigator.pop(context);
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
              Text('Reminder personalizat',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Titlu *'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Obligatoriu'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _body,
                decoration:
                    const InputDecoration(labelText: 'Descriere (opțional)'),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final p = await showDatePicker(
                    context: context,
                    initialDate: _start,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                    locale: const Locale('ro', 'RO'),
                  );
                  if (p != null) setState(() => _start = p);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Data start'),
                  child: Text(DateUtilsRo.short(_start)),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final p = await showTimePicker(
                      context: context, initialTime: _time);
                  if (p != null) setState(() => _time = p);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Ora'),
                  child: Text(
                      '${_time.hour.toString().padLeft(2, "0")}:${_time.minute.toString().padLeft(2, "0")}'),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ReminderInterval>(
                value: _interval,
                decoration:
                    const InputDecoration(labelText: 'Frecvență'),
                items: ReminderInterval.values
                    .map((i) => DropdownMenuItem(
                        value: i, child: Text(i.labelRo)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _interval = v ?? _interval),
              ),
              if (_interval == ReminderInterval.custom) ...[
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: '$_customDays',
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'La câte zile se repetă'),
                  onChanged: (v) {
                    final n = int.tryParse(v);
                    if (n != null && n > 0) _customDays = n;
                  },
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null || n <= 0) return 'Număr invalid';
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _occurrences?.toString() ?? '',
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Număr ocurențe (gol = la infinit)',
                ),
                onChanged: (v) {
                  final n = int.tryParse(v);
                  _occurrences = (n != null && n > 0) ? n : null;
                },
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

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
