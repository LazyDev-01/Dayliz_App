import '../../domain/entities/laundry_service.dart';

/// LaundryBookingItem model extending the domain entity
class LaundryBookingItemModel extends LaundryBookingItem {
  const LaundryBookingItemModel({
    required String id,
    required String bookingId,
    required String serviceId,
    String? vendorId,
    required String itemType,
    required int quantity,
    double? estimatedWeight,
    double? actualWeight,
    double? serviceBasePrice,
    double? serviceTotalPrice,
    LaundryBookingItemStatus itemStatus = LaundryBookingItemStatus.pending,
    DateTime? estimatedDeliveryDate,
    DateTime? actualDeliveryDate,
    String? specialInstructions,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(
          id: id,
          bookingId: bookingId,
          serviceId: serviceId,
          vendorId: vendorId,
          itemType: itemType,
          quantity: quantity,
          estimatedWeight: estimatedWeight,
          actualWeight: actualWeight,
          serviceBasePrice: serviceBasePrice,
          serviceTotalPrice: serviceTotalPrice,
          itemStatus: itemStatus,
          estimatedDeliveryDate: estimatedDeliveryDate,
          actualDeliveryDate: actualDeliveryDate,
          specialInstructions: specialInstructions,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  /// Create LaundryBookingItemModel from JSON
  factory LaundryBookingItemModel.fromJson(Map<String, dynamic> json) {
    return LaundryBookingItemModel(
      id: json['id'] ?? '',
      bookingId: json['booking_id'] ?? '',
      serviceId: json['service_id'] ?? '',
      vendorId: json['vendor_id'],
      itemType: json['item_type'] ?? '',
      quantity: json['quantity'] ?? 1,
      estimatedWeight: json['estimated_weight']?.toDouble(),
      actualWeight: json['actual_weight']?.toDouble(),
      serviceBasePrice: json['service_base_price']?.toDouble(),
      serviceTotalPrice: json['service_total_price']?.toDouble(),
      itemStatus: _parseItemStatus(json['item_status']),
      estimatedDeliveryDate: json['estimated_delivery_date'] != null
          ? DateTime.parse(json['estimated_delivery_date']) : null,
      actualDeliveryDate: json['actual_delivery_date'] != null
          ? DateTime.parse(json['actual_delivery_date']) : null,
      specialInstructions: json['special_instructions'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// Convert LaundryBookingItemModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'service_id': serviceId,
      'vendor_id': vendorId,
      'item_type': itemType,
      'quantity': quantity,
      'estimated_weight': estimatedWeight,
      'actual_weight': actualWeight,
      'service_base_price': serviceBasePrice,
      'service_total_price': serviceTotalPrice,
      'item_status': _itemStatusToString(itemStatus),
      'estimated_delivery_date': estimatedDeliveryDate?.toIso8601String().split('T')[0],
      'actual_delivery_date': actualDeliveryDate?.toIso8601String().split('T')[0],
      'special_instructions': specialInstructions,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Parse item status from string
  static LaundryBookingItemStatus _parseItemStatus(String? status) {
    switch (status) {
      case 'pending':
        return LaundryBookingItemStatus.pending;
      case 'picked_up':
        return LaundryBookingItemStatus.pickedUp;
      case 'processing':
        return LaundryBookingItemStatus.processing;
      case 'ready':
        return LaundryBookingItemStatus.ready;
      case 'delivered':
        return LaundryBookingItemStatus.delivered;
      case 'cancelled':
        return LaundryBookingItemStatus.cancelled;
      default:
        return LaundryBookingItemStatus.pending;
    }
  }

  /// Convert item status to string
  static String _itemStatusToString(LaundryBookingItemStatus status) {
    switch (status) {
      case LaundryBookingItemStatus.pending:
        return 'pending';
      case LaundryBookingItemStatus.pickedUp:
        return 'picked_up';
      case LaundryBookingItemStatus.processing:
        return 'processing';
      case LaundryBookingItemStatus.ready:
        return 'ready';
      case LaundryBookingItemStatus.delivered:
        return 'delivered';
      case LaundryBookingItemStatus.cancelled:
        return 'cancelled';
    }
  }
}

/// LaundryService model extending the domain entity
class LaundryServiceModel extends LaundryService {
  const LaundryServiceModel({
    required String id,
    required String name,
    required LaundryServiceType serviceType,
    required double basePrice,
    double? pricePerKg,
    required int turnaroundHours,
    List<String> pickupAreas = const [],
    bool isActive = true,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(
          id: id,
          name: name,
          serviceType: serviceType,
          basePrice: basePrice,
          pricePerKg: pricePerKg,
          turnaroundHours: turnaroundHours,
          pickupAreas: pickupAreas,
          isActive: isActive,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  /// Create LaundryServiceModel from JSON
  factory LaundryServiceModel.fromJson(Map<String, dynamic> json) {
    return LaundryServiceModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      serviceType: _parseServiceType(json['service_type']),
      basePrice: (json['base_price'] ?? 0.0).toDouble(),
      pricePerKg: json['price_per_kg']?.toDouble(),
      turnaroundHours: json['turnaround_hours'] ?? 24,
      pickupAreas: _parsePickupAreas(json['pickup_areas']),
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// Convert LaundryServiceModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'service_type': _serviceTypeToString(serviceType),
      'base_price': basePrice,
      'price_per_kg': pricePerKg,
      'turnaround_hours': turnaroundHours,
      'pickup_areas': pickupAreas,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Parse service type from string
  static LaundryServiceType _parseServiceType(String? serviceType) {
    switch (serviceType) {
      case 'wash_fold':
        return LaundryServiceType.washFold;
      case 'dry_clean':
        return LaundryServiceType.dryClean;
      case 'steam_iron':
        return LaundryServiceType.steamIron;
      case 'wash_iron':
        return LaundryServiceType.washIron;
      default:
        return LaundryServiceType.washFold;
    }
  }

  /// Convert service type to string
  static String _serviceTypeToString(LaundryServiceType serviceType) {
    switch (serviceType) {
      case LaundryServiceType.washFold:
        return 'wash_fold';
      case LaundryServiceType.dryClean:
        return 'dry_clean';
      case LaundryServiceType.steamIron:
        return 'steam_iron';
      case LaundryServiceType.washIron:
        return 'wash_iron';
    }
  }

  /// Parse pickup areas from JSON
  static List<String> _parsePickupAreas(dynamic pickupAreas) {
    if (pickupAreas == null) return [];
    if (pickupAreas is List) {
      return pickupAreas.map((area) => area.toString()).toList();
    }
    return [];
  }
}

/// LaundryBooking model extending the domain entity (multi-service support)
class LaundryBookingModel extends LaundryBooking {
  const LaundryBookingModel({
    required String id,
    required String userId,
    String? pickupAddressId,
    String? deliveryAddressId,
    DateTime? pickupDate,
    String? pickupTimeSlot,
    double? totalEstimatedPrice,
    double? totalFinalPrice,
    LaundryBookingStatus overallStatus = LaundryBookingStatus.pending,
    String? specialInstructions,
    List<LaundryBookingItem> items = const [],
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(
          id: id,
          userId: userId,
          pickupAddressId: pickupAddressId,
          deliveryAddressId: deliveryAddressId,
          pickupDate: pickupDate,
          pickupTimeSlot: pickupTimeSlot,
          totalEstimatedPrice: totalEstimatedPrice,
          totalFinalPrice: totalFinalPrice,
          overallStatus: overallStatus,
          specialInstructions: specialInstructions,
          items: items,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  /// Create LaundryBookingModel from JSON
  factory LaundryBookingModel.fromJson(Map<String, dynamic> json) {
    return LaundryBookingModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      pickupAddressId: json['pickup_address_id'],
      deliveryAddressId: json['delivery_address_id'],
      pickupDate: json['pickup_date'] != null ? DateTime.parse(json['pickup_date']) : null,
      pickupTimeSlot: json['pickup_time_slot'],
      totalEstimatedPrice: json['total_estimated_price']?.toDouble(),
      totalFinalPrice: json['total_final_price']?.toDouble(),
      overallStatus: _parseBookingStatus(json['overall_status']),
      specialInstructions: json['special_instructions'],
      items: _parseBookingItems(json['items'] ?? []),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// Convert LaundryBookingModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'pickup_address_id': pickupAddressId,
      'delivery_address_id': deliveryAddressId,
      'pickup_date': pickupDate?.toIso8601String().split('T')[0],
      'pickup_time_slot': pickupTimeSlot,
      'total_estimated_price': totalEstimatedPrice,
      'total_final_price': totalFinalPrice,
      'overall_status': _bookingStatusToString(overallStatus),
      'special_instructions': specialInstructions,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Parse booking items from JSON (for multi-service bookings)
  static List<LaundryBookingItem> _parseBookingItems(dynamic items) {
    if (items == null) return [];
    if (items is List) {
      return items.map((item) => LaundryBookingItemModel.fromJson(item)).toList();
    }
    return [];
  }

  /// Parse booking status from string
  static LaundryBookingStatus _parseBookingStatus(String? status) {
    switch (status) {
      case 'pending':
        return LaundryBookingStatus.pending;
      case 'confirmed':
        return LaundryBookingStatus.confirmed;
      case 'picked_up':
        return LaundryBookingStatus.pickedUp;
      case 'in_process':
        return LaundryBookingStatus.inProcess;
      case 'ready':
        return LaundryBookingStatus.ready;
      case 'delivered':
        return LaundryBookingStatus.delivered;
      case 'cancelled':
        return LaundryBookingStatus.cancelled;
      default:
        return LaundryBookingStatus.pending;
    }
  }

  /// Convert booking status to string
  static String _bookingStatusToString(LaundryBookingStatus status) {
    switch (status) {
      case LaundryBookingStatus.pending:
        return 'pending';
      case LaundryBookingStatus.confirmed:
        return 'confirmed';
      case LaundryBookingStatus.pickedUp:
        return 'picked_up';
      case LaundryBookingStatus.inProcess:
        return 'in_process';
      case LaundryBookingStatus.ready:
        return 'ready';
      case LaundryBookingStatus.delivered:
        return 'delivered';
      case LaundryBookingStatus.cancelled:
        return 'cancelled';
    }
  }
}

/// LaundryVendor model extending the domain entity
class LaundryVendorModel extends LaundryVendor {
  const LaundryVendorModel({
    required String id,
    required String vendorId,
    required int dailyCapacityKg,
    List<LaundryServiceType> serviceTypes = const [],
    List<String> pickupAreas = const [],
    Map<String, dynamic> operatingHours = const {},
    Map<String, dynamic> pricingConfig = const {},
    bool isActive = true,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(
          id: id,
          vendorId: vendorId,
          dailyCapacityKg: dailyCapacityKg,
          serviceTypes: serviceTypes,
          pickupAreas: pickupAreas,
          operatingHours: operatingHours,
          pricingConfig: pricingConfig,
          isActive: isActive,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  /// Create LaundryVendorModel from JSON
  factory LaundryVendorModel.fromJson(Map<String, dynamic> json) {
    return LaundryVendorModel(
      id: json['id'] ?? '',
      vendorId: json['vendor_id'] ?? '',
      dailyCapacityKg: json['daily_capacity_kg'] ?? 100,
      serviceTypes: _parseServiceTypes(json['service_types']),
      pickupAreas: _parsePickupAreas(json['pickup_areas']),
      operatingHours: json['operating_hours'] ?? {},
      pricingConfig: json['pricing_config'] ?? {},
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// Parse service types from JSON
  static List<LaundryServiceType> _parseServiceTypes(dynamic serviceTypes) {
    if (serviceTypes == null) return [];
    if (serviceTypes is List) {
      return serviceTypes
          .map((type) => LaundryServiceModel._parseServiceType(type.toString()))
          .toList();
    }
    return [];
  }

  /// Parse pickup areas from JSON
  static List<String> _parsePickupAreas(dynamic pickupAreas) {
    if (pickupAreas == null) return [];
    if (pickupAreas is List) {
      return pickupAreas.map((area) => area.toString()).toList();
    }
    return [];
  }
}
