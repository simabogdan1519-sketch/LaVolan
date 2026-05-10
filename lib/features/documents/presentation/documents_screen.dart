import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/nimbus_screen.dart';
import '../../../core/theme/nimbus_tokens.dart';
import '../../../core/theme/nimbus_widgets.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/require_vehicle.dart';
import '../../vehicle/presentation/vehicle_providers.dart';
import '../domain/document.dart';
import 'document_providers.dart';

class DocumentsScreen extends ConsumerWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(documentsProvider);
    // Show only vehicle-related documents here. Personal documents
    // (buletin, permis) live on a separate screen.
    final docs = all.where((d) => d.type.isVehicleDocument).toList();
    return NimbusScreen(
      appBar: AppBar(title: const Text('Documente')),
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
              child: Icon(Icons.description_outlined, size: 40, color: cs.primary),
            ),
            const SizedBox(height: 24),
            Text('Niciun document încă',
                style: Theme.of(context).textTheme.headlineSmall),
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
    );
  }
}

class _DocumentTile extends ConsumerWidget {
  const _DocumentTile({required this.doc});
  final VehicleDocument doc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).extension<NimbusTokens>()!;
    final daysLeft = doc.expiryDate.difference(DateTime.now()).inDays;
    final color = t.docColor(daysLeft: daysLeft);

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
            child: Icon(_iconFor(doc.type), color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doc.typeLabelRo,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  '${DateUtilsRo.short(doc.expiryDate)} · ${DateUtilsRo.relativeRo(doc.expiryDate)}',
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
                ref.read(documentsProvider.notifier).delete(doc.id),
          ),
        ],
      ),
    );
  }

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
  DateTime _expiry = DateTime.now().add(const Duration(days: 365));
  final _issuer = TextEditingController();
  final _policy = TextEditingController();
  final _cost = TextEditingController();

  @override
  void dispose() {
    _issuer.dispose();
    _policy.dispose();
    _cost.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final selected = await requireVehicle(context, ref);
    if (selected == null) return;
    final doc = VehicleDocument(
      id: const Uuid().v4(),
      vehicleId: selected.id,
      type: _type,
      issueDate: _issue,
      expiryDate: _expiry,
      issuer: _issuer.text.trim().isEmpty ? null : _issuer.text.trim(),
      policyNumber:
          _policy.text.trim().isEmpty ? null : _policy.text.trim(),
      cost: double.tryParse(_cost.text.trim()),
    );
    await ref.read(documentsProvider.notifier).add(doc);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard.ultra(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Form(
        key: _formKey,
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
                  color:
                      Theme.of(context).colorScheme.outline.withOpacity(0.6),
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
                  .map((t) =>
                      DropdownMenuItem(value: t, child: Text(_label(t))))
                  .toList(),
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            const SizedBox(height: 12),
            _dateField('Data emiterii', _issue,
                (d) => setState(() => _issue = d)),
            const SizedBox(height: 12),
            _dateField('Data expirării', _expiry,
                (d) => setState(() => _expiry = d)),
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
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_rounded),
              label: const Text('Salvează'),
            ),
          ],
        ),
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
