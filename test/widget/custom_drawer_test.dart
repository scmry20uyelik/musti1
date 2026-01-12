import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mirmir_app/features/home/presentation/widgets/custom_drawer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _SpyNavigatorObserver extends NavigatorObserver {
  final List<Route<dynamic>> pushed = [];

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    pushed.add(route);
  }
}

void main() {
  testWidgets('Drawer Test button navigates to QuizScreen', (WidgetTester tester) async {
    final observer = _SpyNavigatorObserver();

    // Make the test window larger to avoid Drawer overflow
    tester.binding.window.physicalSizeTestValue = const Size(800, 1200);
    tester.binding.window.devicePixelRatioTestValue = 1.0;
    addTearDown(() {
      tester.binding.window.clearPhysicalSizeTestValue();
      tester.binding.window.clearDevicePixelRatioTestValue();
    });

    // Reduce curriculum data to a small test dataset to avoid layout overflow
    CustomDrawer.curriculumData.clear();
    CustomDrawer.curriculumData.add({'level': 'A1', 'topics': ['Kısa']});

    await tester.pumpWidget(ProviderScope(
      child: MediaQuery(
        data: const MediaQueryData(textScaleFactor: 0.8),
        child: MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('Home')),
            // Place the drawer directly in the body with wide width to avoid Drawer width clipping in tests
            body: SizedBox(
              width: 800,
              child: const CustomDrawer(),
            ),
          ),
          navigatorObservers: [observer],
        ),
      ),
    ));

    // Expand the first level to reveal the topic/test button
    await tester.tap(find.widgetWithText(ExpansionTile, 'A1').first);
    await tester.pumpAndSettle();

    // Find a topic's Test icon (first occurrence) and tap it
    final testIcon = find.byTooltip('Test').first;
    expect(testIcon, findsOneWidget);

    await tester.tap(testIcon);
    await tester.pumpAndSettle();

    // Should have pushed a new route (QuizScreen)
    expect(observer.pushed.isNotEmpty, isTrue);

    // Basic smoke check: QuizScreen app bar title exists
    expect(find.text('Quiz Zamanı'), findsOneWidget);
  });
}
