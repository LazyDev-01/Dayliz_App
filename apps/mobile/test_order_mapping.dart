import 'package:flutter_test/flutter_test.dart';
import 'lib/core/services/order_service.dart';
import 'lib/domain/entities/order.dart';

void main() {
  group('OrderService Mapping Tests', () {
    test('should handle null order_number without throwing error', () {
      // Arrange
      final orderService = OrderService();
      final mockData = {
        'id': 'test-id',
        'user_id': 'test-user-id',
        'order_number': null, // This was causing the error
        'status': 'processing',
        'subtotal': 100.0,
        'tax': 10.0,
        'shipping': 5.0,
        'total_amount': 115.0,
        'final_amount': 115.0,
        'created_at': '2025-07-01T15:10:42.002645+00:00',
        'order_items': [],
        'addresses': {
          'id': 'addr-id',
          'user_id': 'test-user-id',
          'address_line1': 'Test Address',
          'address_line2': null, // This was also causing issues
          'city': 'Test City',
          'state': 'Test State',
          'postal_code': '12345',
          'country': 'India',
          'label': 'Home',
          'is_default': true,
        },
        'payment_methods': {
          'id': 'pm-id',
          'user_id': 'test-user-id',
          'type': 'cod',
          'name': 'Cash on Delivery',
          'is_default': true,
          'details': {},
        },
      };

      // Act & Assert
      expect(() {
        // This should not throw an error anymore
        final order = orderService._mapDatabaseOrderToEntity(mockData);
        expect(order.orderNumber, isNull);
        expect(order.shippingAddress.addressLine2, equals(''));
      }, returnsNormally);
    });

    test('should handle null address_line2 without throwing error', () {
      // Arrange
      final orderService = OrderService();
      final mockData = {
        'id': 'test-id',
        'user_id': 'test-user-id',
        'order_number': 'DLZ-20250701-0001',
        'status': 'pending',
        'subtotal': 100.0,
        'tax': 10.0,
        'shipping': 5.0,
        'total_amount': 115.0,
        'final_amount': 115.0,
        'created_at': '2025-07-01T15:10:42.002645+00:00',
        'order_items': [],
        'addresses': {
          'id': 'addr-id',
          'user_id': 'test-user-id',
          'address_line1': 'Test Address',
          'address_line2': null, // Null value
          'city': 'Test City',
          'state': 'Test State',
          'postal_code': '12345',
          'country': 'India',
          'label': 'Home',
          'is_default': true,
        },
        'payment_methods': {
          'id': 'pm-id',
          'user_id': 'test-user-id',
          'type': 'cod',
          'name': 'Cash on Delivery',
          'is_default': true,
          'details': {},
        },
      };

      // Act & Assert
      expect(() {
        final order = orderService._mapDatabaseOrderToEntity(mockData);
        expect(order.shippingAddress.addressLine2, equals(''));
      }, returnsNormally);
    });
  });
}
