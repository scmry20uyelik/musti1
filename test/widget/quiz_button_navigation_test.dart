import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mirmir_app/features/quiz/presentation/pages/quiz_screen.dart';

class _SpyNavigatorObserver extends NavigatorObserver {
  final List<Route<dynamic>> pushed = [];

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    pushed.add(route);
  }
}

void main() {
  testWidgets('Quiz button list tile triggers navigation to QuizScreen', (WidgetTester tester) async {
    final observer = _SpyNavigatorObserver();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: ListTile(
            title: const Text('Test topic'),
            trailing: IconButton(
              tooltip: 'Test',
              icon: const Icon(Icons.school_outlined),
              onPressed: () {
                Navigator.of(tester.element(find.byType(ListTile))).push(
                  MaterialPageRoute(
                    builder: (context) => const QuizScreen(levelName: 'A1', topicName: 'Test topic'),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      navigatorObservers: [observer],
    ));

    expect(find.byTooltip('Test'), findsOneWidget);
    await tester.tap(find.byTooltip('Test'));
    await tester.pumpAndSettle();

    expect(observer.pushed.isNotEmpty, isTrue);
    expect(find.text('Quiz Zamanı'), findsOneWidget);
  });
}
