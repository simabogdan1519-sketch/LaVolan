import 'dart:io';

import 'package:flutter/material.dart';

/// Vizualizator full-screen pentru poze atașate (poze de documente,
/// echipament, etc). Pinch-to-zoom prin InteractiveViewer.
///
/// Folosire:
///   Navigator.push(context, MaterialPageRoute(
///     builder: (_) => PhotoViewerScreen(path: doc.imagePath!),
///   ));
class PhotoViewerScreen extends StatelessWidget {
  const PhotoViewerScreen({
    super.key,
    required this.path,
    this.heroTag,
    this.title,
  });

  final String path;
  final String? heroTag;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final file = File(path);

    Widget image = Image.file(
      file,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image_outlined,
                size: 64, color: Colors.white.withOpacity(0.6)),
            const SizedBox(height: 8),
            Text('Poza nu mai poate fi încărcată',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.white.withOpacity(0.7))),
          ],
        ),
      ),
    );

    if (heroTag != null) {
      image = Hero(tag: heroTag!, child: image);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: title != null ? Text(title!) : null,
      ),
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: SizedBox.expand(
          child: InteractiveViewer(
            minScale: 0.8,
            maxScale: 5,
            child: Center(child: image),
          ),
        ),
      ),
    );
  }
}
