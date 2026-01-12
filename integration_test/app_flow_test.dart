import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:mirmir_app/main.dart' as app;
import 'package:mirmir_app/features/home/presentation/pages/main_screen.dart';
import 'package:mirmir_app/features/home/presentation/widgets/custom_drawer.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Add vocabulary and start quiz flow',
    (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Wait for main screen
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // If login screen is present, push MainScreen directly for testing
      final loginText = find.text('Google ile Giriş Yap');
      if (loginText.evaluate().isNotEmpty) {
        await tester.runAsync(() async {
          Navigator.of(
            tester.element(find.byType(Scaffold)),
          ).push(MaterialPageRoute(builder: (_) => const MainScreen()));
        });
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }

      // Navigate to Vocabulary via the app bar icon (book_outlined)
      final vocabIcon = find.byIcon(Icons.book_outlined);
      // Ensure the icon exists and tap it
      expect(vocabIcon, findsOneWidget);
      await tester.tap(vocabIcon);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Wait for the input field with the expected hint to appear
      final wordFieldFinder = find.byWidgetPredicate((w) {
        return w is TextField &&
            w.decoration != null &&
            w.decoration!.hintText == 'Almanca kelime girin...';
      });

      int retries = 0;
      while (wordFieldFinder.evaluate().isEmpty && retries < 10) {
        await tester.pump(const Duration(milliseconds: 300));
        retries++;
      }

      expect(wordFieldFinder, findsOneWidget);
      await tester.enterText(wordFieldFinder, 'Haus');
      await tester.pumpAndSettle();

      // Press add button (icon add)
      final addButton = find.byIcon(Icons.add).first;
      await tester.tap(addButton);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Expect either snack or the list contains 'Haus'
      expect(find.textContaining('Haus'), findsWidgets);

      // Check that Turkish translation appears (either flag or translation text)
      final turkishFlagFinder = find.textContaining('🇹🇷');
      final turkishValueFinder = find.textContaining('Ev');
      expect(
        turkishFlagFinder.evaluate().isNotEmpty ||
            turkishValueFinder.evaluate().isNotEmpty,
        isTrue,
      );

      // Try to open quiz from app bar (icon quiz)
      final quizIcon = find.byIcon(Icons.quiz);
      if (quizIcon.evaluate().isNotEmpty) {
        await tester.tap(quizIcon);
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Two possible quiz screens: general adaptive quiz or vocabulary quiz
        if (find.text('Quiz Zamanı').evaluate().isNotEmpty) {
          expect(find.text('Quiz Zamanı'), findsOneWidget);
          expect(find.text('Soru yüklenemedi'), findsNothing);
        } else if (find.text('Kelime Quiz').evaluate().isNotEmpty) {
          expect(find.text('Kelime Quiz'), findsWidgets);

          // Start the vocabulary quiz
          final startButton = find.text('Quiz Başlat');
          expect(startButton, findsOneWidget);
          await tester.tap(startButton);
          await tester.pumpAndSettle(const Duration(seconds: 3));

          // Wait for a question to appear
          final questionFinder = find.textContaining('Bu kelimenin');
          final questionFinder2 = find.textContaining('Bu Türkçe kelimenin');
          expect(
            questionFinder.evaluate().isNotEmpty ||
                questionFinder2.evaluate().isNotEmpty,
            isTrue,
          );
        } else {
          // Unexpected UI - fail explicitly
          fail('Beklenmeyen quiz screen açıldı');
        }
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  testWidgets(
    'Drawer topic quiz button opens quiz',
    (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Wait for main screen
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // If login screen is present, push MainScreen directly for testing
      final loginText = find.text('Google ile Giriş Yap');
      if (loginText.evaluate().isNotEmpty) {
        await tester.runAsync(() async {
          Navigator.of(
            tester.element(find.byType(Scaffold)),
          ).push(MaterialPageRoute(builder: (_) => const MainScreen()));
        });
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }

      // Open drawer
      final menuIcon = find.byIcon(Icons.menu);
      expect(menuIcon, findsOneWidget);
      // Use center tap to avoid hit-test issues when icon is partially obscured
      final menuCenter = tester.getCenter(menuIcon.first);
      await tester.tapAt(menuCenter);
      await tester.pumpAndSettle();

      // Expand A1.1 level
      final levelFinder = find.text('A1.1');
      expect(levelFinder, findsWidgets);
      await tester.tap(levelFinder.first);
      await tester.pumpAndSettle();

      // Tap first topic's quiz button (school icon)
      final schoolIcon = find.byIcon(Icons.school_outlined);
      expect(schoolIcon, findsWidgets);
      final schoolCenter = tester.getCenter(schoolIcon.first);
      await tester.tapAt(schoolCenter);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Assert quiz screen opened (adaptive or vocabulary)
      final adaptive = find.text('Quiz Zamanı');
      final vocab = find.text('Kelime Quiz');
      expect(
        adaptive.evaluate().isNotEmpty || vocab.evaluate().isNotEmpty,
        isTrue,
      );
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  testWidgets(
    'Open quiz for first topic of each level',
    (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Bypass login if present
      final loginText = find.text('Google ile Giriş Yap');
      if (loginText.evaluate().isNotEmpty) {
        await tester.runAsync(() async {
          Navigator.of(
            tester.element(find.byType(Scaffold)),
          ).push(MaterialPageRoute(builder: (_) => const MainScreen()));
        });
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }

      // Open drawer
      final menuIcon = find.byIcon(Icons.menu);
      expect(menuIcon, findsOneWidget);
      final menuCenter = tester.getCenter(menuIcon.first);
      await tester.tapAt(menuCenter);
      await tester.pumpAndSettle();

      // Import curriculum data from app widgets
      // For each level (skip 'Genel') tap its expansion and press the first topic's quiz button
      final levels = CustomDrawer.curriculumData;

      for (final levelData in levels) {
        final level = levelData['level'] as String;
        if (level == 'Genel') continue; // skip general

        // Ensure the level is visible in drawer and expand it
        final levelFinder = find.text(level);
        // Try to make the level visible using a robust strategy:
        // 1) Prefer using tester.ensureVisible
        // 2) Fallback to scrollUntilVisible targeting drawer Scrollable if needed
        if (levelFinder.evaluate().isEmpty) {
          try {
            await tester.ensureVisible(levelFinder.first);
            await tester.pumpAndSettle();
          } catch (_) {
            final drawerScrollable = find.descendant(
              of: find.byType(Drawer),
              matching: find.byType(Scrollable),
            );
            if (drawerScrollable.evaluate().isNotEmpty) {
              await tester.scrollUntilVisible(
                levelFinder,
                200.0,
                scrollable: drawerScrollable.first,
              );
              await tester.pumpAndSettle();
            } else {
              // As a last resort, allow the UI to settle and retry
              await tester.pumpAndSettle(const Duration(milliseconds: 500));
            }
          }
        }
        expect(levelFinder, findsWidgets);
        await tester.tap(levelFinder.first);
        await tester.pumpAndSettle();

        // Tap the first topic's quiz button specifically for this level
        final topicTitle = (levelData['topics'] as List).first as String;

        // Locate the ListTile reliably: exact match, fallback to substring (before '('),
        // and as a last resort, scroll the drawer and retry
        Finder? topicTile;
        final allListTiles = find.byType(ListTile);
        for (final lt in allListTiles.evaluate()) {
          final ltWidget = lt.widget as ListTile;
          final tileFinder = find.byWidget(ltWidget);
          if (find
              .descendant(of: tileFinder, matching: find.text(topicTitle))
              .evaluate()
              .isNotEmpty) {
            topicTile = tileFinder;
            break;
          }
          final baseTitle = topicTitle.split('(').first.trim();
          if (baseTitle.isNotEmpty &&
              find
                  .descendant(
                    of: tileFinder,
                    matching: find.textContaining(baseTitle),
                  )
                  .evaluate()
                  .isNotEmpty) {
            topicTile = tileFinder;
            break;
          }
        }

        if (topicTile == null) {
          final drawerScrollable = find.descendant(
            of: find.byType(Drawer),
            matching: find.byType(Scrollable),
          );
          if (drawerScrollable.evaluate().isNotEmpty) {
            final key = topicTitle.split('(').first.trim();
            await tester.scrollUntilVisible(
              find.textContaining(key),
              200.0,
              scrollable: drawerScrollable.first,
            );
            await tester.pumpAndSettle();

            // Retry locating after scroll
            for (final lt in allListTiles.evaluate()) {
              final ltWidget = lt.widget as ListTile;
              final tileFinder = find.byWidget(ltWidget);
              if (find
                  .descendant(
                    of: tileFinder,
                    matching: find.textContaining(key),
                  )
                  .evaluate()
                  .isNotEmpty) {
                topicTile = tileFinder;
                break;
              }
            }
          } else {
            await tester.pumpAndSettle(const Duration(milliseconds: 500));
          }
        }

        expect(topicTile, isNotNull);
        final topicTileFinder = topicTile!;

        // Prefer tapping the IconButton specifically inside the tile (more reliable),
        // falling back to positional icon matching when needed.
        Finder? schoolButton;
        bool foundIcon = false;

        final allIconButtons = find.descendant(
          of: topicTileFinder,
          matching: find.byType(IconButton),
        );

        for (final btn in allIconButtons.evaluate()) {
          final widget = btn.widget;
          if (widget is IconButton && widget.icon is Icon) {
            final iconWidget = widget.icon as Icon;
            if (iconWidget.icon == Icons.school_outlined) {
              schoolButton = find.byWidget(widget);
              foundIcon = true;
              break;
            }
          }
        }

        if (!foundIcon) {
          // Positional fallback: find Icons and pick the one nearest to tile
          final allIcons = find.byIcon(Icons.school_outlined);
          final tileRect = tester.getRect(topicTileFinder);
          for (final iconEl in allIcons.evaluate()) {
            final iconFinder = find.byWidget(iconEl.widget);
            final renderBox = iconEl.renderObject as RenderBox;
            final iconCenter = renderBox.localToGlobal(
              renderBox.size.center(Offset.zero),
            );
            // Check vertical overlap and prefer icons to the right side of the tile
            if (iconCenter.dy >= tileRect.top - 2 &&
                iconCenter.dy <= tileRect.bottom + 2) {
              if (iconCenter.dx >= tileRect.right - 1) {
                schoolButton = iconFinder;
                foundIcon = true;
                break;
              } else {
                // keep as a fallback if we don't find a trailing icon
                schoolButton ??= iconFinder;
              }
            }
          }
        }

        if (!foundIcon && schoolButton == null) {
          // Final fallback: scoped descendant search for any matching icon
          schoolButton = find.descendant(
            of: topicTileFinder,
            matching: find.byIcon(Icons.school_outlined),
          );
        }

        expect(schoolButton, isNotNull);
        expect(schoolButton!, findsWidgets);

        // Choose a specific matching element when multiple matches exist by
        // preferring the one nearest to the tile's right edge.
        final matches = schoolButton!.evaluate();
        expect(matches, isNotEmpty);
        Element chosenEl = matches.first;
        if (matches.length > 1) {
          final tileRect = tester.getRect(topicTileFinder);
          double bestDist = double.infinity;
          for (final el in matches) {
            final rb = el.renderObject as RenderBox;
            final c = rb.localToGlobal(rb.size.center(Offset.zero));
            final dist = (c.dx - tileRect.right).abs();
            if (dist < bestDist) {
              bestDist = dist;
              chosenEl = el;
            }
          }
        }

        final rbTarget = chosenEl.renderObject as RenderBox;
        final schoolCenter = rbTarget.localToGlobal(
          rbTarget.size.center(Offset.zero),
        );

        // First try to directly invoke the IconButton's onPressed if available
        bool invoked = false;
        final btnFinder = find.descendant(
          of: topicTileFinder,
          matching: find.byType(IconButton),
        );
        for (final b in btnFinder.evaluate()) {
          final widget = b.widget;
          if (widget is IconButton && widget.icon is Icon) {
            final iconWidget = widget.icon as Icon;
            if (iconWidget.icon == Icons.school_outlined) {
              if (widget.onPressed != null) {
                widget.onPressed!();
                await tester.pumpAndSettle(const Duration(seconds: 2));
                invoked = true;
                break;
              }
            }
          }
        }

        if (!invoked) {
          await tester.tapAt(schoolCenter);
          await tester.pumpAndSettle(const Duration(seconds: 2));
        }

        // Assert quiz screen opened (adaptive or vocabulary)
        final adaptive = find.text('Quiz Zamanı');
        final vocab = find.text('Kelime Quiz');
        bool opened =
            adaptive.evaluate().isNotEmpty || vocab.evaluate().isNotEmpty;
        if (!opened) {
          // Retry: tap the topic tile (in case icon didn't trigger navigation) and retry tapping the quiz button
          print(
            'Retrying: level=$level topic=$topicTitle, schoolButtonCount=${schoolButton.evaluate().length}',
          );
          final tileCenter = tester.getCenter(topicTileFinder);
          await tester.tapAt(tileCenter);
          await tester.pumpAndSettle(const Duration(seconds: 1));

          Finder sb2;
          try {
            sb2 = find.descendant(
              of: topicTileFinder,
              matching: find.byIcon(Icons.school_outlined),
            );
          } catch (_) {
            // If topic tile is not available (UI changed), fallback to any school icon on screen
            sb2 = find.byIcon(Icons.school_outlined);
          }

          bool sb2Has = false;
          try {
            sb2Has = sb2.evaluate().isNotEmpty;
          } catch (_) {
            sb2Has = false;
          }

          if (sb2Has) {
            final sb2Center = tester.getCenter(sb2.first);
            await tester.tapAt(sb2Center);
            await tester.pumpAndSettle(const Duration(seconds: 2));
          }

          opened =
              adaptive.evaluate().isNotEmpty || vocab.evaluate().isNotEmpty;
        }

        if (!opened) {
          // Provide debug info and fail with context
          final topicCount = topicTile.evaluate().length;
          final sbCount = schoolButton.evaluate().length;
          print(
            'ERROR: Could not open quiz for level=$level topic=$topicTitle; topicMatches=$topicCount, schoolButtonMatches=$sbCount',
          );
        }
        expect(opened, isTrue);

        // Navigate back to main screen and re-open drawer for next level
        final backButton = find.byIcon(Icons.arrow_back);
        if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton.first);
        } else {
          await tester.pageBack();
        }
        await tester.pumpAndSettle();
        await tester.tapAt(menuCenter);
        await tester.pumpAndSettle();
      }
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
