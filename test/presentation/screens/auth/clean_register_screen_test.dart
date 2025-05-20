import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Basic widget test', (WidgetTester tester) async {
    // Create a simple widget for testing
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Hello, World!'),
          ),
        ),
      ),
    );

    // assert
    expect(find.text('Hello, World!'), findsOneWidget);
  });
}
