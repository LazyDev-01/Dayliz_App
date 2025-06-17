import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Test helpers for Dayliz App testing
class TestHelpers {
  /// Creates a test app wrapper with ProviderScope for Riverpod testing
  static Widget createTestApp({
    required Widget child,
    List<Override>? overrides,
  }) {
    return ProviderScope(
      overrides: overrides ?? [],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  /// Creates a test app wrapper with navigation support
  static Widget createTestAppWithNavigation({
    required Widget child,
    List<Override>? overrides,
  }) {
    return ProviderScope(
      overrides: overrides ?? [],
      child: MaterialApp(
        home: Scaffold(body: child),
      ),
    );
  }

  /// Pumps a widget with ProviderScope wrapper
  static Future<void> pumpWidgetWithProviders(
    WidgetTester tester,
    Widget widget, {
    List<Override>? overrides,
  }) async {
    await tester.pumpWidget(
      createTestApp(
        child: widget,
        overrides: overrides,
      ),
    );
  }

  /// Common test setup for screens that require authentication
  static List<Override> createAuthenticatedOverrides() {
    // TODO: Add actual provider overrides for authenticated state
    return [];
  }

  /// Common test setup for screens that require cart data
  static List<Override> createCartOverrides() {
    // TODO: Add actual provider overrides for cart state
    return [];
  }

  /// Waits for all animations and async operations to complete
  static Future<void> waitForAnimations(WidgetTester tester) async {
    await tester.pumpAndSettle();
  }

  /// Finds a widget by its key
  static Finder findByKey(String key) {
    return find.byKey(Key(key));
  }

  /// Finds a widget by its text content
  static Finder findByText(String text) {
    return find.text(text);
  }

  /// Finds a widget by its type
  static Finder findByType<T extends Widget>() {
    return find.byType(T);
  }

  /// Taps a widget and waits for animations
  static Future<void> tapAndSettle(
    WidgetTester tester,
    Finder finder,
  ) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Enters text in a text field and waits for animations
  static Future<void> enterTextAndSettle(
    WidgetTester tester,
    Finder finder,
    String text,
  ) async {
    await tester.enterText(finder, text);
    await tester.pumpAndSettle();
  }

  /// Scrolls to a widget and waits for animations
  static Future<void> scrollToAndSettle(
    WidgetTester tester,
    Finder finder,
  ) async {
    await tester.scrollUntilVisible(finder, 100);
    await tester.pumpAndSettle();
  }

  /// Verifies that a widget exists
  static void expectWidgetExists(Finder finder) {
    expect(finder, findsOneWidget);
  }

  /// Verifies that a widget does not exist
  static void expectWidgetNotExists(Finder finder) {
    expect(finder, findsNothing);
  }

  /// Verifies that multiple widgets exist
  static void expectWidgetsExist(Finder finder, int count) {
    expect(finder, findsNWidgets(count));
  }
}

/// Mock data helpers for testing
class MockDataHelpers {
  /// Creates mock product data for testing
  static Map<String, dynamic> createMockProduct({
    String? id,
    String? name,
    double? price,
    String? imageUrl,
  }) {
    return {
      'id': id ?? 'test_product_1',
      'name': name ?? 'Test Product',
      'price': price ?? 99.99,
      'image_url': imageUrl ?? 'https://example.com/image.jpg',
      'description': 'Test product description',
      'category_id': 'test_category',
      'subcategory_id': 'test_subcategory',
      'is_available': true,
      'stock_quantity': 10,
    };
  }

  /// Creates mock user data for testing
  static Map<String, dynamic> createMockUser({
    String? id,
    String? email,
    String? name,
  }) {
    return {
      'id': id ?? 'test_user_1',
      'email': email ?? 'test@example.com',
      'name': name ?? 'Test User',
      'phone': '+1234567890',
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  /// Creates mock address data for testing
  static Map<String, dynamic> createMockAddress({
    String? id,
    String? title,
    String? address,
  }) {
    return {
      'id': id ?? 'test_address_1',
      'title': title ?? 'Home',
      'address_line_1': address ?? '123 Test Street',
      'address_line_2': 'Apt 4B',
      'city': 'Test City',
      'state': 'Test State',
      'postal_code': '12345',
      'country': 'Test Country',
      'latitude': 26.1445,
      'longitude': 91.7362,
      'is_default': true,
    };
  }

  /// Creates mock cart item data for testing
  static Map<String, dynamic> createMockCartItem({
    String? productId,
    int? quantity,
  }) {
    return {
      'product_id': productId ?? 'test_product_1',
      'quantity': quantity ?? 1,
      'product': createMockProduct(id: productId),
    };
  }
}
