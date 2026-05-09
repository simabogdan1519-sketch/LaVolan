import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/ocr_service.dart';
import '../../../core/utils/date_utils.dart';
import '../../documents/domain/document.dart';
import '../../documents/presentation/document_providers.dart';
import '../../vehicle/presentation/vehicle_providers.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  final OcrProcessingService _ocr = MlKitOcrService();
  bool _processing = false;
  OcrResult? _result;
  File? _image;

  @override
  void dispose() {
    _ocr.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 90);
    if (picked == null) return;
    setState(() {
      _processing = true;
      _image = File(picked.path);
      _result = null;
    });
    try {
      final r = await _ocr.processImage(File(picked.path));
      setState(() => _result = r);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Eroare OCR: $e')));
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scanare document')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_image == null) _IntroCard(),
            if (_image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(_image!,
                    height: 240, fit: BoxFit.cover),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _processing
                        ? null
                        : () => _pick(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_rounded),
                    label: const Text('Cameră'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _processing
                        ? null
                        : () => _pick(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_rounded),
                    label: const Text('Galerie'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_processing)
              const Center(child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              )),
            if (_result != null) _ResultForm(result: _result!, image: _image),
          ],
        ),
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.document_scanner_rounded, size: 48),
            const SizedBox(height: 12),
            Text('Scanează RCA, ITP sau Rovinietă',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              'Aplicația detectează tipul documentului și extrage automat data de expirare. Verifică datele extrase înainte de salvare.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultForm extends ConsumerStatefulWidget {
  const _ResultForm({required this.result, required this.image});
  final OcrResult result;
  final File? image;

  @override
  ConsumerState<_ResultForm> createState() => _ResultFormState();
}

class _ResultFormState extends ConsumerState<_ResultForm> {
  late DocumentType _type;
  late DateTime _expiry;
  late DateTime _issue;
  late TextEditingController _issuer;
  late TextEditingController _policy;
  late TextEditingController _plate;

  @override
  void initState() {
    super.initState();
    _type = widget.result.detectedType ?? DocumentType.rca;
    _expiry = widget.result.expiryDate ??
        DateTime.now().add(const Duration(days: 365));
    _issue = widget.result.issueDate ?? DateTime.now();
    _issuer = TextEditingController(text: widget.result.issuer ?? '');
    _policy = TextEditingController(text: widget.result.policyNumber ?? '');
    _plate = TextEditingController(text: widget.result.licensePlate ?? '');
  }

  @override
  void dispose() {
    _issuer.dispose();
    _policy.dispose();
    _plate.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
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
      policyNumber: _policy.text.trim().isEmpty ? null : _policy.text.trim(),
      imagePath: widget.image?.path,
    );
    await ref.read(documentsProvider.notifier).add(doc);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document salvat')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final conf = (widget.result.confidence * 100).round();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  conf >= 66
                      ? Icons.check_circle_rounded
                      : Icons.info_outline_rounded,
                  color: conf >= 66 ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text('Date extrase ($conf% siguranță)',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
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
            _date('Data emiterii', _issue, (d) => setState(() => _issue = d)),
            const SizedBox(height: 12),
            _date('Data expirării', _expiry, (d) => setState(() => _expiry = d)),
            const SizedBox(height: 12),
            TextField(
              controller: _plate,
              decoration: const InputDecoration(labelText: 'Nr. înmatriculare'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _issuer,
              decoration: const InputDecoration(labelText: 'Emitent / asigurator'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _policy,
              decoration: const InputDecoration(labelText: 'Număr poliță'),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _confirm,
              icon: const Icon(Icons.check_rounded),
              label: const Text('Confirmă și salvează'),
            ),
            const SizedBox(height: 8),
            ExpansionTile(
              title: const Text('Vezi text brut OCR'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SelectableText(widget.result.rawText,
                      style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _date(String label, DateTime v, ValueChanged<DateTime> on) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: v,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
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
