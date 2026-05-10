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
import '../../../core/widgets/photo_viewer_screen.dart';
import '../domain/document.dart';
import 'document_providers.dart';

class PersonalDocumentsScreen extends ConsumerWidget {
  const PersonalDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(documentsProvider);
    final docs = all.where((d) => d.type.isPersonalDocument).toList();
    final now = DateTime.now();
    docs.sort((a, b) {
      final aExp = a.expiryDate.isBefore(now);
      final bExp = b.expiryDate.isBefore(now);
      if (aExp != bExp) return aExp ? 1 : -1;
      return a.expiryDate.compareTo(b.expiryDate);
    });
    return NimbusScreen(
      appBar: AppBar(title: const Text('Documente personale')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _open(context),
        icon: const Icon(Icons.add),
        label: const Text('Adaugă'),
      ),
      body: docs.isEmpty
          ? _Empty(onAdd: () => _open(context))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _Tile(doc: docs[i]),
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
        child: const _Form(),
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
                child: Icon(Icons.badge_rounded, size: 40, color: cs.primary),
              ),
              const SizedBox(height: 24),
              Text('Fără documente personale',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                'Adaugă buletinul și permisul. Te alertăm când se apropie expirarea.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Adaugă document'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tile extends ConsumerWidget {
  const _Tile({required this.doc});
  final VehicleDocument doc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).extension<NimbusTokens>()!;
    final cs = Theme.of(context).colorScheme;
    final daysLeft = doc.expiryDate.difference(DateTime.now()).inDays;
    final color = t.docColor(daysLeft: daysLeft);
    final hasImage = doc.imagePath != null && doc.imagePath!.isNotEmpty;
    final isExpired = daysLeft < 0;

    return GlassCard.heavy(
      onTap: hasImage
          ? () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PhotoViewerScreen(
                    path: doc.imagePath!,
                    title: doc.typeLabelRo,
                  ),
                ),
              )
          : null,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          if (hasImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(doc.imagePath!),
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _iconBox(color, doc.type),
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
                await AttachmentPhotoService.instance.delete(doc.imagePath);
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
        child: Icon(
          type == DocumentType.buletin
              ? Icons.contact_page_rounded
              : Icons.card_membership_rounded,
          color: color,
        ),
      );
}

class _Form extends ConsumerStatefulWidget {
  const _Form();
  @override
  ConsumerState<_Form> createState() => _FormState();
}

class _FormState extends ConsumerState<_Form> {
  final _formKey = GlobalKey<FormState>();
  DocumentType _type = DocumentType.buletin;
  DateTime _issue = DateTime.now();
  DateTime _expiry = DateTime.now()
      .add(Duration(days: 365 * AppConstants.buletinValidityYears));
  final _serial = TextEditingController();
  String? _imagePath;
  bool _autoExpiry = true; // calc expiry as issue + standard validity

  @override
  void dispose() {
    _serial.dispose();
    super.dispose();
  }

  void _recompute() {
    if (!_autoExpiry) return;
    final years = _type == DocumentType.buletin
        ? AppConstants.buletinValidityYears
        : AppConstants.permisValidityYears;
    _expiry = DateTime(_issue.year + years, _issue.month, _issue.day);
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final path = await AttachmentPhotoService.instance.pickAndStore(
      source: source,
      scope: 'pdoc',
    );
    if (path != null) setState(() => _imagePath = path);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final doc = VehicleDocument(
      id: const Uuid().v4(),
      vehicleId: '_personal_',
      type: _type,
      issueDate: _issue,
      expiryDate: _expiry,
      policyNumber:
          _serial.text.trim().isEmpty ? null : _serial.text.trim(),
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
              Text('Document personal',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              DropdownButtonFormField<DocumentType>(
                value: _type,
                decoration: const InputDecoration(labelText: 'Tip'),
                items: DocumentType.values
                    .where((t) => t.isPersonalDocument)
                    .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(t == DocumentType.buletin
                            ? 'Buletin'
                            : 'Permis')))
                    .toList(),
                onChanged: (v) => setState(() {
                  _type = v ?? _type;
                  _recompute();
                }),
              ),
              const SizedBox(height: 12),
              _date('Data emiterii', _issue, (d) => setState(() {
                    _issue = d;
                    _recompute();
                  })),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _autoExpiry,
                onChanged: (v) => setState(() {
                  _autoExpiry = v;
                  if (v) _recompute();
                }),
                title: Text('Calculează expirarea automat',
                    style: Theme.of(context).textTheme.bodyMedium),
                subtitle: Text(
                  '${_type == DocumentType.buletin ? AppConstants.buletinValidityYears : AppConstants.permisValidityYears} ani de la emitere',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
              ),
              const SizedBox(height: 8),
              IgnorePointer(
                ignoring: _autoExpiry,
                child: Opacity(
                  opacity: _autoExpiry ? 0.6 : 1.0,
                  child: _date('Data expirării', _expiry,
                      (d) => setState(() => _expiry = d)),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _serial,
                decoration:
                    const InputDecoration(labelText: 'Serie (opțional)'),
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

  Widget _date(String label, DateTime value, ValueChanged<DateTime> on) {
    return InkWell(
      onTap: () async {
        final p = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(1990),
          lastDate: DateTime(2100),
          locale: const Locale('ro', 'RO'),
        );
        if (p != null) on(p);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(DateUtilsRo.short(value)),
      ),
    );
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
