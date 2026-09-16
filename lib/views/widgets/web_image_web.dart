// ignore_for_file: deprecated_member_use
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

Widget buildWebImage(String url, BoxFit fit) {
  final String viewType = 'img-${url.hashCode}';
  ui_web.platformViewRegistry.registerViewFactory(
    viewType,
    (int viewId) {
      final img = html.ImageElement()
        ..src = url
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.pointerEvents = 'none'
        ..style.objectFit = fit == BoxFit.cover ? 'cover' : 'contain';
      return img;
    },
  );
  return HtmlElementView(
    key: ValueKey(url),
    viewType: viewType,
  );
}
