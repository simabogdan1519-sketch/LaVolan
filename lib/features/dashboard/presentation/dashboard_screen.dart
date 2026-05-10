import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/nimbus_tokens.dart';
import '../../../core/theme/nimbus_widgets.dart';
import '../../../core/utils/date_utils.dart';
import '../../documents/domain/document.dart';
import '../../documents/presentation/document_providers.dart';
import '../../fuel/presentation/fuel_providers.dart';
import '../../maintenance/domain/maintenance_entry.dart';
import '../../maintenance/presentation/maintenance_providers.dart';
import '../../penalty_points/data/penalty_repository.dart';
import '../../penalty_points/presentation/penalty_providers.dart';
import '../../vehicle/domain/vehicle.dart';
import '../../vehicle/presentation/vehicle_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicles = ref.watch(vehiclesProvider);
    final selected = ref.watch(selectedVehicleProvider);

    if (vehicles.isEmpty) {
      return Stack(
        children: [
          const Positioned.fill(child: LvBackdrop()),
          Scaffold(
            backgroundColor: Colors.transparent,
            body: const _EmptyState(),
          ),
        ],
      );
    }

    return Stack(
      children: [
        const Positioned.fill(child: LvBackdrop()),
        Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: const Text('LaVolan'),
            actions: [
              IconButton(
                tooltip: 'Setări',
                icon: const Icon(Icons.settings_rounded),
                onPressed: () =>
                    Navigator.pushNamed(context, AppRouter.settings),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.pushNamed(context, AppRouter.scanner),
            icon: const Icon(Icons.document_scanner_rounded),
            label: const Text('Scanează'),
          ),
          body: RefreshIndicator(
            onRefresh: () async => ref.invalidate(selectedVehicleTintProvider),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.paddingOf(context).top + 56,
                16,
                120,
              ),
              children: [
                _VehicleHeroCard(),
                const SizedBox(height: 14),
                _QuickActions(),
                const SizedBox(height: 18),
                _NextDocumentCard(),
                const SizedBox(height: 14),
                _PenaltyCard(),
                const SizedBox(height: 14),
                if (selected != null) _FuelCard(vehicleId: selected.id),
                const SizedBox(height: 14),
                _MaintenanceCard(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ────────────────────────── Empty state ──────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_car_filled_rounded,
                size: 96, color: cs.onSurface.withOpacity(0.7)),
            const SizedBox(height: 16),
            Text('Bun venit la LaVolan',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(
              'Adaugă primul vehicul ca să începi.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRouter.vehicleForm),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Adaugă vehicul'),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────── Vehicle hero ──────────────────────────

class _VehicleHeroCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicles = ref.watch(vehiclesProvider);
    final selected = ref.watch(selectedVehicleProvider);
    if (selected == null) return const SizedBox.shrink();

    final t = Theme.of(context).extension<NimbusTokens>()!;

    return GlassCard.heavy(
      onTap: () => _pickVehicle(context, ref, vehicles, selected.id),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          _VehicleAvatar(vehicle: selected, size: 72),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Eyebrow('Vehicul activ', color: t.risk.safe),
                const SizedBox(height: 4),
                Text(
                  selected.displayName,
                  style: Theme.of(context).textTheme.titleLarge,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _MetaChip(text: selected.licensePlate),
                    _MetaChip(text: selected.fuelLabelRo),
                    _MetaChip(text: '${selected.mileage} km'),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.unfold_more_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }

  Future<void> _pickVehicle(BuildContext context, WidgetRef ref,
      List<Vehicle> vehicles, String selectedId) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: GlassCard.ultra(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final v in vehicles)
                  ListTile(
                    leading: _VehicleAvatar(vehicle: v, size: 40),
                    title: Text(v.displayName),
                    subtitle: Text(v.licensePlate),
                    selected: v.id == selectedId,
                    onTap: () => Navigator.pop(context, v.id),
                  ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.add_rounded),
                  title: const Text('Adaugă vehicul'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRouter.vehicleForm);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (picked != null) {
      ref.read(selectedVehicleIdProvider.notifier).state = picked;
      ref.invalidate(selectedVehicleTintProvider);
    }
  }
}

class _VehicleAvatar extends StatelessWidget {
  const _VehicleAvatar({required this.vehicle, this.size = 56});
  final Vehicle vehicle;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final p = vehicle.photoPath;
    final has = p != null && p.isNotEmpty;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: cs.surfaceContainerHighest.withOpacity(0.4),
        border: Border.all(
            color: Colors.white.withOpacity(0.25), width: 1.5),
      ),
      child: ClipOval(
        child: has
            ? Image.file(File(p),
                fit: BoxFit.cover,
                width: size,
                height: size,
                errorBuilder: (_, __, ___) =>
                    _fallbackIcon(cs, size))
            : _fallbackIcon(cs, size),
      ),
    );
  }

  Widget _fallbackIcon(ColorScheme cs, double size) => Icon(
        Icons.directions_car_rounded,
        size: size * 0.5,
        color: cs.onSurface.withOpacity(0.85),
      );
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: Colors.white.withOpacity(0.15), width: 0.5),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              letterSpacing: 0.6,
            ),
      ),
    );
  }
}

// ────────────────────────── Quick actions ──────────────────────────

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: _QuickAction(
          icon: Icons.local_gas_station_rounded,
          label: 'Alimentare',
          onTap: () => Navigator.pushNamed(context, AppRouter.fuel),
        )),
        const SizedBox(width: 10),
        Expanded(
            child: _QuickAction(
          icon: Icons.build_rounded,
          label: 'Mentenanță',
          onTap: () => Navigator.pushNamed(context, AppRouter.maintenance),
        )),
        const SizedBox(width: 10),
        Expanded(
            child: _QuickAction(
          icon: Icons.description_rounded,
          label: 'Documente',
          onTap: () => Navigator.pushNamed(context, AppRouter.documents),
        )),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GlassCard.light(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Icon(icon, color: cs.onSurface, size: 22),
          const SizedBox(height: 6),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

// ────────────────────────── Next document ──────────────────────────

class _NextDocumentCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).extension<NimbusTokens>()!;
    final next = ref.watch(nextExpiringDocumentProvider);
    if (next == null) {
      return GlassCard.heavy(
        onTap: () => Navigator.pushNamed(context, AppRouter.documents),
        child: Row(
          children: [
            const Icon(Icons.description_outlined, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Eyebrow('Documente', color: t.risk.safe),
                  const SizedBox(height: 4),
                  Text('Niciun document înregistrat',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text('Adaugă RCA, ITP sau Rovinieta',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      );
    }

    final daysLeft = next.expiryDate.difference(DateTime.now()).inDays;
    final color = t.docColor(daysLeft: daysLeft);
    final tier = daysLeft <= 7
        ? NimbusRiskTier.critical
        : daysLeft <= 30
            ? NimbusRiskTier.warn
            : daysLeft <= 60
                ? NimbusRiskTier.watch
                : NimbusRiskTier.safe;

    return GlassCard.heavy(
      onTap: () => Navigator.pushNamed(context, AppRouter.documents),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Eyebrow('Următorul document', color: color),
              RiskPill(tier: tier, label: _docLabel(next.type)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                daysLeft >= 0 ? '$daysLeft' : '${daysLeft.abs()}',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: color,
                    ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  daysLeft >= 0 ? 'zile rămase' : 'zile depășit',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Expiră ${DateUtilsRo.display(next.expiryDate)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  String _docLabel(DocumentType t) {
    switch (t) {
      case DocumentType.rca:
        return 'RCA';
      case DocumentType.itp:
        return 'ITP';
      case DocumentType.rovinieta:
        return 'Rovinietă';
      case DocumentType.talon:
        return 'Talon';
      case DocumentType.altul:
        return 'Document';
      case DocumentType.buletin:
        return 'Buletin';
      case DocumentType.permis:
        return 'Permis';
    }
  }
}

// ────────────────────────── Penalty card ──────────────────────────

class _PenaltyCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).extension<NimbusTokens>()!;
    final stats = ref.watch(penaltyStatsProvider);
    final color = t.riskColor(points: stats.activePoints);
    final tier = t.riskTier(points: stats.activePoints);
    final progress = (stats.activePoints / AppConstants.penaltyMaxBeforeSuspension)
        .clamp(0.0, 1.0);

    return GlassCard.heavy(
      onTap: () => Navigator.pushNamed(context, AppRouter.penalty),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Eyebrow('Puncte de penalizare', color: color),
              RiskPill(tier: tier, label: tier.labelRo),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${stats.activePoints}',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: color,
                    ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '/ ${AppConstants.penaltyMaxBeforeSuspension}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              valueColor: AlwaysStoppedAnimation(color),
              backgroundColor: Colors.white.withOpacity(0.10),
            ),
          ),
          const SizedBox(height: 10),
          _PenaltyFooter(stats: stats),
        ],
      ),
    );
  }
}

class _PenaltyFooter extends StatelessWidget {
  const _PenaltyFooter({required this.stats});
  final PenaltyStats stats;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final next = stats.active.isEmpty
        ? null
        : (stats.active.toList()
              ..sort((a, b) => a.expiresOn.compareTo(b.expiresOn)))
            .first
            .expiresOn;
    return Text(
      next == null
          ? 'Nicio penalizare activă'
          : 'Următoarea expiră ${DateUtilsRo.display(next)}',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
          ),
    );
  }
}

// ────────────────────────── Fuel card ──────────────────────────

class _FuelCard extends ConsumerWidget {
  const _FuelCard({required this.vehicleId});
  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).extension<NimbusTokens>()!;
    final stats = ref.watch(fuelStatsProvider(vehicleId));
    final cs = Theme.of(context).colorScheme;

    return GlassCard.heavy(
      onTap: () => Navigator.pushNamed(context, AppRouter.fuel),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Eyebrow('Combustibil', color: t.risk.safe),
              const Icon(Icons.local_gas_station_rounded, size: 20),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  value: stats.avgConsumption == 0
                      ? '—'
                      : stats.avgConsumption.toStringAsFixed(1),
                  unit: 'L/100km',
                  label: 'Consum mediu',
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: cs.outlineVariant.withOpacity(0.5),
              ),
              Expanded(
                child: _Metric(
                  value: stats.costPerKm == 0
                      ? '—'
                      : stats.costPerKm.toStringAsFixed(2),
                  unit: 'lei/km',
                  label: 'Cost / km',
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: cs.outlineVariant.withOpacity(0.5),
              ),
              Expanded(
                child: _Metric(
                  value: stats.totalSpent.toStringAsFixed(0),
                  unit: 'lei',
                  label: 'Total',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(
      {required this.value, required this.unit, required this.label});
  final String value;
  final String unit;
  final String label;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: cs.onSurface,
                      ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  )),
        ],
      ),
    );
  }
}

// ────────────────────────── Maintenance card ──────────────────────────

class _MaintenanceCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).extension<NimbusTokens>()!;
    final next = ref.watch(nextMaintenanceProvider);

    return GlassCard.heavy(
      onTap: () => Navigator.pushNamed(context, AppRouter.maintenance),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: t.risk.safe.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.build_rounded, color: t.risk.safe),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Eyebrow('Mentenanță'),
                const SizedBox(height: 4),
                Text(
                  next == null
                      ? 'Niciun serviciu programat'
                      : next.categoryLabelRo,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (next != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    next.nextDueDate != null
                        ? 'Scade ${DateUtilsRo.display(next.nextDueDate!)}'
                        : next.nextDueMileage != null
                            ? 'Scade la ${next.nextDueMileage} km'
                            : 'Fără termen',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}
