// ignore_for_file: deprecated_member_use
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

Widget buildWebImage(String url, BoxFit fit, {bool isGray = false}) {
  final String viewType = 'img-${url.hashCode}${isGray ? '-gray' : ''}';
  ui_web.platformViewRegistry.registerViewFactory(
    viewType,
    (int viewId) {
      final img = html.ImageElement()
        ..src = url
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.pointerEvents = 'none'
        ..style.objectFit = fit == BoxFit.cover ? 'cover' : 'contain';

      if (isGray) {
        img.style.filter = 'grayscale(100%) opacity(0.6)';
      }

      return img;
    },
  );
  Widget view = HtmlElementView(
    key: ValueKey(viewType),
    viewType: viewType,
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
        child: view,
      ),
    );
  }

  return view;
}
