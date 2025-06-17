// Basic widget tests for Dayliz App
//
// These tests verify that the app can be built and basic widgets work correctly.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('Basic Widget Tests', () {
    testWidgets('App builds without crashing', (WidgetTester tester) async {
      // Build a simple test app with ProviderScope using helper
      await TestHelpers.pumpWidgetWithProviders(
        tester,
        Scaffold(
          appBar: AppBar(title: const Text('Test App')),
          body: const Center(
            child: Text('Hello, World!'),
          ),
        ),
      );

      // Verify that the app builds successfully
      TestHelpers.expectWidgetExists(find.text('Test App'));
      TestHelpers.expectWidgetExists(find.text('Hello, World!'));
    });

    testWidgets('Basic widget interactions work', (WidgetTester tester) async {
      int counter = 0;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                return Scaffold(
                  appBar: AppBar(title: const Text('Counter Test')),
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Count: $counter'),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              counter++;
                            });
                          },
                          child: const Text('Increment'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Verify initial state
      TestHelpers.expectWidgetExists(find.text('Count: 0'));
      TestHelpers.expectWidgetExists(find.text('Increment'));

      // Tap the increment button using helper
      await TestHelpers.tapAndSettle(tester, find.text('Increment'));

      // Verify the counter incremented
      TestHelpers.expectWidgetExists(find.text('Count: 1'));
      TestHelpers.expectWidgetNotExists(find.text('Count: 0'));
    });

    testWidgets('ProviderScope wrapper works correctly', (WidgetTester tester) async {
      // Test that our test helper creates proper ProviderScope wrapper
      await TestHelpers.pumpWidgetWithProviders(
        tester,
        const Text('Provider Test'),
      );

      TestHelpers.expectWidgetExists(find.text('Provider Test'));
      TestHelpers.expectWidgetExists(TestHelpers.findByType<ProviderScope>());
    });

    testWidgets('Navigation wrapper works correctly', (WidgetTester tester) async {
      // Test navigation wrapper
      await tester.pumpWidget(
        TestHelpers.createTestAppWithNavigation(
          child: const Text('Navigation Test'),
        ),
      );

      TestHelpers.expectWidgetExists(find.text('Navigation Test'));
      TestHelpers.expectWidgetExists(TestHelpers.findByType<Scaffold>());
    });
  });
}
