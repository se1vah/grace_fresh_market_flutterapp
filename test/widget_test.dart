import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:grace_fresh_market/main.dart';

class TestHttpOverrides extends HttpOverrides {}

void main() {
  setUpAll(() {
    HttpOverrides.global = TestHttpOverrides();
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const GraceFreshMarketApp());
    await tester.pumpAndSettle();
    expect(find.text('Grace Fresh Market'), findsWidgets);
  });
}
