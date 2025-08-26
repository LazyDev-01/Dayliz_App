import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/presentation/widgets/animations/animated_add_to_cart.dart';

void main() {
  group('AnimatedAddToCartButton Widget Tests', () {
    testWidgets('should display button with default text', (WidgetTester tester) async {
      bool wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedAddToCartButton(
              onAddToCart: () => wasPressed = true,
            ),
          ),
        ),
      );

      // Should find default text
      expect(find.text('Add to Cart'), findsOneWidget);

      // Test button press
      await tester.tap(find.byType(AnimatedAddToCartButton));
      expect(wasPressed, isTrue);
    });

    testWidgets('should display custom button text', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedAddToCartButton(
              onAddToCart: () {},
              buttonText: 'ADD TO CART',
            ),
          ),
        ),
      );

      // Should find custom text
      expect(find.text('ADD TO CART'), findsOneWidget);
      expect(find.text('Add to Cart'), findsNothing);
    });

    testWidgets('should show loading indicator when loading', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedAddToCartButton(
              onAddToCart: () {},
              isLoading: true,
            ),
          ),
        ),
      );

      // Should find loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should be disabled when isDisabled is true', (WidgetTester tester) async {
      bool wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedAddToCartButton(
              onAddToCart: () => wasPressed = true,
              isDisabled: true,
            ),
          ),
        ),
      );

      // Try to tap the button
      await tester.tap(find.byType(AnimatedAddToCartButton));
      
      // Should not have been pressed since it's disabled
      expect(wasPressed, isFalse);
    });

    testWidgets('should have custom size when specified', (WidgetTester tester) async {
      const customSize = Size(150, 50);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedAddToCartButton(
              onAddToCart: () {},
              size: customSize,
            ),
          ),
        ),
      );

      // Find the button container and check its size
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(AnimatedAddToCartButton),
          matching: find.byType(Container),
        ).first,
      );

      expect(container.constraints?.maxWidth, customSize.width);
      expect(container.constraints?.maxHeight, customSize.height);
    });

    testWidgets('should not respond to tap when loading', (WidgetTester tester) async {
      bool wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedAddToCartButton(
              onAddToCart: () => wasPressed = true,
              isLoading: true,
            ),
          ),
        ),
      );

      // Try to tap the button while loading
      await tester.tap(find.byType(AnimatedAddToCartButton));
      
      // Should not have been pressed since it's loading
      expect(wasPressed, isFalse);
    });
  });

  group('FloatingAddToCartButton Widget Tests', () {
    testWidgets('should display button when visible', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingAddToCartButton(
              onPressed: () {},
              isVisible: true,
            ),
          ),
        ),
      );

      // Should find the floating button
      expect(find.byType(FloatingAddToCartButton), findsOneWidget);
    });

    testWidgets('should show item count badge when itemCount > 0', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingAddToCartButton(
              onPressed: () {},
              itemCount: 5,
            ),
          ),
        ),
      );

      // Should find the item count
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('should show loading indicator when loading', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingAddToCartButton(
              onPressed: () {},
              isLoading: true,
            ),
          ),
        ),
      );

      // Should find loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
