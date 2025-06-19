import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../lib/presentation/widgets/product/enhanced_add_to_cart_button.dart';

void main() {
  group('EnhancedAddToCartButton Widget Tests', () {
    testWidgets('should display ADD text when not in cart', (WidgetTester tester) async {
      bool wasPressed = false;

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          child: MaterialApp(
            home: Scaffold(
              body: EnhancedAddToCartButton(
                onPressed: () => wasPressed = true,
                isInCart: false,
                addText: 'ADD',
              ),
            ),
          ),
        ),
      );

      // Should find ADD text
      expect(find.text('ADD'), findsOneWidget);
      expect(find.text('ADDED'), findsNothing);

      // Test button press
      await tester.tap(find.byType(EnhancedAddToCartButton));
      expect(wasPressed, isTrue);
    });

    testWidgets('should display ADDED text when in cart', (WidgetTester tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          child: MaterialApp(
            home: Scaffold(
              body: EnhancedAddToCartButton(
                onPressed: () {},
                isInCart: true,
                addText: 'ADD',
                inCartText: 'ADDED',
              ),
            ),
          ),
        ),
      );

      // Should find ADDED text
      expect(find.text('ADDED'), findsOneWidget);
      expect(find.text('ADD'), findsNothing);
    });

    testWidgets('should show quantity controls when enabled', (WidgetTester tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          child: MaterialApp(
            home: Scaffold(
              body: EnhancedAddToCartButton(
                onPressed: () {},
                isInCart: true,
                quantity: 2,
                showQuantityControls: true,
                onIncrease: () {},
                onDecrease: () {},
              ),
            ),
          ),
        ),
      );

      // Should find quantity controls
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.remove), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('should show loading indicator when loading', (WidgetTester tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          child: MaterialApp(
            home: Scaffold(
              body: EnhancedAddToCartButton(
                onPressed: () {},
                isLoading: true,
              ),
            ),
          ),
        ),
      );

      // Should find loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should handle compact mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          child: MaterialApp(
            home: Scaffold(
              body: EnhancedAddToCartButton(
                onPressed: () {},
                isCompact: true,
                addText: 'ADD',
              ),
            ),
          ),
        ),
      );

      // Should find the button in compact mode
      expect(find.text('ADD'), findsOneWidget);
      
      // Button should be smaller in compact mode
      final button = tester.widget<EnhancedAddToCartButton>(
        find.byType(EnhancedAddToCartButton),
      );
      expect(button.isCompact, isTrue);
    });
  });
}
