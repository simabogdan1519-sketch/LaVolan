import 'package:flutter/material.dart';

import 'nimbus_widgets.dart';

/// Drop-in replacement for [Scaffold] that paints the theme-aware
/// LvBackdrop behind the content. Folosește-l ca rădăcină pentru fiecare
/// ecran, ca să fie consistent.
///
/// ```dart
/// NimbusScreen(
///   appBar: AppBar(title: Text('Documente')),
///   body: ListView(...),
/// )
/// ```
class NimbusScreen extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: LvBackdrop()),
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
