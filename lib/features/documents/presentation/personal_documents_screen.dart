import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/nimbus_screen.dart';
import '../../../core/theme/nimbus_tokens.dart';
import '../../../core/theme/nimbus_widgets.dart';
import '../../../core/utils/date_utils.dart';
import '../domain/document.dart';
import 'document_providers.dart';

class PersonalDocumentsScreen extends ConsumerWidget {
  const PersonalDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(documentsProvider);
    final docs = all.where((d) => d.type.isPersonalDocument).toList();
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
              child: Icon(Icons.badge_rounded, size: 40, color: cs.primary),
            ),
            const SizedBox(height: 24),
            Text('Fără documente personale',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Adaugă buletinul și permisul. Te alertăm înainte de expirare.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRouter.scanner),
              icon: const Icon(Icons.document_scanner_rounded),
              label: const Text('Scanează cu camera'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Adaugă manual'),
            ),
          ],
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
            child: Icon(
              doc.type == DocumentType.permis
                  ? Icons.card_membership_rounded
                  : Icons.contact_page_rounded,
              color: color,
            ),
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
  DateTime _expiry = DateTime.now().add(const Duration(days: 365 * 10));
  final _serial = TextEditingController();

  @override
  void dispose() {
    _serial.dispose();
    super.dispose();
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
                        child:
                            Text(t == DocumentType.buletin ? 'Buletin' : 'Permis')))
                    .toList(),
                onChanged: (v) => setState(() => _type = v ?? _type),
              ),
              const SizedBox(height: 12),
              _date('Data emiterii', _issue,
                  (d) => setState(() => _issue = d)),
              const SizedBox(height: 12),
              _date('Data expirării', _expiry,
                  (d) => setState(() => _expiry = d)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _serial,
                decoration: const InputDecoration(
                  labelText: 'Serie & număr',
                ),
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

  Widget _date(String label, DateTime v, ValueChanged<DateTime> on) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          firstDate: DateTime(1990),
          lastDate: DateTime(2100),
          initialDate: v,
          locale: const Locale('ro', 'RO'),
        );
        if (picked != null) on(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(DateUtilsRo.short(v)),
      ),
    );
  }
}
