import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/nimbus_screen.dart';
import '../../../core/theme/nimbus_tokens.dart';
import '../../../core/theme/nimbus_widgets.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/require_vehicle.dart';
import '../domain/equipment_item.dart';
import 'equipment_providers.dart';

class EquipmentScreen extends ConsumerWidget {
  const EquipmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(equipmentProvider);
    return NimbusScreen(
      appBar: AppBar(title: const Text('Echipament obligatoriu')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _open(context),
        icon: const Icon(Icons.add),
        label: const Text('Adaugă'),
      ),
      body: items.isEmpty
          ? _Empty(onAdd: () => _open(context))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _Tile(item: items[i]),
            ),
    );
  }

  void _open(BuildContext context) {
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
        child: const _EquipmentForm(),
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
                border: Border.all(
                    color: cs.primary.withOpacity(0.4), width: 1.5),
              ),
              child: Icon(Icons.fire_extinguisher_outlined,
                  size: 40, color: cs.primary),
            ),
            const SizedBox(height: 24),
            Text('Niciun echipament',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Adaugă extinctor, trusă medicală, vestă, triunghi. Te alertăm înainte să expire.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Adaugă echipament'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends ConsumerWidget {
  const _Tile({required this.item});
  final EquipmentItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).extension<NimbusTokens>()!;
    final cs = Theme.of(context).colorScheme;
    Color color = t.risk.safe;
    String? subtitle;
    if (item.expiryDate != null) {
      final days = item.daysUntilExpiry!;
      color = t.docColor(daysLeft: days);
      subtitle = days < 0
          ? 'Expirat ${DateUtilsRo.short(item.expiryDate!)}'
          : 'Expiră ${DateUtilsRo.short(item.expiryDate!)} · ${DateUtilsRo.relativeRo(item.expiryDate!)}';
    } else if (item.purchaseDate != null) {
      subtitle = 'Cumpărat ${DateUtilsRo.short(item.purchaseDate!)}';
    }

    return GlassCard.heavy(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_iconFor(item.type), color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.type.labelRo,
                    style: Theme.of(context).textTheme.titleMedium),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () =>
                ref.read(equipmentProvider.notifier).delete(item.id),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(EquipmentType t) {
    switch (t) {
      case EquipmentType.extinctor:
        return Icons.fire_extinguisher_outlined;
      case EquipmentType.trusaMedicala:
        return Icons.medical_services_outlined;
      case EquipmentType.triunghiReflectorizant:
        return Icons.warning_amber_outlined;
      case EquipmentType.vestaReflectorizanta:
        return Icons.checkroom_outlined;
      case EquipmentType.rotiRezerva:
        return Icons.tire_repair_rounded;
      case EquipmentType.altul:
        return Icons.inventory_2_outlined;
    }
  }
}

class _EquipmentForm extends ConsumerStatefulWidget {
  const _EquipmentForm();
  @override
  ConsumerState<_EquipmentForm> createState() => _EquipmentFormState();
}

class _EquipmentFormState extends ConsumerState<_EquipmentForm> {
  final _formKey = GlobalKey<FormState>();
  EquipmentType _type = EquipmentType.extinctor;
  DateTime? _expiry = DateTime.now().add(const Duration(days: 365 * 3));
  DateTime? _purchase = DateTime.now();
  final _brand = TextEditingController();
  final _notes = TextEditingController();

  @override
  void dispose() {
    _brand.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final selected = await requireVehicle(context, ref);
    if (selected == null) return;
    final item = EquipmentItem(
      id: const Uuid().v4(),
      vehicleId: selected.id,
      type: _type,
      expiryDate: _type.canExpire ? _expiry : null,
      purchaseDate: _purchase,
      brand: _brand.text.trim().isEmpty ? null : _brand.text.trim(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    );
    await ref.read(equipmentProvider.notifier).add(item);
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
              Text('Adaugă echipament',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(
                'Poți scana eticheta cu OCR-ul.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRouter.scanner);
                },
                icon: const Icon(Icons.document_scanner_rounded),
                label: const Text('Scanează eticheta'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<EquipmentType>(
                value: _type,
                decoration: const InputDecoration(labelText: 'Tip'),
                items: EquipmentType.values
                    .map((t) => DropdownMenuItem(
                        value: t, child: Text(t.labelRo)))
                    .toList(),
                onChanged: (v) => setState(() => _type = v ?? _type),
              ),
              const SizedBox(height: 12),
              if (_type.canExpire)
                _date('Data expirării', _expiry,
                    (d) => setState(() => _expiry = d)),
              if (_type.canExpire) const SizedBox(height: 12),
              _date('Data achiziției', _purchase,
                  (d) => setState(() => _purchase = d)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _brand,
                decoration:
                    const InputDecoration(labelText: 'Marcă (opțional)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notes,
                maxLines: 2,
                decoration:
                    const InputDecoration(labelText: 'Note (opțional)'),
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

  Widget _date(String label, DateTime? value, ValueChanged<DateTime> on) {
    return InkWell(
      onTap: () async {
        final p = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          locale: const Locale('ro', 'RO'),
        );
        if (p != null) on(p);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(value == null ? '—' : DateUtilsRo.short(value)),
      ),
    );
  }
}
