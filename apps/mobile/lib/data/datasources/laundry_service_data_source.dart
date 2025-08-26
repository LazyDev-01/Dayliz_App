import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import '../../core/error/exceptions.dart';
import '../models/laundry_service_model.dart';
import '../../domain/entities/laundry_service.dart';

/// Multi-service price calculation item
class MultiServicePriceItem {
  final String serviceId;
  final double weight;
  final int quantity;
  final String itemType;

  MultiServicePriceItem({
    required this.serviceId,
    required this.weight,
    required this.quantity,
    required this.itemType,
  });
}

/// Abstract class defining laundry service data source contract
abstract class LaundryServiceDataSource {
  Future<List<LaundryServiceModel>> getLaundryServices();
  Future<LaundryServiceModel> getLaundryServiceById(String id);
  Future<LaundryBookingModel> createLaundryBooking(LaundryBookingModel booking, List<LaundryBookingItemModel> items);
  Future<LaundryBookingModel> updateLaundryBooking(LaundryBookingModel booking);
  Future<List<LaundryBookingModel>> getUserLaundryBookings(String userId);
  Future<LaundryBookingModel> getLaundryBookingById(String id);
  Future<double> calculateMultiServicePrice(List<MultiServicePriceItem> items);
  Future<List<LaundryVendorModel>> getAvailableLaundryVendors(String area);
  Future<LaundryBookingItemModel> createBookingItem(LaundryBookingItemModel item);
  Future<LaundryBookingItemModel> updateBookingItem(LaundryBookingItemModel item);
  Future<List<LaundryBookingItemModel>> getBookingItems(String bookingId);
}

/// Supabase implementation of laundry service data source
class LaundryServiceSupabaseDataSource implements LaundryServiceDataSource {
  final SupabaseClient supabaseClient;

  LaundryServiceSupabaseDataSource({required this.supabaseClient});

  @override
  Future<List<LaundryServiceModel>> getLaundryServices() async {
    try {
      debugPrint('🧺 LAUNDRY: Fetching laundry services...');
      
      final response = await supabaseClient
          .from('laundry_services')
          .select('*')
          .eq('is_active', true)
          .order('name', ascending: true);

      debugPrint('🧺 LAUNDRY: Raw response: $response');
      
      final services = response
          .map((data) => LaundryServiceModel.fromJson(data))
          .toList();

      debugPrint('🧺 LAUNDRY: Mapped ${services.length} services');
      return services;
    } catch (e) {
      debugPrint('🧺 LAUNDRY ERROR: Failed to fetch services: $e');
      throw ServerException('Failed to fetch laundry services: ${e.toString()}');
    }
  }

  @override
  Future<LaundryServiceModel> getLaundryServiceById(String id) async {
    try {
      debugPrint('🧺 LAUNDRY: Fetching service by ID: $id');
      
      final response = await supabaseClient
          .from('laundry_services')
          .select('*')
          .eq('id', id)
          .single();

      debugPrint('🧺 LAUNDRY: Service found: ${response['name']}');
      return LaundryServiceModel.fromJson(response);
    } catch (e) {
      debugPrint('🧺 LAUNDRY ERROR: Failed to fetch service: $e');
      throw ServerException('Failed to fetch laundry service: ${e.toString()}');
    }
  }

  @override
  Future<LaundryBookingModel> createLaundryBooking(LaundryBookingModel booking, List<LaundryBookingItemModel> items) async {
    try {
      debugPrint('🧺 LAUNDRY: Creating multi-service booking with ${items.length} items');

      // Validate input data
      if (items.isEmpty) {
        throw const ServerException('Cannot create booking without services');
      }

      // Prepare booking data
      final bookingData = booking.toJson();
      bookingData.remove('id');

      // Validate required fields
      if (bookingData['user_id'] == null || bookingData['user_id'].toString().isEmpty) {
        throw const ServerException('User ID is required for booking');
      }

      if (bookingData['pickup_date'] == null) {
        throw const ServerException('Pickup date is required for booking');
      }

      // Create the main booking with error handling
      final bookingResponse = await supabaseClient
          .from('laundry_bookings')
          .insert(bookingData)
          .select()
          .single()
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw const ServerException('Booking creation timed out. Please try again.'),
          );

      final bookingId = bookingResponse['id'];
      if (bookingId == null) {
        throw const ServerException('Failed to generate booking ID');
      }

      debugPrint('🧺 LAUNDRY: Booking created with ID: $bookingId');

      // Prepare booking items data
      final itemsData = items.map((item) {
        final itemData = item.toJson();
        itemData.remove('id');
        itemData['booking_id'] = bookingId;

        // Validate item data
        if (itemData['service_id'] == null || itemData['service_id'].toString().isEmpty) {
          throw const ServerException('Service ID is required for booking items');
        }

        return itemData;
      }).toList();

      // Create booking items with error handling
      await supabaseClient
          .from('laundry_booking_items')
          .insert(itemsData)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw const ServerException('Booking items creation timed out. Please try again.'),
          );

      debugPrint('🧺 LAUNDRY: Created ${items.length} booking items');

      // Return the complete booking with items
      return await getLaundryBookingById(bookingId);
    } on ServerException {
      // Re-throw server exceptions as-is
      rethrow;
    } catch (e) {
      debugPrint('🧺 LAUNDRY ERROR: Failed to create booking: $e');

      // Handle specific error types
      if (e.toString().contains('network') || e.toString().contains('connection')) {
        throw const ServerException('Network error. Please check your internet connection and try again.');
      } else if (e.toString().contains('timeout')) {
        throw const ServerException('Request timed out. Please try again.');
      } else if (e.toString().contains('duplicate') || e.toString().contains('unique')) {
        throw const ServerException('A booking with similar details already exists.');
      } else {
        throw ServerException('Failed to create laundry booking: ${e.toString()}');
      }
    }
  }

  @override
  Future<LaundryBookingModel> updateLaundryBooking(LaundryBookingModel booking) async {
    try {
      debugPrint('🧺 LAUNDRY: Updating booking: ${booking.id}');

      final bookingData = booking.toJson();
      bookingData['updated_at'] = DateTime.now().toIso8601String();

      final response = await supabaseClient
          .from('laundry_bookings')
          .update(bookingData)
          .eq('id', booking.id)
          .select()
          .single();

      debugPrint('🧺 LAUNDRY: Booking updated: ${response['id']}');
      return LaundryBookingModel.fromJson(response);
    } catch (e) {
      debugPrint('🧺 LAUNDRY ERROR: Failed to update booking: $e');
      throw ServerException('Failed to update laundry booking: ${e.toString()}');
    }
  }

  @override
  Future<List<LaundryBookingModel>> getUserLaundryBookings(String userId) async {
    try {
      debugPrint('🧺 LAUNDRY: Fetching bookings for user: $userId');

      final response = await supabaseClient
          .from('laundry_bookings')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      debugPrint('🧺 LAUNDRY: Found ${response.length} bookings');

      final bookings = <LaundryBookingModel>[];

      for (final bookingData in response) {
        final booking = LaundryBookingModel.fromJson(bookingData);
        final items = await getBookingItems(booking.id);

        // Create booking with items
        final bookingWithItems = LaundryBookingModel(
          id: booking.id,
          userId: booking.userId,
          pickupAddressId: booking.pickupAddressId,
          deliveryAddressId: booking.deliveryAddressId,
          pickupDate: booking.pickupDate,
          pickupTimeSlot: booking.pickupTimeSlot,
          totalEstimatedPrice: booking.totalEstimatedPrice,
          totalFinalPrice: booking.totalFinalPrice,
          overallStatus: booking.overallStatus,
          specialInstructions: booking.specialInstructions,
          items: items,
          createdAt: booking.createdAt,
          updatedAt: booking.updatedAt,
        );

        bookings.add(bookingWithItems);
      }

      return bookings;
    } catch (e) {
      debugPrint('🧺 LAUNDRY ERROR: Failed to fetch user bookings: $e');
      throw ServerException('Failed to fetch user laundry bookings: ${e.toString()}');
    }
  }

  @override
  Future<LaundryBookingModel> getLaundryBookingById(String id) async {
    try {
      debugPrint('🧺 LAUNDRY: Fetching booking by ID: $id');

      final response = await supabaseClient
          .from('laundry_bookings')
          .select('*')
          .eq('id', id)
          .single();

      debugPrint('🧺 LAUNDRY: Booking found: ${response['id']}');

      final booking = LaundryBookingModel.fromJson(response);
      final items = await getBookingItems(booking.id);

      // Return booking with items
      return LaundryBookingModel(
        id: booking.id,
        userId: booking.userId,
        pickupAddressId: booking.pickupAddressId,
        deliveryAddressId: booking.deliveryAddressId,
        pickupDate: booking.pickupDate,
        pickupTimeSlot: booking.pickupTimeSlot,
        totalEstimatedPrice: booking.totalEstimatedPrice,
        totalFinalPrice: booking.totalFinalPrice,
        overallStatus: booking.overallStatus,
        specialInstructions: booking.specialInstructions,
        items: items,
        createdAt: booking.createdAt,
        updatedAt: booking.updatedAt,
      );
    } catch (e) {
      debugPrint('🧺 LAUNDRY ERROR: Failed to fetch booking: $e');
      throw ServerException('Failed to fetch laundry booking: ${e.toString()}');
    }
  }

  @override
  Future<double> calculateMultiServicePrice(List<MultiServicePriceItem> items) async {
    try {
      debugPrint('🧺 LAUNDRY: Calculating multi-service price for ${items.length} items');

      double totalPrice = 0.0;

      for (final item in items) {
        final service = await getLaundryServiceById(item.serviceId);

        double servicePrice = service.basePrice;

        // Add weight-based pricing if available
        if (service.pricePerKg != null && item.weight > 0) {
          servicePrice += (service.pricePerKg! * item.weight);
        }

        totalPrice += servicePrice;
        debugPrint('🧺 LAUNDRY: Service ${service.name}: ₹$servicePrice');
      }

      debugPrint('🧺 LAUNDRY: Total calculated price: ₹$totalPrice');
      return totalPrice;
    } catch (e) {
      debugPrint('🧺 LAUNDRY ERROR: Failed to calculate price: $e');
      throw ServerException('Failed to calculate laundry price: ${e.toString()}');
    }
  }

  @override
  Future<List<LaundryVendorModel>> getAvailableLaundryVendors(String area) async {
    try {
      debugPrint('🧺 LAUNDRY: Fetching vendors for area: $area');

      final response = await supabaseClient
          .from('laundry_vendors')
          .select('*')
          .eq('is_active', true);

      debugPrint('🧺 LAUNDRY: Found ${response.length} vendors');

      final vendors = response
          .map((data) => LaundryVendorModel.fromJson(data))
          .where((vendor) => vendor.servesArea(area))
          .toList();

      debugPrint('🧺 LAUNDRY: ${vendors.length} vendors serve area: $area');
      return vendors;
    } catch (e) {
      debugPrint('🧺 LAUNDRY ERROR: Failed to fetch vendors: $e');
      throw ServerException('Failed to fetch laundry vendors: ${e.toString()}');
    }
  }

  @override
  Future<LaundryBookingItemModel> createBookingItem(LaundryBookingItemModel item) async {
    try {
      debugPrint('🧺 LAUNDRY: Creating booking item: ${item.itemType}');

      final itemData = item.toJson();
      itemData.remove('id');

      final response = await supabaseClient
          .from('laundry_booking_items')
          .insert(itemData)
          .select()
          .single();

      debugPrint('🧺 LAUNDRY: Booking item created with ID: ${response['id']}');
      return LaundryBookingItemModel.fromJson(response);
    } catch (e) {
      debugPrint('🧺 LAUNDRY ERROR: Failed to create booking item: $e');
      throw ServerException('Failed to create booking item: ${e.toString()}');
    }
  }

  @override
  Future<LaundryBookingItemModel> updateBookingItem(LaundryBookingItemModel item) async {
    try {
      debugPrint('🧺 LAUNDRY: Updating booking item: ${item.id}');

      final itemData = item.toJson();
      itemData['updated_at'] = DateTime.now().toIso8601String();

      final response = await supabaseClient
          .from('laundry_booking_items')
          .update(itemData)
          .eq('id', item.id)
          .select()
          .single();

      debugPrint('🧺 LAUNDRY: Booking item updated: ${response['id']}');
      return LaundryBookingItemModel.fromJson(response);
    } catch (e) {
      debugPrint('🧺 LAUNDRY ERROR: Failed to update booking item: $e');
      throw ServerException('Failed to update booking item: ${e.toString()}');
    }
  }

  @override
  Future<List<LaundryBookingItemModel>> getBookingItems(String bookingId) async {
    try {
      debugPrint('🧺 LAUNDRY: Fetching items for booking: $bookingId');

      final response = await supabaseClient
          .from('laundry_booking_items')
          .select('*')
          .eq('booking_id', bookingId)
          .order('created_at', ascending: true);

      debugPrint('🧺 LAUNDRY: Found ${response.length} items');

      final items = response
          .map((data) => LaundryBookingItemModel.fromJson(data))
          .toList();

      return items;
    } catch (e) {
      debugPrint('🧺 LAUNDRY ERROR: Failed to fetch booking items: $e');
      throw ServerException('Failed to fetch booking items: ${e.toString()}');
    }
  }
}
