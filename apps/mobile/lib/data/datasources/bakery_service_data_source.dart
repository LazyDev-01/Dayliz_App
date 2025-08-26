import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import '../../core/error/exceptions.dart';
import '../models/bakery_service_model.dart';
import '../../domain/entities/bakery_service.dart';

/// Abstract class defining bakery service data source contract
abstract class BakeryServiceDataSource {
  Future<List<BakeryServiceModel>> getBakeryServices();
  Future<BakeryServiceModel> getBakeryServiceById(String id);
  Future<BakeryOrderModel> createBakeryOrder(BakeryOrderModel order);
  Future<BakeryOrderModel> updateBakeryOrder(BakeryOrderModel order);
  Future<List<BakeryOrderModel>> getUserBakeryOrders(String userId);
  Future<BakeryOrderModel> getBakeryOrderById(String id);
  Future<double> calculateBakeryPrice(String serviceId, BakeryOrderSpecifications specifications);
  Future<List<BakeryVendorModel>> getAvailableBakeryVendors(String area);
  Future<String> uploadDesignImage(String filePath);
}

/// Supabase implementation of bakery service data source
class BakeryServiceSupabaseDataSource implements BakeryServiceDataSource {
  final SupabaseClient supabaseClient;

  BakeryServiceSupabaseDataSource({required this.supabaseClient});

  @override
  Future<List<BakeryServiceModel>> getBakeryServices() async {
    try {
      debugPrint('🎂 BAKERY: Fetching bakery services...');
      
      final response = await supabaseClient
          .from('bakery_services')
          .select('*')
          .eq('is_active', true)
          .order('name', ascending: true);

      debugPrint('🎂 BAKERY: Raw response: $response');
      
      final services = response
          .map((data) => BakeryServiceModel.fromJson(data))
          .toList();

      debugPrint('🎂 BAKERY: Mapped ${services.length} services');
      return services;
    } catch (e) {
      debugPrint('🎂 BAKERY ERROR: Failed to fetch services: $e');
      throw ServerException('Failed to fetch bakery services: ${e.toString()}');
    }
  }

  @override
  Future<BakeryServiceModel> getBakeryServiceById(String id) async {
    try {
      debugPrint('🎂 BAKERY: Fetching service by ID: $id');
      
      final response = await supabaseClient
          .from('bakery_services')
          .select('*')
          .eq('id', id)
          .single();

      debugPrint('🎂 BAKERY: Service found: ${response['name']}');
      return BakeryServiceModel.fromJson(response);
    } catch (e) {
      debugPrint('🎂 BAKERY ERROR: Failed to fetch service: $e');
      throw ServerException('Failed to fetch bakery service: ${e.toString()}');
    }
  }

  @override
  Future<BakeryOrderModel> createBakeryOrder(BakeryOrderModel order) async {
    try {
      debugPrint('🎂 BAKERY: Creating order for service: ${order.serviceId}');
      
      final orderData = order.toJson();
      // Remove id for creation
      orderData.remove('id');
      
      final response = await supabaseClient
          .from('bakery_orders')
          .insert(orderData)
          .select()
          .single();

      debugPrint('🎂 BAKERY: Order created with ID: ${response['id']}');
      return BakeryOrderModel.fromJson(response);
    } catch (e) {
      debugPrint('🎂 BAKERY ERROR: Failed to create order: $e');
      throw ServerException('Failed to create bakery order: ${e.toString()}');
    }
  }

  @override
  Future<BakeryOrderModel> updateBakeryOrder(BakeryOrderModel order) async {
    try {
      debugPrint('🎂 BAKERY: Updating order: ${order.id}');
      
      final orderData = order.toJson();
      orderData['updated_at'] = DateTime.now().toIso8601String();
      
      final response = await supabaseClient
          .from('bakery_orders')
          .update(orderData)
          .eq('id', order.id)
          .select()
          .single();

      debugPrint('🎂 BAKERY: Order updated: ${response['id']}');
      return BakeryOrderModel.fromJson(response);
    } catch (e) {
      debugPrint('🎂 BAKERY ERROR: Failed to update order: $e');
      throw ServerException('Failed to update bakery order: ${e.toString()}');
    }
  }

  @override
  Future<List<BakeryOrderModel>> getUserBakeryOrders(String userId) async {
    try {
      debugPrint('🎂 BAKERY: Fetching orders for user: $userId');
      
      final response = await supabaseClient
          .from('bakery_orders')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      debugPrint('🎂 BAKERY: Found ${response.length} orders');
      
      final orders = response
          .map((data) => BakeryOrderModel.fromJson(data))
          .toList();

      return orders;
    } catch (e) {
      debugPrint('🎂 BAKERY ERROR: Failed to fetch user orders: $e');
      throw ServerException('Failed to fetch user bakery orders: ${e.toString()}');
    }
  }

  @override
  Future<BakeryOrderModel> getBakeryOrderById(String id) async {
    try {
      debugPrint('🎂 BAKERY: Fetching order by ID: $id');
      
      final response = await supabaseClient
          .from('bakery_orders')
          .select('*')
          .eq('id', id)
          .single();

      debugPrint('🎂 BAKERY: Order found: ${response['id']}');
      return BakeryOrderModel.fromJson(response);
    } catch (e) {
      debugPrint('🎂 BAKERY ERROR: Failed to fetch order: $e');
      throw ServerException('Failed to fetch bakery order: ${e.toString()}');
    }
  }

  @override
  Future<double> calculateBakeryPrice(String serviceId, BakeryOrderSpecifications specifications) async {
    try {
      debugPrint('🎂 BAKERY: Calculating price for service: $serviceId');
      
      final service = await getBakeryServiceById(serviceId);
      
      double totalPrice = service.basePrice;
      
      // Add size-based pricing
      if (specifications.size != null) {
        switch (specifications.size) {
          case '0.5kg':
            totalPrice *= 0.7;
            break;
          case '1kg':
            totalPrice *= 1.0;
            break;
          case '2kg':
            totalPrice *= 1.8;
            break;
          case '3kg':
            totalPrice *= 2.5;
            break;
        }
      }
      
      // Add customization charges
      if (service.customizationAvailable && specifications.design != null) {
        totalPrice += 200; // Design fee
      }
      
      // Add flavor premium
      if (specifications.flavor == 'strawberry' || specifications.flavor == 'butterscotch') {
        totalPrice += 100; // Premium flavor charge
      }
      
      debugPrint('🎂 BAKERY: Calculated price: ₹$totalPrice');
      return totalPrice;
    } catch (e) {
      debugPrint('🎂 BAKERY ERROR: Failed to calculate price: $e');
      throw ServerException('Failed to calculate bakery price: ${e.toString()}');
    }
  }

  @override
  Future<List<BakeryVendorModel>> getAvailableBakeryVendors(String area) async {
    try {
      debugPrint('🎂 BAKERY: Fetching vendors for area: $area');
      
      final response = await supabaseClient
          .from('bakery_vendors')
          .select('*')
          .eq('is_active', true);

      debugPrint('🎂 BAKERY: Found ${response.length} vendors');
      
      final vendors = response
          .map((data) => BakeryVendorModel.fromJson(data))
          .where((vendor) => vendor.deliversTo(area))
          .toList();

      debugPrint('🎂 BAKERY: ${vendors.length} vendors deliver to area: $area');
      return vendors;
    } catch (e) {
      debugPrint('🎂 BAKERY ERROR: Failed to fetch vendors: $e');
      throw ServerException('Failed to fetch bakery vendors: ${e.toString()}');
    }
  }

  @override
  Future<String> uploadDesignImage(String filePath) async {
    try {
      debugPrint('🎂 BAKERY: Uploading design image: $filePath');

      // For now, return a placeholder URL since we don't have storage bucket set up
      // TODO: Implement actual file upload when storage bucket is configured
      const placeholderUrl = 'https://via.placeholder.com/400x300.png?text=Design+Image';

      debugPrint('🎂 BAKERY: Using placeholder image URL: $placeholderUrl');
      return placeholderUrl;
    } catch (e) {
      debugPrint('🎂 BAKERY ERROR: Failed to upload image: $e');
      throw ServerException('Failed to upload design image: ${e.toString()}');
    }
  }
}
