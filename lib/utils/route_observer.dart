import 'package:flutter/material.dart';

/// Global RouteObserver to detect route navigation, pushes, and pops across the app.
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();
