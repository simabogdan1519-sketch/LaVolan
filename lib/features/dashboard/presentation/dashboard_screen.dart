import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/date_utils.dart';
import '../../documents/domain/document.dart';
import '../../documents/presentation/document_providers.dart';
import '../../fuel/presentation/fuel_providers.dart';
import '../../penalty_points/data/penalty_repository.dart';
import '../../penalty_points/presentation/penalty_providers.dart';
import '../../vehicle/presentation/vehicle_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final vehicles = ref.watch(vehiclesProvider);
    final selected = ref.watch(selectedVehicleProvider);
    final nextDoc = ref.watch(nextExpiringDocumentProvider);
    final penalty = ref.watch(penaltyStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'Scanare document',
            onPressed: () => Navigator.pushNamed(context, AppRouter.scanner),
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => Navigator.pushNamed(context, AppRouter.settings),
          ),
        ],
      ),
      body: vehicles.isEmpty
          ? _EmptyState(
              onAdd: () =>
                  Navigator.pushNamed(context, AppRouter.vehicleForm),
            )
          : RefreshIndicator(
              onRefresh: () async => ref.invalidate(vehiclesProvider),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Vehicle selector
                  _VehicleSelectorCard(),
                  const SizedBox(height: 8),

                  // Quick actions row
                  _QuickActions(),
                  const SizedBox(height: 8),

                  // Next document
                  _SectionHeader(
                    title: 'Document expiră curând',
                    actionLabel: 'Toate',
                    onAction: () => Navigator.pushNamed(
                        context, AppRouter.documents),
                  ),
                  if (nextDoc != null)
                    _DocumentCard(doc: nextDoc)
                  else
                    _EmptyHint(
                      icon: Icons.description_outlined,
                      text: 'Niciun document înregistrat',
                      action: 'Adaugă',
                      onAction: () => Navigator.pushNamed(
                          context, AppRouter.documents),
                    ),

                  const SizedBox(height: 16),
                  _SectionHeader(
                    title: 'Puncte de penalizare',
                    actionLabel: 'Detalii',
                    onAction: () =>
                        Navigator.pushNamed(context, AppRouter.penalty),
                  ),
                  _PenaltyCard(stats: penalty),

                  const SizedBox(height: 16),
                  if (selected != null) ...[
                    _SectionHeader(
                      title: 'Combustibil',
                      actionLabel: 'Detalii',
                      onAction: () =>
                          Navigator.pushNamed(context, AppRouter.fuel),
                    ),
                    Builder(builder: (ctx) {
                      final stats = ref.watch(fuelStatsProvider(selected.id));
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: _Metric(
                                  label: 'Consum mediu',
                                  value: stats.avgConsumption == 0
                                      ? '—'
                                      : '${stats.avgConsumption.toStringAsFixed(1)} L/100',
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 36,
                                color: scheme.outlineVariant,
                              ),
                              Expanded(
                                child: _Metric(
                                  label: 'Cost / km',
                                  value: stats.costPerKm == 0
                                      ? '—'
                                      : '${stats.costPerKm.toStringAsFixed(2)} lei',
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 36,
                                color: scheme.outlineVariant,
                              ),
                              Expanded(
                                child: _Metric(
                                  label: 'Total',
                                  value:
                                      '${stats.totalSpent.toStringAsFixed(0)} lei',
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],

                  const SizedBox(height: 24),
                  _SectionHeader(
                    title: 'Mentenanță',
                    actionLabel: 'Detalii',
                    onAction: () => Navigator.pushNamed(
                        context, AppRouter.maintenance),
                  ),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.build_rounded),
                      title: const Text('Vezi istoric și planificare'),
                      subtitle: const Text(
                          'Ulei, filtre, plăcuțe, anvelope, revizii'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.pushNamed(
                          context, AppRouter.maintenance),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
      floatingActionButton: vehicles.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRouter.scanner),
              icon: const Icon(Icons.document_scanner_rounded),
              label: const Text('Scanează'),
            ),
    );
  }
}

class _VehicleSelectorCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicles = ref.watch(vehiclesProvider);
    final selectedId = ref.watch(selectedVehicleIdProvider);
    final selected = ref.watch(selectedVehicleProvider);

    return Card(
      child: InkWell(
        onTap: () async {
          final picked = await showModalBottomSheet<String>(
            context: context,
            builder: (_) => SafeArea(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final v in vehicles)
                    ListTile(
                      leading: const Icon(Icons.directions_car_rounded),
                      title: Text(v.displayName),
                      subtitle: Text(v.licensePlate),
                      selected: v.id == selectedId,
                      onTap: () => Navigator.pop(context, v.id),
                    ),
                  const Divider(height: 0),
                  ListTile(
                    leading: const Icon(Icons.add),
                    title: const Text('Adaugă vehicul'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRouter.vehicleForm);
                    },
                  ),
                ],
              ),
            ),
          );
          if (picked != null) {
            ref.read(selectedVehicleIdProvider.notifier).state = picked;
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor:
                    Theme.of(context).colorScheme.primaryContainer,
                child: const Icon(Icons.directions_car_rounded, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selected?.displayName ?? '—',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700),
                    ),
                    if (selected != null)
                      Text(
                        '${selected.licensePlate} · ${selected.fuelLabelRo} · ${selected.mileage} km',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              const Icon(Icons.unfold_more_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.shield_outlined, 'Documente', AppRouter.documents),
      (Icons.local_gas_station_rounded, 'Combustibil', AppRouter.fuel),
      (Icons.build_circle_outlined, 'Mentenanță', AppRouter.maintenance),
      (Icons.gavel_rounded, 'Puncte', AppRouter.penalty),
    ];
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemBuilder: (_, i) {
          final (icon, label, route) = items[i];
          return _QuickActionTile(icon: icon, label: label, route: route);
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: items.length,
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.route,
  });
  final IconData icon;
  final String label;
  final String route;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primaryContainer.withOpacity(0.5),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.pushNamed(context, route),
        child: SizedBox(
          width: 96,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: scheme.onPrimaryContainer, size: 28),
              const SizedBox(height: 6),
              Text(label, style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
  });
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({required this.doc});
  final VehicleDocument doc;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Color bg;
    Color fg;
    IconData icon;
    switch (doc.status) {
      case DocumentStatus.expired:
        bg = scheme.errorContainer;
        fg = scheme.onErrorContainer;
        icon = Icons.error_outline_rounded;
        break;
      case DocumentStatus.expiringSoon:
        bg = const Color(0xFFFFF3CD);
        fg = const Color(0xFF7A5C00);
        icon = Icons.warning_amber_rounded;
        break;
      case DocumentStatus.valid:
        bg = scheme.primaryContainer;
        fg = scheme.onPrimaryContainer;
        icon = Icons.check_circle_outline_rounded;
        break;
    }
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: bg,
          foregroundColor: fg,
          child: Icon(icon),
        ),
        title: Text(doc.typeLabelRo,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          '${DateUtilsRo.short(doc.expiryDate)} · ${DateUtilsRo.relativeRo(doc.expiryDate)}',
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () =>
            Navigator.pushNamed(context, AppRouter.documents),
      ),
    );
  }
}

class _PenaltyCard extends StatelessWidget {
  const _PenaltyCard({required this.stats});
  final PenaltyStats stats;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (stats.risk) {
      case PenaltyRiskLevel.safe:
        color = Colors.green;
        label = 'Sigur';
        break;
      case PenaltyRiskLevel.caution:
        color = Colors.orange;
        label = 'Atenție';
        break;
      case PenaltyRiskLevel.warning:
        color = Colors.deepOrange;
        label = 'Risc ridicat';
        break;
      case PenaltyRiskLevel.critical:
        color = Colors.red;
        label = 'Suspendare iminentă';
        break;
    }
    final ratio =
        (stats.activePoints / AppConstants.penaltyMaxBeforeSuspension).clamp(0.0, 1.0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('${stats.activePoints}',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800, color: color)),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '/ ${AppConstants.penaltyMaxBeforeSuspension} puncte active',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(label,
                      style: TextStyle(color: color, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                color: color,
                backgroundColor: color.withOpacity(0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label,
            style: Theme.of(context).textTheme.labelSmall,
            textAlign: TextAlign.center),
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({
    required this.icon,
    required this.text,
    required this.action,
    required this.onAction,
  });
  final IconData icon;
  final String text;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Text(text)),
            FilledButton.tonal(onPressed: onAction, child: Text(action)),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.directions_car_filled_rounded, size: 96),
            const SizedBox(height: 16),
            Text('Bun venit la LaVolan',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Adaugă primul tău vehicul pentru a începe să gestionezi documentele, mentenanța și consumul.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Adaugă vehicul'),
            ),
          ],
        ),
      ),
    );
  }
}
