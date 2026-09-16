import 'package:flutter/material.dart';

Widget buildWebImage(String url, BoxFit fit) {
  return Image.network(
    url,
    fit: fit,
    errorBuilder: (context, error, stackTrace) => const SizedBox(),
  );
}
