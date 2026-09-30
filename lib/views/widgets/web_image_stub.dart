import 'package:flutter/material.dart';

Widget buildWebImage(String url, BoxFit fit, {bool isGray = false}) {
  Widget img = Image.network(
    url,
    fit: fit,
    errorBuilder: (context, error, stackTrace) => const SizedBox(),
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
        child: img,
      ),
    );
  }

  return img;
}
