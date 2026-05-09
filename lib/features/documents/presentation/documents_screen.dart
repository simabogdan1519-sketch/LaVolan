import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/date_utils.dart';
import '../../vehicle/presentation/vehicle_providers.dart';
import '../domain/document.dart';
import 'document_providers.dart';

class DocumentsScreen extends ConsumerWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docs = ref.watch(documentsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Documente')),
      body: docs.isEmpty
          ? const Center(child: Text('Niciun document înregistrat'))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (_, i) {
                final d = docs[i];
                return _DocumentTile(doc: d);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Adaugă'),
      ),
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(_).viewInsets.bottom,
        ),
        child: const _DocumentForm(),
      ),
    );
  }
}

class _DocumentTile extends ConsumerWidget {
  const _DocumentTile({required this.doc});
  final VehicleDocument doc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    Color color;
    switch (doc.status) {
      case DocumentStatus.expired:
        color = scheme.error;
        break;
      case DocumentStatus.expiringSoon:
        color = Colors.orange;
        break;
      case DocumentStatus.valid:
        color = Colors.green;
        break;
    }
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(Icons.shield_rounded, color: color),
        ),
        title: Text(doc.typeLabelRo,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
            '${DateUtilsRo.short(doc.expiryDate)} · ${DateUtilsRo.relativeRo(doc.expiryDate)}'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded),
          onPressed: () =>
              ref.read(documentsProvider.notifier).delete(doc.id),
        ),
      ),
    );
  }
}

class _DocumentForm extends ConsumerStatefulWidget {
  const _DocumentForm({this.prefill});
  final VehicleDocument? prefill;

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
  void initState() {
    super.initState();
    if (widget.prefill != null) {
      _type = widget.prefill!.type;
      _issue = widget.prefill!.issueDate;
      _expiry = widget.prefill!.expiryDate;
      _issuer.text = widget.prefill!.issuer ?? '';
      _policy.text = widget.prefill!.policyNumber ?? '';
      _cost.text = widget.prefill!.cost?.toString() ?? '';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final selected = ref.read(selectedVehicleProvider);
    if (selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Adaugă întâi un vehicul')));
      return;
    }
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Adaugă document',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            DropdownButtonFormField<DocumentType>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Tip document'),
              items: DocumentType.values
                  .map((t) => DropdownMenuItem(
                      value: t, child: Text(_label(t))))
                  .toList(),
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            const SizedBox(height: 12),
            _dateField('Data emiterii', _issue, (d) => setState(() => _issue = d)),
            const SizedBox(height: 12),
            _dateField('Data expirării', _expiry, (d) => setState(() => _expiry = d)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _issuer,
              decoration: const InputDecoration(labelText: 'Emitent (opțional)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _policy,
              decoration: const InputDecoration(labelText: 'Număr poliță (opțional)'),
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
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _dateField(String label, DateTime value, ValueChanged<DateTime> onChange) {
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
    }
  }
}
