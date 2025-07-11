import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dayliz/core/services/order_service.dart';
import 'package:dayliz/core/errors/exceptions.dart';

// Generate mocks
@GenerateMocks([SupabaseClient, GoTrueClient, PostgrestQueryBuilder, PostgrestFilterBuilder])
import 'order_service_test.mocks.dart';

void main() {
  group('OrderService', () {
    late OrderService orderService;
    late MockSupabaseClient mockSupabaseClient;
    late MockGoTrueClient mockAuth;

    setUp(() {
      mockSupabaseClient = MockSupabaseClient();
      mockAuth = MockGoTrueClient();
      orderService = OrderService(supabaseClient: mockSupabaseClient);

      // Setup auth mock
      when(mockSupabaseClient.auth).thenReturn(mockAuth);
    });

    group('createOrder', () {
      test('should create order successfully when all data is valid', () async {
        // Arrange
        const userId = 'test-user-id';
        const deliveryAddressId = 'test-address-id';
        final mockUser = User(
          id: userId,
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: DateTime.now().toIso8601String(),
        );

        final orderItems = [
          {
            'product_id': 'product-1',
            'product_name': 'Test Product',
            'quantity': 2,
            'price': 10.0,
            'total': 20.0,
          }
        ];

        final mockOrderResponse = {
          'id': 'order-123',
          'user_id': userId,
          'total_amount': 25.0,
          'subtotal': 20.0,
          'tax': 3.6,
          'shipping': 1.4,
          'discount': 0.0,
          'final_amount': 25.0,
          'status': 'pending',
          'payment_method': 'cod',
          'payment_status': 'pending',
          'delivery_address_id': deliveryAddressId,
          'created_at': DateTime.now().toIso8601String(),
          'order_items': [
            {
              'id': 'item-1',
              'product_id': 'product-1',
              'product_name': 'Test Product',
              'quantity': 2,
              'product_price': 10.0,
              'total_price': 20.0,
            }
          ],
          'addresses': {
            'id': deliveryAddressId,
            'user_id': userId,
            'address_line1': '123 Test St',
            'city': 'Test City',
            'state': 'Test State',
            'postal_code': '12345',
            'country': 'Test Country',
            'label': 'Home',
            'is_default': true,
          },
          'payment_methods': {
            'id': 'payment-1',
            'user_id': userId,
            'type': 'cod',
            'name': 'Cash on Delivery',
            'is_default': true,
            'details': {},
          }
        };

        when(mockAuth.currentUser).thenReturn(mockUser);
        when(mockSupabaseClient.rpc('create_order_with_items', any))
            .thenAnswer((_) async => mockOrderResponse);

        // Act
        final result = await orderService.createOrder(
          userId: userId,
          items: orderItems,
          subtotal: 20.0,
          tax: 3.6,
          shipping: 1.4,
          total: 25.0,
          paymentMethod: 'cod',
          deliveryAddressId: deliveryAddressId,
        );

        // Assert
        expect(result.id, 'order-123');
        expect(result.userId, userId);
        expect(result.total, 25.0);
        expect(result.status, 'pending');
        expect(result.items.length, 1);
        expect(result.items.first.productName, 'Test Product');
        expect(result.shippingAddress.addressLine1, '123 Test St');
        expect(result.paymentMethod.type, 'cod');

        verify(mockSupabaseClient.rpc('create_order_with_items', {
          'order_data': {
            'user_id': userId,
            'total_amount': 25.0,
            'subtotal': 20.0,
            'tax': 3.6,
            'shipping': 1.4,
            'discount': 0.0,
            'final_amount': 25.0,
            'status': 'pending',
            'payment_method': 'cod',
            'payment_status': 'pending',
            'delivery_address_id': deliveryAddressId,
            'notes': null,
            'coupon_code': null,
            'created_at': any(named: 'created_at'),
          },
          'order_items': orderItems,
        })).called(1);
      });

      test('should throw ServerException when user is not authenticated', () async {
        // Arrange
        when(mockAuth.currentUser).thenReturn(null);

        // Act & Assert
        expect(
          () => orderService.createOrder(
            userId: 'test-user-id',
            items: [],
            subtotal: 0,
            tax: 0,
            shipping: 0,
            total: 0,
            paymentMethod: 'cod',
            deliveryAddressId: 'test-address-id',
          ),
          throwsA(isA<ServerException>()),
        );
      });

      test('should throw ServerException when items list is empty', () async {
        // Arrange
        const userId = 'test-user-id';
        final mockUser = User(
          id: userId,
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: DateTime.now().toIso8601String(),
        );

        when(mockAuth.currentUser).thenReturn(mockUser);

        // Act & Assert
        expect(
          () => orderService.createOrder(
            userId: userId,
            items: [], // Empty items
            subtotal: 0,
            tax: 0,
            shipping: 0,
            total: 0,
            paymentMethod: 'cod',
            deliveryAddressId: 'test-address-id',
          ),
          throwsA(isA<ServerException>()),
        );
      });

      test('should throw ServerException when total is zero or negative', () async {
        // Arrange
        const userId = 'test-user-id';
        final mockUser = User(
          id: userId,
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: DateTime.now().toIso8601String(),
        );

        when(mockAuth.currentUser).thenReturn(mockUser);

        // Act & Assert
        expect(
          () => orderService.createOrder(
            userId: userId,
            items: [{'product_id': 'test', 'quantity': 1}],
            subtotal: 0,
            tax: 0,
            shipping: 0,
            total: 0, // Invalid total
            paymentMethod: 'cod',
            deliveryAddressId: 'test-address-id',
          ),
          throwsA(isA<ServerException>()),
        );
      });
    });

    group('getOrderById', () {
      test('should return order when found', () async {
        // Arrange
        const orderId = 'test-order-id';
        final mockQueryBuilder = MockPostgrestQueryBuilder();
        final mockFilterBuilder = MockPostgrestFilterBuilder();

        final mockOrderData = {
          'id': orderId,
          'user_id': 'test-user-id',
          'total_amount': 25.0,
          'status': 'processing',
          'created_at': DateTime.now().toIso8601String(),
          'order_items': [],
          'addresses': {
            'id': 'address-1',
            'address_line1': '123 Test St',
            'city': 'Test City',
            'state': 'Test State',
            'postal_code': '12345',
            'country': 'Test Country',
          },
          'payment_methods': {
            'type': 'cod',
            'name': 'Cash on Delivery',
          }
        };

        when(mockSupabaseClient.from('orders')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.select(any)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('id', orderId)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.single()).thenAnswer((_) async => mockOrderData);

        // Act
        final result = await orderService.getOrderById(orderId);

        // Assert
        expect(result.id, orderId);
        expect(result.status, 'pending');
      });

      test('should throw NotFoundException when order not found', () async {
        // Arrange
        const orderId = 'non-existent-order';
        final mockQueryBuilder = MockPostgrestQueryBuilder();
        final mockFilterBuilder = MockPostgrestFilterBuilder();

        when(mockSupabaseClient.from('orders')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.select(any)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('id', orderId)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.single()).thenThrow(
          PostgrestException(message: 'Not found', code: 'PGRST116'),
        );

        // Act & Assert
        expect(
          () => orderService.getOrderById(orderId),
          throwsA(isA<NotFoundException>()),
        );
      });
    });
  });
}
