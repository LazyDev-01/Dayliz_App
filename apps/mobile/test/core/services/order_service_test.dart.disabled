import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dayliz_app/core/services/order_service.dart';
import 'package:dayliz_app/core/errors/exceptions.dart';

// Generate mocks
@GenerateMocks([SupabaseClient, GoTrueClient])
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
      test('should validate user authentication', () async {
        // Arrange
        when(mockAuth.currentUser).thenReturn(null);

        // Act & Assert
        expect(
          () => orderService.createOrder(
            userId: 'test-user-id',
            items: [{'product_id': 'test', 'quantity': 1}],
            subtotal: 10.0,
            tax: 1.0,
            shipping: 2.0,
            total: 13.0,
            paymentMethod: 'cod',
            deliveryAddressId: 'test-address-id',
          ),
          throwsA(isA<ServerException>()),
        );
      });

      test('should validate items list is not empty', () async {
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

      test('should validate total amount is positive', () async {
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
  });
}
