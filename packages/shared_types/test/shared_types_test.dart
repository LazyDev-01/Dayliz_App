import 'package:flutter_test/flutter_test.dart';
import 'package:shared_types/shared_types.dart';

void main() {
  group('AgentModel Tests', () {
    test('should create AgentModel from JSON', () {
      final json = {
        'id': 'agent-1',
        'user_id': 'user-1',
        'agent_id': 'AG001',
        'full_name': 'John Doe',
        'phone': '+919876543210',
        'email': 'john@example.com',
        'assigned_zone': 'Zone A',
        'status': 'active',
        'total_deliveries': 10,
        'total_earnings': 1500.0,
        'join_date': '2024-01-01T00:00:00.000Z',
        'is_verified': true,
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-01T00:00:00.000Z',
      };

      final agent = AgentModel.fromJson(json);

      expect(agent.id, 'agent-1');
      expect(agent.agentId, 'AG001');
      expect(agent.fullName, 'John Doe');
      expect(agent.status, AgentStatus.active);
      expect(agent.totalDeliveries, 10);
      expect(agent.isVerified, true);
    });
  });

  group('AgentOrderModel Tests', () {
    test('should create AgentOrderModel from JSON', () {
      final json = {
        'id': 'order-1',
        'order_id': 'ORD001',
        'agent_id': 'agent-1',
        'customer_name': 'Jane Smith',
        'customer_phone': '+919876543211',
        'delivery_address': {
          'street': '123 Main St',
          'city': 'Mumbai',
          'state': 'Maharashtra',
          'pincode': '400001',
          'landmark': 'Near Station',
          'latitude': 19.0760,
          'longitude': 72.8777,
        },
        'order_items': [
          {
            'product_id': 'prod-1',
            'product_name': 'Rice 1kg',
            'quantity': 2,
            'price': 50.0,
            'image_url': 'https://example.com/rice.jpg',
          }
        ],
        'total_amount': 100.0,
        'delivery_fee': 20.0,
        'status': 'assigned',
        'assigned_at': '2024-01-01T00:00:00.000Z',
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-01T00:00:00.000Z',
      };

      final order = AgentOrderModel.fromJson(json);

      expect(order.id, 'order-1');
      expect(order.orderId, 'ORD001');
      expect(order.customerName, 'Jane Smith');
      expect(order.status, OrderStatus.assigned);
      expect(order.totalAmount, 100.0);
      expect(order.deliveryFee, 20.0);
      expect(order.orderItems.length, 1);
      expect(order.orderItems.first.productName, 'Rice 1kg');
    });
  });
}
