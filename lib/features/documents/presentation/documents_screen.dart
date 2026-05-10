import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/attachment_photo_service.dart';
import '../../../core/theme/nimbus_screen.dart';
import '../../../core/theme/nimbus_tokens.dart';
import '../../../core/theme/nimbus_widgets.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/require_vehicle.dart';
import '../../../core/widgets/photo_viewer_screen.dart';
import '../domain/document.dart';
import 'document_providers.dart';

class DocumentsScreen extends ConsumerWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(documentsProvider);
    // Doar documentele de vehicul aici. Cele personale (buletin, permis)
    // au ecranul lor.
    final docs = all.where((d) => d.type.isVehicleDocument).toList();
    // Sortează: valabile mai întâi (cele care expiră cel mai curând în
    // sus), expirate jos.
    final now = DateTime.now();
    docs.sort((a, b) {
      final aExp = a.expiryDate.isBefore(now);
      final bExp = b.expiryDate.isBefore(now);
      if (aExp != bExp) return aExp ? 1 : -1;
      return a.expiryDate.compareTo(b.expiryDate);
    });

    return NimbusScreen(
      appBar: AppBar(title: const Text('Documente vehicul')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Adaugă'),
      ),
      body: docs.isEmpty
          ? _EmptyDocs(onAdd: () => _showAddSheet(context, ref))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _DocumentTile(doc: docs[i]),
            ),
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref) {
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
        child: const _DocumentForm(),
      ),
    );
  }
}

class _EmptyDocs extends StatelessWidget {
  const _EmptyDocs({required this.onAdd});
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: Center(
        child: Padding(
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
                child: Icon(Icons.description_outlined,
                    size: 40, color: cs.primary),
              ),
              const SizedBox(height: 24),
              Text('Niciun document încă',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                'Adaugă RCA, ITP sau rovinieta și te alertăm înainte de expirare.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Adaugă primul document'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocumentTile extends ConsumerWidget {
  const _DocumentTile({required this.doc});
  final VehicleDocument doc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).extension<NimbusTokens>()!;
    final cs = Theme.of(context).colorScheme;
    final daysLeft = doc.expiryDate.difference(DateTime.now()).inDays;
    final color = t.docColor(daysLeft: daysLeft);
    final hasImage =
        doc.imagePath != null && doc.imagePath!.isNotEmpty;
    final isExpired = daysLeft < 0;

    return GlassCard.heavy(
      onTap: () => _showDetailSheet(context, ref, doc),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          if (hasImage)
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PhotoViewerScreen(
                    path: doc.imagePath!,
                    title: doc.typeLabelRo,
                  ),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(doc.imagePath!),
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _iconBox(color, doc.type),
                ),
              ),
            )
          else
            _iconBox(color, doc.type),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(doc.typeLabelRo,
                        style: Theme.of(context).textTheme.titleMedium),
                    if (isExpired) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: t.risk.critical,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('EXPIRAT',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                                letterSpacing: 0.6)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${DateUtilsRo.short(doc.expiryDate)} · ${DateUtilsRo.relativeRo(doc.expiryDate)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isExpired ? t.risk.critical : cs.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () async {
              await ref.read(documentsProvider.notifier).delete(doc.id);
              if (doc.imagePath != null) {
                await AttachmentPhotoService.instance
                    .delete(doc.imagePath);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _iconBox(Color color, DocumentType type) => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withOpacity(0.18),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(_iconFor(type), color: color),
      );

  IconData _iconFor(DocumentType t) {
    switch (t) {
      case DocumentType.rca:
        return Icons.shield_rounded;
      case DocumentType.itp:
        return Icons.verified_rounded;
      case DocumentType.rovinieta:
        return Icons.alt_route_rounded;
      case DocumentType.talon:
        return Icons.badge_rounded;
      case DocumentType.altul:
        return Icons.description_rounded;
      case DocumentType.buletin:
        return Icons.contact_page_rounded;
      case DocumentType.permis:
        return Icons.card_membership_rounded;
    }
  }

  void _showDetailSheet(
      BuildContext context, WidgetRef ref, VehicleDocument doc) {
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
        child: _DocumentDetailSheet(doc: doc),
      ),
    );
  }
}

/// Sheet care arată detalii document + poza (cu tap pentru full-screen).
class _DocumentDetailSheet extends ConsumerWidget {
  const _DocumentDetailSheet({required this.doc});
  final VehicleDocument doc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final hasImage = doc.imagePath != null && doc.imagePath!.isNotEmpty;
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
            Text(doc.typeLabelRo,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            if (hasImage) ...[
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PhotoViewerScreen(
                      path: doc.imagePath!,
                      title: doc.typeLabelRo,
                    ),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(doc.imagePath!),
                    height: 200,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => Container(
                      height: 200,
                      color: cs.surfaceContainerHigh,
                      child: const Center(
                          child: Icon(Icons.broken_image_outlined, size: 48)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            _detailRow('Emis',
                DateUtilsRo.short(doc.issueDate), Icons.event_rounded),
            const SizedBox(height: 8),
            _detailRow('Expiră',
                DateUtilsRo.short(doc.expiryDate), Icons.event_busy_rounded),
            if (doc.issuer != null) ...[
              const SizedBox(height: 8),
              _detailRow('Emitent', doc.issuer!, Icons.business_rounded),
            ],
            if (doc.policyNumber != null) ...[
              const SizedBox(height: 8),
              _detailRow('Număr', doc.policyNumber!, Icons.numbers_rounded),
            ],
            if (doc.cost != null) ...[
              const SizedBox(height: 8),
              _detailRow('Cost', '${doc.cost!.toStringAsFixed(2)} lei',
                  Icons.payments_outlined),
            ],
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded),
              label: const Text('Închide'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, IconData icon) => Builder(
        builder: (context) {
          final cs = Theme.of(context).colorScheme;
          return Row(
            children: [
              Icon(icon, size: 18, color: cs.onSurfaceVariant),
              const SizedBox(width: 10),
              Text('$label:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      )),
              const SizedBox(width: 8),
              Expanded(
                child: Text(value,
                    style: Theme.of(context).textTheme.bodyMedium),
              ),
            ],
          );
        },
      );
}

class _DocumentForm extends ConsumerStatefulWidget {
  const _DocumentForm();

  @override
  ConsumerState<_DocumentForm> createState() => _DocumentFormState();
}

class _DocumentFormState extends ConsumerState<_DocumentForm> {
  final _formKey = GlobalKey<FormState>();
  DocumentType _type = DocumentType.rca;
  DateTime _issue = DateTime.now();
  DateTime? _expiry; // calculat din valabilitate de regulă
  /// Valabilitatea aleasă (în zile sau luni, depinde de tipul documentului).
  /// Pentru RCA/ITP — în luni. Pentru rovinietă — în zile. Pentru talon
  /// și "altul" — null și utilizatorul alege manual data.
  int? _validityValue;
  final _issuer = TextEditingController();
  final _policy = TextEditingController();
  final _cost = TextEditingController();
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _applyDefaultValidity();
  }

  void _applyDefaultValidity() {
    switch (_type) {
      case DocumentType.rca:
        _validityValue = 12;
        break;
      case DocumentType.itp:
        _validityValue = 24;
        break;
      case DocumentType.rovinieta:
        _validityValue = 365;
        break;
      default:
        _validityValue = null;
    }
    _recomputeExpiry();
  }

  void _recomputeExpiry() {
    if (_validityValue == null) return;
    switch (_type) {
      case DocumentType.rca:
      case DocumentType.itp:
        _expiry = DateTime(_issue.year, _issue.month + _validityValue!, _issue.day);
        break;
      case DocumentType.rovinieta:
        _expiry = _issue.add(Duration(days: _validityValue!));
        break;
      default:
        _expiry ??= _issue.add(const Duration(days: 365));
    }
  }

  @override
  void dispose() {
    _issuer.dispose();
    _policy.dispose();
    _cost.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final path = await AttachmentPhotoService.instance.pickAndStore(
      source: source,
      scope: 'doc',
    );
    if (path != null) setState(() => _imagePath = path);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final selected = await requireVehicle(context, ref);
    if (selected == null) return;
    final expiry = _expiry ?? _issue.add(const Duration(days: 365));
    final doc = VehicleDocument(
      id: const Uuid().v4(),
      vehicleId: selected.id,
      type: _type,
      issueDate: _issue,
      expiryDate: expiry,
      issuer: _issuer.text.trim().isEmpty ? null : _issuer.text.trim(),
      policyNumber:
          _policy.text.trim().isEmpty ? null : _policy.text.trim(),
      cost: double.tryParse(_cost.text.trim()),
      imagePath: _imagePath,
    );
    try {
      await ref.read(documentsProvider.notifier).add(doc);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare la salvare: $e')));
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document salvat')));
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
              Text('Adaugă document',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              DropdownButtonFormField<DocumentType>(
                value: _type,
                decoration: const InputDecoration(labelText: 'Tip document'),
                items: DocumentType.values
                    .where((t) => t.isVehicleDocument)
                    .map((t) => DropdownMenuItem(
                        value: t, child: Text(_label(t))))
                    .toList(),
                onChanged: (v) => setState(() {
                  _type = v ?? _type;
                  _applyDefaultValidity();
                }),
              ),
              const SizedBox(height: 12),
              _dateField('Data emiterii', _issue,
                  (d) => setState(() {
                        _issue = d;
                        _recomputeExpiry();
                      })),
              const SizedBox(height: 12),
              _validitySelector(),
              const SizedBox(height: 12),
              _expiryDisplay(),
              const SizedBox(height: 12),
              TextFormField(
                controller: _issuer,
                decoration:
                    const InputDecoration(labelText: 'Emitent (opțional)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _policy,
                decoration: const InputDecoration(
                    labelText: 'Număr poliță (opțional)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cost,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Cost (lei)'),
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

  Widget _validitySelector() {
    switch (_type) {
      case DocumentType.rca:
        return _chipChooser(
          label: 'Valabilitate',
          options: [
            for (final m in AppConstants.rcaValidityMonths)
              (m, '$m luni'),
          ],
        );
      case DocumentType.itp:
        return _chipChooser(
          label: 'Valabilitate',
          options: [
            for (final m in AppConstants.itpValidityMonths)
              (m, m == 12 ? '1 an' : m == 24 ? '2 ani' : '$m luni'),
          ],
        );
      case DocumentType.rovinieta:
        return _chipChooser(
          label: 'Valabilitate',
          options: [
            for (final d in AppConstants.rovinietaValidityDays)
              (d, _rovinietaLabel(d)),
          ],
        );
      default:
        return _dateField('Data expirării',
            _expiry ?? _issue.add(const Duration(days: 365)),
            (d) => setState(() => _expiry = d));
    }
  }

  String _rovinietaLabel(int days) {
    if (days == 1) return '1 zi';
    if (days == 7) return '7 zile';
    if (days == 10) return '10 zile';
    if (days == 30) return '30 zile';
    if (days == 60) return '60 zile';
    if (days == 90) return '90 zile';
    if (days == 365) return '12 luni';
    return '$days zile';
  }

  Widget _chipChooser({required String label, required List<(int, String)> options}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            )),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (val, lbl) in options)
              ChoiceChip(
                label: Text(lbl),
                selected: _validityValue == val,
                onSelected: (sel) {
                  if (sel) {
                    setState(() {
                      _validityValue = val;
                      _recomputeExpiry();
                    });
                  }
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _expiryDisplay() {
    final cs = Theme.of(context).colorScheme;
    final txt = _expiry == null
        ? 'Alege valabilitatea'
        : 'Expiră: ${DateUtilsRo.short(_expiry!)}';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primary.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.event_busy_rounded, color: cs.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(txt,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w600,
                    )),
          ),
        ],
      ),
    );
  }

  Widget _dateField(
      String label, DateTime value, ValueChanged<DateTime> onChange) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          initialDate: value,
          locale: const Locale('ro', 'RO'),
        );
        if (picked != null) onChange(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(DateUtilsRo.short(value)),
      ),
    );
  }

  String _label(DocumentType t) {
    switch (t) {
      case DocumentType.rca:
        return 'RCA';
      case DocumentType.itp:
        return 'ITP';
      case DocumentType.rovinieta:
        return 'Rovinietă';
      case DocumentType.talon:
        return 'Talon (CIV)';
      case DocumentType.altul:
        return 'Altul';
      case DocumentType.buletin:
        return 'Buletin';
      case DocumentType.permis:
        return 'Permis';
    }
  }
}

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
              Text('Tap ca s-o vezi mărită',
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
