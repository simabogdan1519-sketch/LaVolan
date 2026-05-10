import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/attachment_photo_service.dart';
import '../../../core/theme/nimbus_screen.dart';
import '../../../core/theme/nimbus_tokens.dart';
import '../../../core/theme/nimbus_widgets.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/require_vehicle.dart';
import '../../../core/widgets/photo_viewer_screen.dart';
import '../domain/equipment_item.dart';
import 'equipment_providers.dart';

/// Ecran "Echipament obligatoriu". Afișează un checklist condensat al
/// celor 5 categorii relevante, cu status colorat (✓ ok, ! atenție,
/// ✗ lipsă/expirat). Tap pe rând → adaugă/editează acea categorie.
class EquipmentScreen extends ConsumerWidget {
  const EquipmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(equipmentProvider);
    return NimbusScreen(
      appBar: AppBar(title: const Text('Echipament obligatoriu')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          const _ChecklistHeader(),
          const SizedBox(height: 12),
          for (final type in _displayOrder)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ChecklistTile(
                type: type,
                items: all.where((e) => e.type == type).toList(),
              ),
            ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _openForm(context, EquipmentType.altul, null),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Adaugă alt echipament'),
          ),
        ],
      ),
    );
  }

  static const _displayOrder = [
    EquipmentType.extinctor,
    EquipmentType.trusaMedicala,
    EquipmentType.triunghiReflectorizant,
    EquipmentType.vestaReflectorizanta,
    EquipmentType.rotiRezerva,
  ];
}

class _ChecklistHeader extends ConsumerWidget {
  const _ChecklistHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(equipmentProvider);
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).extension<NimbusTokens>()!;

    final issues = <String>[];
    for (final type in EquipmentScreen._displayOrder) {
      final items = all.where((e) => e.type == type).toList();
      final totalQty = items.fold<int>(0, (sum, it) => sum + it.quantity);
      if (totalQty < type.minRequiredQuantity) {
        issues.add('${type.labelRo} lipsește');
      } else if (type.canExpire && items.any((i) => i.isExpired)) {
        issues.add('${type.labelRo} expirat');
      }
    }

    final ok = issues.isEmpty;
    final color = ok ? t.risk.safe : t.risk.critical;
    final icon = ok ? Icons.check_circle_rounded : Icons.error_outline_rounded;

    return GlassCard.heavy(
      tinted: ok ? null : color.withOpacity(0.10),
      child: Row(
        children: [
          Icon(icon, size: 36, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ok
                      ? 'Totul e în regulă'
                      : 'Probleme: ${issues.length}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  ok
                      ? 'Mașina ta are tot echipamentul obligatoriu.'
                      : issues.join(' · '),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistTile extends ConsumerWidget {
  const _ChecklistTile({required this.type, required this.items});
  final EquipmentType type;
  final List<EquipmentItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).extension<NimbusTokens>()!;
    final cs = Theme.of(context).colorScheme;
    final totalQty = items.fold<int>(0, (sum, it) => sum + it.quantity);
    final hasExpired = type.canExpire && items.any((i) => i.isExpired);
    final missing = totalQty < type.minRequiredQuantity;

    Color statusColor;
    IconData statusIcon;
    String statusText;
    if (missing) {
      statusColor = t.risk.critical;
      statusIcon = Icons.close_rounded;
      statusText = 'Lipsește';
    } else if (hasExpired) {
      statusColor = t.risk.critical;
      statusIcon = Icons.warning_amber_rounded;
      statusText = 'Expirat';
    } else if (type.canExpire) {
      // Cea mai apropiată expirare
      final next = items
          .where((i) => i.expiryDate != null)
          .map((i) => i.daysUntilExpiry!)
          .fold<int?>(null, (a, b) => a == null || b < a ? b : a);
      if (next != null && next <= 60) {
        statusColor = t.risk.warn;
        statusIcon = Icons.schedule_rounded;
        statusText = 'Expiră în $next zile';
      } else {
        statusColor = t.risk.safe;
        statusIcon = Icons.check_rounded;
        statusText = 'OK · $totalQty buc.';
      }
    } else {
      statusColor = t.risk.safe;
      statusIcon = Icons.check_rounded;
      statusText = 'OK · $totalQty buc.';
    }

    return GlassCard.heavy(
      onTap: () => _openSheet(context, type, items),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_iconFor(type), color: statusColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type.labelRo,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        statusText,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: statusColor),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
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

void _openSheet(
    BuildContext context, EquipmentType type, List<EquipmentItem> items) {
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
      child: _CategorySheet(type: type, existing: items),
    ),
  );
}

void _openForm(
    BuildContext context, EquipmentType type, EquipmentItem? prefill) {
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
      child: _ItemForm(initialType: type, existing: prefill),
    ),
  );
}

/// Sheet care arată ce ai în categoria asta și permite editat / adăugat /
/// șters. Pentru categoriile fără expirare (triunghi/vestă/roată),
/// arată un slider de cantitate; pentru extinctor/trusă, listă cu fiecare
/// piesă în parte (fiecare are propria expirare).
class _CategorySheet extends ConsumerStatefulWidget {
  const _CategorySheet({required this.type, required this.existing});
  final EquipmentType type;
  final List<EquipmentItem> existing;

  @override
  ConsumerState<_CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends ConsumerState<_CategorySheet> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isExpiring = widget.type.canExpire;

    return GlassCard.ultra(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
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
                  color: cs.outline.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(widget.type.labelRo,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center),
            if (widget.type.quantityHintRo.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                widget.type.quantityHintRo,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
            ],
            const SizedBox(height: 20),
            if (isExpiring)
              ..._expiringList()
            else
              ..._countOnly(),
          ],
        ),
      ),
    );
  }

  List<Widget> _expiringList() {
    return [
      for (final item in widget.existing) ...[
        _ExpiringItemTile(item: item),
        const SizedBox(height: 8),
      ],
      const SizedBox(height: 4),
      FilledButton.icon(
        onPressed: () {
          Navigator.pop(context);
          _openForm(context, widget.type, null);
        },
        icon: const Icon(Icons.add_rounded),
        label: Text(widget.existing.isEmpty
            ? 'Adaugă ${widget.type.labelRo.toLowerCase()}'
            : 'Adaugă încă ${widget.type.labelRo.toLowerCase()}'),
      ),
    ];
  }

  List<Widget> _countOnly() {
    final notifier = ref.read(equipmentProvider.notifier);
    // Pentru categoriile fără expirare, păstrăm cel mult un singur record
    // cu cantitatea ca atribut, ca să nu se aglomereze tabelul.
    final item = widget.existing.isEmpty ? null : widget.existing.first;
    int qty = item?.quantity ?? widget.type.minRequiredQuantity;

    return [
      StatefulBuilder(builder: (context, setSheetState) {
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  iconSize: 36,
                  onPressed: qty > 0
                      ? () => setSheetState(() => qty--)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                ),
                const SizedBox(width: 16),
                Text('$qty',
                    style: Theme.of(context).textTheme.displayMedium),
                const SizedBox(width: 8),
                Text('buc.',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(width: 16),
                IconButton(
                  iconSize: 36,
                  onPressed: () => setSheetState(() => qty++),
                  icon: const Icon(Icons.add_circle_outline_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              qty < widget.type.minRequiredQuantity
                  ? 'Sub minimul cerut (${widget.type.minRequiredQuantity}).'
                  : 'În regulă · cerință legală: ${widget.type.minRequiredQuantity}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () async {
                final selected = await requireVehicle(context, ref);
                if (selected == null) return;
                if (item != null) {
                  item.quantity = qty;
                  await notifier.update(item);
                } else {
                  await notifier.add(EquipmentItem(
                    id: const Uuid().v4(),
                    vehicleId: selected.id,
                    type: widget.type,
                    quantity: qty,
                  ));
                }
                if (mounted) Navigator.pop(context);
              },
              icon: const Icon(Icons.check_rounded),
              label: const Text('Salvează'),
            ),
          ],
        );
      }),
    ];
  }
}

class _ExpiringItemTile extends ConsumerWidget {
  const _ExpiringItemTile({required this.item});
  final EquipmentItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).extension<NimbusTokens>()!;
    final days = item.daysUntilExpiry;
    final color = days == null
        ? cs.onSurfaceVariant
        : days < 0
            ? t.risk.critical
            : days < 30
                ? t.risk.warn
                : days < 90
                    ? t.risk.watch
                    : t.risk.safe;

    String subtitle;
    if (item.expiryDate != null) {
      subtitle = days! < 0
          ? 'Expirat ${DateUtilsRo.short(item.expiryDate!)}'
          : 'Expiră ${DateUtilsRo.short(item.expiryDate!)} · în $days zile';
    } else {
      subtitle = item.purchaseDate != null
          ? 'Cumpărat ${DateUtilsRo.short(item.purchaseDate!)}'
          : 'Fără dată';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          if (item.imagePath != null && item.imagePath!.isNotEmpty)
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PhotoViewerScreen(
                    path: item.imagePath!,
                    title: item.type.labelRo,
                  ),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(item.imagePath!),
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                      Icons.broken_image_outlined,
                      color: color),
                ),
              ),
            )
          else
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                item.type == EquipmentType.extinctor
                    ? Icons.fire_extinguisher_outlined
                    : Icons.medical_services_outlined,
                color: color,
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.brand?.isNotEmpty == true ? item.brand! : 'Bucată',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        )),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        )),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.pop(context);
              _openForm(context, item.type, item);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () async {
              await ref
                  .read(equipmentProvider.notifier)
                  .delete(item.id);
              if (item.imagePath != null) {
                await AttachmentPhotoService.instance.delete(item.imagePath);
              }
            },
          ),
        ],
      ),
    );
  }
}

/// Form pentru un item cu expirare (extinctor, trusă, "altul").
class _ItemForm extends ConsumerStatefulWidget {
  const _ItemForm({required this.initialType, this.existing});
  final EquipmentType initialType;
  final EquipmentItem? existing;
  @override
  ConsumerState<_ItemForm> createState() => _ItemFormState();
}

class _ItemFormState extends ConsumerState<_ItemForm> {
  final _formKey = GlobalKey<FormState>();
  late EquipmentType _type;
  DateTime? _expiry;
  DateTime? _purchase;
  late TextEditingController _brand;
  late TextEditingController _notes;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _type = widget.existing?.type ?? widget.initialType;
    _expiry = widget.existing?.expiryDate ??
        DateTime.now().add(const Duration(days: 365 * 3));
    _purchase = widget.existing?.purchaseDate ?? DateTime.now();
    _brand = TextEditingController(text: widget.existing?.brand ?? '');
    _notes = TextEditingController(text: widget.existing?.notes ?? '');
    _imagePath = widget.existing?.imagePath;
  }

  @override
  void dispose() {
    _brand.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final path = await AttachmentPhotoService.instance.pickAndStore(
      source: source,
      scope: 'eq',
    );
    if (path != null) setState(() => _imagePath = path);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final selected = await requireVehicle(context, ref);
    if (selected == null) return;
    final notifier = ref.read(equipmentProvider.notifier);
    try {
      if (widget.existing != null) {
        widget.existing!
          ..type = _type
          ..expiryDate = _type.canExpire ? _expiry : null
          ..purchaseDate = _purchase
          ..brand = _brand.text.trim().isEmpty ? null : _brand.text.trim()
          ..notes = _notes.text.trim().isEmpty ? null : _notes.text.trim()
          ..imagePath = _imagePath;
        await notifier.update(widget.existing!);
      } else {
        await notifier.add(EquipmentItem(
          id: const Uuid().v4(),
          vehicleId: selected.id,
          type: _type,
          expiryDate: _type.canExpire ? _expiry : null,
          purchaseDate: _purchase,
          brand: _brand.text.trim().isEmpty ? null : _brand.text.trim(),
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
          imagePath: _imagePath,
        ));
      }
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
                    color: cs.outline.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(widget.existing == null ? 'Adaugă piesă' : 'Editează piesă',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              DropdownButtonFormField<EquipmentType>(
                value: _type,
                decoration: const InputDecoration(labelText: 'Tip'),
                items: EquipmentType.values
                    .map((t) =>
                        DropdownMenuItem(value: t, child: Text(t.labelRo)))
                    .toList(),
                onChanged: (v) => setState(() => _type = v ?? _type),
              ),
              const SizedBox(height: 12),
              if (_type.canExpire) ...[
                _date('Data expirării', _expiry,
                    (d) => setState(() => _expiry = d)),
                const SizedBox(height: 12),
              ],
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
              const SizedBox(height: 16),
              _PhotoAttachmentRow(
                path: _imagePath,
                onPickCamera: () => _pickPhoto(ImageSource.camera),
                onPickGallery: () => _pickPhoto(ImageSource.gallery),
                onRemove: () => setState(() => _imagePath = null),
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

/// Component reutilizabil — buton "Adaugă poză" sau preview cu opțiune
/// de șters / înlocuit. Folosit pe equipment, documents, personal docs.
class _PhotoAttachmentRow extends StatelessWidget {
  const _PhotoAttachmentRow({
    required this.path,
    required this.onPickCamera,
    required this.onPickGallery,
    required this.onRemove,
  });
  final String? path;
  final VoidCallback onPickCamera;
  final VoidCallback onPickGallery;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (path == null || path!.isEmpty) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onPickCamera,
              icon: const Icon(Icons.camera_alt_rounded),
              label: const Text('Foto'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onPickGallery,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Galerie'),
            ),
          ),
        ],
      );
    }
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PhotoViewerScreen(path: path!),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              File(path!),
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 64, height: 64, color: cs.surfaceContainerHigh,
                child: const Icon(Icons.broken_image_outlined),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Poză atașată',
                  style: Theme.of(context).textTheme.bodyMedium),
              Text('Tap pe poză ca s-o vezi mărită',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      )),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded),
          onPressed: onRemove,
        ),
      ],
    );
  }
}
