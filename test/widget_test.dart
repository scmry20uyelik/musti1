// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mirmir_app/features/home/presentation/pages/main_screen.dart';
import 'package:flutter/material.dart';


void main() {
  testWidgets('App starts with main screen', (WidgetTester tester) async {
    // Build main screen directly to avoid external dependencies
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: MainScreen())));

    // Verify that main screen is shown (contains the welcome text)
    expect(
      find.byWidgetPredicate((widget) =>
          widget is Text && (widget.data ?? '').contains('Almanca öğrenmeye başlayın!')),
      findsOneWidget,
    );
  });
}
