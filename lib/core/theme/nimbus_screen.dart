import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/vehicle/presentation/vehicle_providers.dart';
import 'nimbus_tokens.dart';
import 'nimbus_widgets.dart';

/// Drop-in replacement for [Scaffold] that paints a mesh backdrop tinted
/// after the active vehicle (or a neutral tint if none).
///
/// Use it as the root of every screen for consistent Nimbus look:
///
/// ```dart
/// NimbusScreen(
///   appBar: AppBar(title: Text('Documente')),
///   body: ListView(...),
/// )
/// ```
class NimbusScreen extends ConsumerWidget {
  const NimbusScreen({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.extendBodyBehindAppBar = false,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool extendBodyBehindAppBar;

  static const NimbusVehicleTint _neutralTint = NimbusVehicleTint(
    a: Color(0xFF9CC4DA),
    b: Color(0xFF5687AA),
    c: Color(0xFF3D4F7E),
    d: Color(0xFF1B2342),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tintAsync = ref.watch(selectedVehicleTintProvider);
    final tint = tintAsync.maybeWhen(
      data: (t) => t,
      orElse: () => _neutralTint,
    );

    return Stack(
      children: [
        Positioned.fill(child: AnimatedMeshBackdrop(tint: tint)),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: appBar,
          body: body,
          floatingActionButton: floatingActionButton,
          bottomNavigationBar: bottomNavigationBar,
          extendBodyBehindAppBar: extendBodyBehindAppBar,
        ),
      ],
    );
  }
}
