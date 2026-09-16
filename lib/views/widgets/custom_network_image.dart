import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'web_image_stub.dart' if (dart.library.html) 'web_image_web.dart';

class CustomNetworkImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final String? itemName;

  const CustomNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.itemName,
  });

  @override
  Widget build(BuildContext context) {
    final cleanUrl = imageUrl.trim();

    if (cleanUrl.isEmpty) {
      return _buildBlankPlaceholder();
    }

    if (kIsWeb) {
      return buildWebImage(cleanUrl, fit);
    }

    return Image.network(
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
  }

  Widget _buildBlankPlaceholder() {
    return Container(
      color: const Color(0xFFF7F8F6),
    );
  }
}
