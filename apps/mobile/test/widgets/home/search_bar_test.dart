import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/presentation/widgets/home/search_bar.dart';

void main() {
  group('SearchBarWidget', () {
    late TextEditingController controller;
    late List<String> suggestions;
    late List<String> searchResults;

    setUp(() {
      controller = TextEditingController();
      suggestions = ['apple', 'banana', 'orange', 'grape'];
      searchResults = [];
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('should display search bar with hint text', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              controller: controller,
              suggestions: suggestions,
              onSearch: (query) => searchResults.add(query),
              hintText: 'Search products...',
            ),
          ),
        ),
      );

      // Verify that the hint text is displayed
      expect(find.text('Search products...'), findsOneWidget);
      
      // Verify that the search icon is present
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('should show clear button when text is entered', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              controller: controller,
              suggestions: suggestions,
              onSearch: (query) => searchResults.add(query),
            ),
          ),
        ),
      );

      // Initially, clear button should not be visible
      expect(find.byIcon(Icons.clear), findsNothing);

      // Enter text in the search field
      await tester.enterText(find.byType(TextField), 'apple');
      await tester.pump();

      // Clear button should now be visible
      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    testWidgets('should clear text when clear button is pressed', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              controller: controller,
              suggestions: suggestions,
              onSearch: (query) => searchResults.add(query),
            ),
          ),
        ),
      );

      // Enter text in the search field
      await tester.enterText(find.byType(TextField), 'apple');
      await tester.pump();

      // Verify text is entered
      expect(controller.text, 'apple');

      // Tap the clear button
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      // Verify text is cleared
      expect(controller.text, '');
      expect(find.byIcon(Icons.clear), findsNothing);
    });

    testWidgets('should show suggestions when text is entered', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              controller: controller,
              suggestions: suggestions,
              onSearch: (query) => searchResults.add(query),
            ),
          ),
        ),
      );

      // Enter text to trigger suggestions
      await tester.enterText(find.byType(TextField), 'a');
      await tester.pump();

      // Verify that suggestions are shown
      expect(find.text('apple'), findsOneWidget);
    });

    testWidgets('should call onSearch when suggestion is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              controller: controller,
              suggestions: suggestions,
              onSearch: (query) => searchResults.add(query),
            ),
          ),
        ),
      );

      // Enter text to show suggestions
      await tester.enterText(find.byType(TextField), 'a');
      await tester.pump();

      // Tap on a suggestion
      await tester.tap(find.text('apple'));
      await tester.pump();

      // Verify that onSearch was called with the suggestion
      expect(searchResults, contains('apple'));
      expect(controller.text, 'apple');
    });

    testWidgets('should show all suggestions when text is entered', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              controller: controller,
              suggestions: suggestions,
              onSearch: (query) => searchResults.add(query),
            ),
          ),
        ),
      );

      // Enter text to show suggestions
      await tester.enterText(find.byType(TextField), 'ap');
      await tester.pump();

      // Should show all suggestions (widget doesn't filter)
      expect(find.text('apple'), findsOneWidget);
      expect(find.text('banana'), findsOneWidget);
      expect(find.text('orange'), findsOneWidget);
      expect(find.text('grape'), findsOneWidget);
    });

    testWidgets('should handle empty suggestions list', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              controller: controller,
              suggestions: [], // Empty suggestions
              onSearch: (query) => searchResults.add(query),
            ),
          ),
        ),
      );

      // Enter text
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();

      // Should not crash and should not show any suggestions
      expect(find.text('test'), findsOneWidget); // Only the input text
    });

    testWidgets('should use custom hint text', (WidgetTester tester) async {
      const customHint = 'Find your favorite items...';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              controller: controller,
              suggestions: suggestions,
              onSearch: (query) => searchResults.add(query),
              hintText: customHint,
            ),
          ),
        ),
      );

      // Verify custom hint text is displayed
      expect(find.text(customHint), findsOneWidget);
      expect(find.text('Search products...'), findsNothing);
    });
  });
}
