import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/app_settings_service.dart';
import '../../../core/theme/nimbus_tokens.dart';
import '../../../core/theme/nimbus_widgets.dart';
import '../../../core/theme/theme_variants.dart';

class ThemePickerScreen extends ConsumerWidget {
  const ThemePickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(appSettingsProvider).themeVariant;
    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedMeshBackdrop(
            tint: const NimbusVehicleTint(
              a: Color(0xFF9CC4DA),
              b: Color(0xFF5687AA),
              c: Color(0xFF3D4F7E),
              d: Color(0xFF1B2342),
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(title: const Text('Temă')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
                child: Text(
                  'Alege un stil vizual. Poți schimba oricând.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
              for (final variant in AppThemeVariant.values) ...[
                _ThemeOption(
                  variant: variant,
                  selected: variant == current,
                  onTap: () => ref
                      .read(appSettingsProvider.notifier)
                      .setThemeVariant(variant),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.variant,
    required this.selected,
    required this.onTap,
  });
  final AppThemeVariant variant;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeVariantPalette.of(variant);
    final scheme = palette.darkScheme;

    return GlassCard.heavy(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.primary.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: scheme.primary.withOpacity(0.4), width: 1.5),
                ),
                child: Icon(variant.iconData, color: scheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(variant.labelRo,
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 2),
                    Text(variant.descriptionRo,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            )),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded,
                    color: Theme.of(context).colorScheme.primary, size: 26)
              else
                Icon(Icons.circle_outlined,
                    color:
                        Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 26),
            ],
          ),
          const SizedBox(height: 14),
          // Palette swatches
          Row(
            children: [
              _Swatch(color: scheme.primary, label: 'primary'),
              const SizedBox(width: 6),
              _Swatch(color: palette.risk.safe, label: 'safe'),
              const SizedBox(width: 6),
              _Swatch(color: palette.risk.watch, label: 'watch'),
              const SizedBox(width: 6),
              _Swatch(color: palette.risk.warn, label: 'warn'),
              const SizedBox(width: 6),
              _Swatch(color: palette.risk.critical, label: 'critical'),
              const SizedBox(width: 6),
              Expanded(
                child: Container(
                  height: 32,
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.1), width: 0.5),
                  ),
                  alignment: Alignment.center,
                  child: Text('123 km/h',
                      style: palette.numberFont(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ).copyWith(color: scheme.onSurface)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: Colors.white.withOpacity(0.18), width: 0.5),
      ),
    );
  }
}
