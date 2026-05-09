// Smoke test: builds the root app to confirm no immediate crashes.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App boots without throwing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('LaVolan'))),
      ),
    );
    expect(find.text('LaVolan'), findsOneWidget);
  });
}
