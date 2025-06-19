import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../lib/presentation/widgets/common/floating_cart_button.dart';
import '../../lib/presentation/providers/cart_providers.dart';

void main() {
  group('FloatingCartButton Widget Tests', () {
    testWidgets('should not show when cart is empty', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            child: MaterialApp(
              home: Scaffold(
                body: Stack(
                  children: const [
                    FloatingCartButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      // Should not find the floating cart button when cart is empty
      expect(find.byType(FloatingCartButton), findsOneWidget);
      expect(find.text('Cart'), findsNothing);
    });

    testWidgets('should show when forceShow is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            child: MaterialApp(
              home: Scaffold(
                body: Stack(
                  children: const [
                    FloatingCartButton(forceShow: true),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should find the floating cart button when forceShow is true
      expect(find.text('Cart'), findsOneWidget);
    });

    testWidgets('should have proper positioning', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            child: MaterialApp(
              home: Scaffold(
                body: Stack(
                  children: const [
                    FloatingCartButton(
                      forceShow: true,
                      bottomPosition: 30,
                      rightPosition: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should find positioned widget
      expect(find.byType(Positioned), findsOneWidget);
    });
  });
}
