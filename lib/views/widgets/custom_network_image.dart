import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'web_image_stub.dart' if (dart.library.html) 'web_image_web.dart';

class CustomNetworkImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final String? itemName;
  final bool isGray;

  const CustomNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.itemName,
    this.isGray = false,
  });

  @override
  Widget build(BuildContext context) {
    final cleanUrl = imageUrl.trim();

    if (cleanUrl.isEmpty) {
      return _buildBlankPlaceholder();
    }

    if (kIsWeb) {
      return buildWebImage(cleanUrl, fit, isGray: isGray);
    }

    Widget imageWidget = Image.network(
      cleanUrl,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: const Color(0xFFF7F8F6),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return _buildBlankPlaceholder();
      },
    );

    if (isGray) {
      return ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0,      0,      0,      1, 0,
        ]),
        child: Opacity(
          opacity: 0.6,
          child: imageWidget,
        ),
      );
    }

    return imageWidget;
  }

  Widget _buildBlankPlaceholder() {
    return Container(
      color: const Color(0xFFF7F8F6),
    );
  }
}
