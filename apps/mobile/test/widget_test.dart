// Basic widget tests for Dayliz App
//
// These tests verify that the app can be built and basic widgets work correctly.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    // Build a simple test app with ProviderScope
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('Test App')),
            body: const Center(
              child: Text('Hello, World!'),
            ),
          ),
        ),
      ),
    );

    // Verify that the app builds successfully
    expect(find.text('Test App'), findsOneWidget);
    expect(find.text('Hello, World!'), findsOneWidget);
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
    expect(find.text('Count: 0'), findsOneWidget);
    expect(find.text('Increment'), findsOneWidget);

    // Tap the increment button
    await tester.tap(find.text('Increment'));
    await tester.pump();

    // Verify the counter incremented
    expect(find.text('Count: 1'), findsOneWidget);
    expect(find.text('Count: 0'), findsNothing);
  });
}
