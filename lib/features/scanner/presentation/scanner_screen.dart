import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/attachment_photo_service.dart';
import '../../../core/services/ocr_service.dart';
import '../../../core/theme/nimbus_screen.dart';
import '../../../core/theme/nimbus_widgets.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/require_vehicle.dart';
import '../../documents/domain/document.dart';
import '../../documents/presentation/document_providers.dart';
import '../../fuel/domain/fuel_entry.dart';
import '../../fuel/presentation/fuel_providers.dart';
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
  ScanMode _mode = ScanMode.auto;

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
      final r = await _ocr.processImage(File(picked.path), mode: _mode);
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
    return NimbusScreen(
      appBar: AppBar(title: const Text('Scanare')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ModeSelector(
              mode: _mode,
              onChanged: (m) => setState(() => _mode = m),
            ),
            const SizedBox(height: 14),
            if (_image == null)
              _IntroCard(mode: _mode)
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(_image!, height: 220, fit: BoxFit.cover),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed:
                        _processing ? null : () => _pick(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_rounded),
                    label: const Text('Cameră'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        _processing ? null : () => _pick(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_rounded),
                    label: const Text('Galerie'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_processing)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              ),
            if (_result != null) _resultWidget(_result!),
          ],
        ),
      ),
    );
  }

  Widget _resultWidget(OcrResult r) {
    switch (r.resolvedMode) {
      case ScanMode.fuelReceipt:
        return _FuelResultForm(result: r);
      case ScanMode.personalDocument:
        return _DocumentResultForm(result: r, image: _image);
      case ScanMode.vehicleDocument:
      case ScanMode.auto:
        return _DocumentResultForm(result: r, image: _image);
    }
  }
}

// ────────────────────── Mode selector ──────────────────────

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.mode, required this.onChanged});
  final ScanMode mode;
  final ValueChanged<ScanMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _chip(context, ScanMode.auto, 'Auto', Icons.auto_awesome_rounded),
          const SizedBox(width: 8),
          _chip(context, ScanMode.vehicleDocument, 'Doc auto',
              Icons.shield_rounded),
          const SizedBox(width: 8),
          _chip(context, ScanMode.fuelReceipt, 'Bon PECO',
              Icons.receipt_long_rounded),
          const SizedBox(width: 8),
          _chip(context, ScanMode.personalDocument, 'CI / Permis',
              Icons.badge_rounded),
        ],
      ),
    );
  }

  Widget _chip(
      BuildContext context, ScanMode m, String label, IconData icon) {
    final selected = mode == m;
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => onChanged(m),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? cs.primary.withOpacity(0.22)
              : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? cs.primary.withOpacity(0.6)
                : Colors.white.withOpacity(0.15),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16, color: selected ? cs.primary : cs.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: selected ? cs.primary : cs.onSurfaceVariant,
                    )),
          ],
        ),
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.mode});
  final ScanMode mode;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (icon, title, body) = _content(mode);
    return GlassCard.heavy(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 32, color: cs.primary),
          ),
          const SizedBox(height: 14),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(body,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  )),
        ],
      ),
    );
  }

  (IconData, String, String) _content(ScanMode m) {
    switch (m) {
      case ScanMode.fuelReceipt:
        return (
          Icons.receipt_long_rounded,
          'Scanează bon PECO',
          'Detectăm litri, preț, total, stație și data. Verifică datele extrase și completează kilometrajul înainte de salvare.'
        );
      case ScanMode.personalDocument:
        return (
          Icons.badge_rounded,
          'Scanează CI sau permis',
          'Extragem CNP-ul, seria și data expirării. Te alertăm înainte de expirare.'
        );
      case ScanMode.vehicleDocument:
        return (
          Icons.shield_rounded,
          'Scanează RCA, ITP, Rovinietă',
          'Aplicația detectează tipul, data emiterii și expirării.'
        );
      case ScanMode.auto:
        return (
          Icons.auto_awesome_rounded,
          'Scanare automată',
          'Detectăm singuri ce ai pus în față: poliță, bon PECO sau act de identitate.'
        );
    }
  }
}

// ────────────────────── Document result ──────────────────────

class _DocumentResultForm extends ConsumerStatefulWidget {
  const _DocumentResultForm({required this.result, required this.image});
  final OcrResult result;
  final File? image;

  @override
  ConsumerState<_DocumentResultForm> createState() =>
      _DocumentResultFormState();
}

class _DocumentResultFormState extends ConsumerState<_DocumentResultForm> {
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
    _policy = TextEditingController(
        text: widget.result.policyNumber ??
            widget.result.personalDocumentNumber ??
            '');
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
    final isPersonal = _type.isPersonalDocument;
    final selected = isPersonal ? null : await requireVehicle(context, ref);
    if (!isPersonal && selected == null) return;

    // Poza venită de la camera/OCR e într-un cache temporar — o copiem
    // în folderul nostru permanent ca să nu dispară.
    String? persistentPath;
    if (widget.image != null) {
      try {
        persistentPath = await AttachmentPhotoService.instance
            .storeFromPath(sourcePath: widget.image!.path, scope: 'doc');
      } catch (_) {
        // dacă eșuează, salvăm fără poză
      }
    }

    final doc = VehicleDocument(
      id: const Uuid().v4(),
      vehicleId: selected?.id ?? '_personal_',
      type: _type,
      issueDate: _issue,
      expiryDate: _expiry,
      issuer: _issuer.text.trim().isEmpty ? null : _issuer.text.trim(),
      policyNumber:
          _policy.text.trim().isEmpty ? null : _policy.text.trim(),
      imagePath: persistentPath,
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
    final conf = (widget.result.confidence * 100).round();
    final cs = Theme.of(context).colorScheme;
    return GlassCard.heavy(
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
                color: conf >= 66 ? cs.primary : cs.tertiary,
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
                .map((t) =>
                    DropdownMenuItem(value: t, child: Text(_label(t))))
                .toList(),
            onChanged: (v) => setState(() => _type = v ?? _type),
          ),
          const SizedBox(height: 12),
          _date('Data emiterii', _issue, (d) => setState(() => _issue = d)),
          const SizedBox(height: 12),
          _date(
              'Data expirării', _expiry, (d) => setState(() => _expiry = d)),
          if (_type.isVehicleDocument) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _plate,
              decoration:
                  const InputDecoration(labelText: 'Nr. înmatriculare'),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _issuer,
            decoration: const InputDecoration(
                labelText: 'Emitent / asigurator'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _policy,
            decoration: InputDecoration(
              labelText: _type.isPersonalDocument
                  ? 'Serie & număr'
                  : 'Număr poliță',
            ),
          ),
          if (widget.result.personalCnp != null) ...[
            const SizedBox(height: 8),
            Text('CNP detectat: ${widget.result.personalCnp}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    )),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _confirm,
            icon: const Icon(Icons.check_rounded),
            label: const Text('Confirmă și salvează'),
          ),
          const SizedBox(height: 8),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text('Vezi text brut OCR',
                style: Theme.of(context).textTheme.bodySmall),
            children: [
              SelectableText(widget.result.rawText,
                  style: const TextStyle(fontSize: 11)),
            ],
          ),
        ],
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
      case DocumentType.buletin:
        return 'Buletin';
      case DocumentType.permis:
        return 'Permis';
    }
  }
}

// ────────────────────── Fuel result ──────────────────────

class _FuelResultForm extends ConsumerStatefulWidget {
  const _FuelResultForm({required this.result});
  final OcrResult result;

  @override
  ConsumerState<_FuelResultForm> createState() => _FuelResultFormState();
}

class _FuelResultFormState extends ConsumerState<_FuelResultForm> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _date;
  late TextEditingController _liters;
  late TextEditingController _ppl;
  late TextEditingController _total;
  late TextEditingController _station;
  final _mileage = TextEditingController();
  bool _full = true;

  @override
  void initState() {
    super.initState();
    _date = widget.result.fuelDate ?? DateTime.now();
    _liters = TextEditingController(
        text: widget.result.fuelLiters?.toStringAsFixed(2) ?? '');
    _ppl = TextEditingController(
        text: widget.result.fuelPricePerLiter?.toStringAsFixed(2) ?? '');
    _total = TextEditingController(
        text: widget.result.fuelTotalCost?.toStringAsFixed(2) ?? '');
    _station =
        TextEditingController(text: widget.result.fuelStationName ?? '');
  }

  @override
  void dispose() {
    _liters.dispose();
    _ppl.dispose();
    _total.dispose();
    _station.dispose();
    _mileage.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Completează câmpurile obligatorii (marcate cu *)')));
      return;
    }
    final selected = await requireVehicle(context, ref);
    if (selected == null) return;

    final mileage = int.tryParse(_mileage.text.trim());
    if (mileage == null || mileage <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Kilometrajul curent este obligatoriu')));
      return;
    }

    final f = FuelEntry(
      id: const Uuid().v4(),
      vehicleId: selected.id,
      date: _date,
      liters: double.tryParse(_liters.text) ?? 0,
      pricePerLiter: double.tryParse(_ppl.text) ?? 0,
      totalCost: double.tryParse(_total.text) ?? 0,
      mileage: mileage,
      fullTank: _full,
      station: _station.text.trim().isEmpty ? null : _station.text.trim(),
    );
    try {
      await ref.read(fuelProvider.notifier).add(f);

      // Auto-update vehicle mileage if greater.
      if (mileage > selected.mileage) {
        selected.mileage = mileage;
        await ref.read(vehiclesProvider.notifier).update(selected);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare la salvare: $e')));
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Realimentare salvată')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final conf = (widget.result.confidence * 100).round();
    final cs = Theme.of(context).colorScheme;
    return GlassCard.heavy(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  conf >= 66
                      ? Icons.check_circle_rounded
                      : Icons.info_outline_rounded,
                  color: conf >= 66 ? cs.primary : cs.tertiary,
                ),
                const SizedBox(width: 8),
                Text('Bon PECO ($conf% siguranță)',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final p = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                  locale: const Locale('ro', 'RO'),
                );
                if (p != null) setState(() => _date = p);
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Data'),
                child: Text(DateUtilsRo.short(_date)),
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _liters,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Litri'),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Obligatoriu' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _ppl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Lei / L'),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            TextFormField(
              controller: _total,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Total (lei)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _mileage,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Kilometraj curent *',
                helperText: 'Obligatoriu pentru calcul consum',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Obligatoriu';
                final n = int.tryParse(v.trim());
                if (n == null || n <= 0) return 'Kilometraj invalid';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _station,
              decoration:
                  const InputDecoration(labelText: 'Benzinărie (opțional)'),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: _full,
              onChanged: (v) => setState(() => _full = v),
              title: const Text('Plin complet'),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check_rounded),
              label: const Text('Confirmă și salvează'),
            ),
          ],
        ),
      ),
    );
  }
}
