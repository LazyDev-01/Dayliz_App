import 'package:equatable/equatable.dart';

/// Enum for laundry service types
enum LaundryServiceType {
  washFold,
  dryClean,
  steamIron,
  washIron,
}

/// Enum for laundry booking status
enum LaundryBookingStatus {
  pending,
  confirmed,
  pickedUp,
  inProcess,
  ready,
  delivered,
  cancelled,
}

/// Laundry service entity
class LaundryService extends Equatable {
  final String id;
  final String name;
  final LaundryServiceType serviceType;
  final double basePrice;
  final double? pricePerKg;
  final int turnaroundHours;
  final List<String> pickupAreas;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LaundryService({
    required this.id,
    required this.name,
    required this.serviceType,
    required this.basePrice,
    this.pricePerKg,
    required this.turnaroundHours,
    this.pickupAreas = const [],
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        serviceType,
        basePrice,
        pricePerKg,
        turnaroundHours,
        pickupAreas,
        isActive,
        createdAt,
        updatedAt,
      ];

  /// Get service type display name
  String get serviceTypeDisplayName {
    switch (serviceType) {
      case LaundryServiceType.washFold:
        return 'Wash & Fold';
      case LaundryServiceType.dryClean:
        return 'Dry Clean';
      case LaundryServiceType.steamIron:
        return 'Steam Iron';
      case LaundryServiceType.washIron:
        return 'Wash Iron';
    }
  }

  /// Get estimated turnaround time display
  String get turnaroundTimeDisplay {
    if (turnaroundHours < 24) {
      return '$turnaroundHours hours';
    } else {
      final days = (turnaroundHours / 24).round();
      return '$days ${days == 1 ? 'day' : 'days'}';
    }
  }
}

/// Laundry item entity (legacy - for backward compatibility)
class LaundryItem extends Equatable {
  final String type;
  final int quantity;
  final String? specialInstructions;

  const LaundryItem({
    required this.type,
    required this.quantity,
    this.specialInstructions,
  });

  @override
  List<Object?> get props => [type, quantity, specialInstructions];

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'quantity': quantity,
      'special_instructions': specialInstructions,
    };
  }

  factory LaundryItem.fromJson(Map<String, dynamic> json) {
    return LaundryItem(
      type: json['type'] ?? '',
      quantity: json['quantity'] ?? 0,
      specialInstructions: json['special_instructions'],
    );
  }
}

/// Enum for laundry booking item status
enum LaundryBookingItemStatus {
  pending,
  pickedUp,
  processing,
  ready,
  delivered,
  cancelled,
}

/// Laundry booking item entity (for multi-service bookings)
class LaundryBookingItem extends Equatable {
  final String id;
  final String bookingId;
  final String serviceId;
  final String? vendorId;
  final String itemType;
  final int quantity;
  final double? estimatedWeight;
  final double? actualWeight;
  final double? serviceBasePrice;
  final double? serviceTotalPrice;
  final LaundryBookingItemStatus itemStatus;
  final DateTime? estimatedDeliveryDate;
  final DateTime? actualDeliveryDate;
  final String? specialInstructions;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LaundryBookingItem({
    required this.id,
    required this.bookingId,
    required this.serviceId,
    this.vendorId,
    required this.itemType,
    required this.quantity,
    this.estimatedWeight,
    this.actualWeight,
    this.serviceBasePrice,
    this.serviceTotalPrice,
    this.itemStatus = LaundryBookingItemStatus.pending,
    this.estimatedDeliveryDate,
    this.actualDeliveryDate,
    this.specialInstructions,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        bookingId,
        serviceId,
        vendorId,
        itemType,
        quantity,
        estimatedWeight,
        actualWeight,
        serviceBasePrice,
        serviceTotalPrice,
        itemStatus,
        estimatedDeliveryDate,
        actualDeliveryDate,
        specialInstructions,
        createdAt,
        updatedAt,
      ];

  /// Get item status display name
  String get itemStatusDisplayName {
    switch (itemStatus) {
      case LaundryBookingItemStatus.pending:
        return 'Pending';
      case LaundryBookingItemStatus.pickedUp:
        return 'Picked Up';
      case LaundryBookingItemStatus.processing:
        return 'Processing';
      case LaundryBookingItemStatus.ready:
        return 'Ready';
      case LaundryBookingItemStatus.delivered:
        return 'Delivered';
      case LaundryBookingItemStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Check if item can be cancelled
  bool get canBeCancelled {
    return itemStatus == LaundryBookingItemStatus.pending ||
           itemStatus == LaundryBookingItemStatus.pickedUp;
  }

  /// Check if item is completed
  bool get isCompleted {
    return itemStatus == LaundryBookingItemStatus.delivered;
  }
}

/// Laundry booking entity (multi-service support)
class LaundryBooking extends Equatable {
  final String id;
  final String userId;
  final String? pickupAddressId;
  final String? deliveryAddressId;
  final DateTime? pickupDate;
  final String? pickupTimeSlot;
  final double? totalEstimatedPrice;
  final double? totalFinalPrice;
  final LaundryBookingStatus overallStatus;
  final String? specialInstructions;
  final List<LaundryBookingItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LaundryBooking({
    required this.id,
    required this.userId,
    this.pickupAddressId,
    this.deliveryAddressId,
    this.pickupDate,
    this.pickupTimeSlot,
    this.totalEstimatedPrice,
    this.totalFinalPrice,
    this.overallStatus = LaundryBookingStatus.pending,
    this.specialInstructions,
    this.items = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        pickupAddressId,
        deliveryAddressId,
        pickupDate,
        pickupTimeSlot,
        totalEstimatedPrice,
        totalFinalPrice,
        overallStatus,
        specialInstructions,
        items,
        createdAt,
        updatedAt,
      ];

  /// Get status display name
  String get statusDisplayName {
    switch (overallStatus) {
      case LaundryBookingStatus.pending:
        return 'Pending';
      case LaundryBookingStatus.confirmed:
        return 'Confirmed';
      case LaundryBookingStatus.pickedUp:
        return 'Picked Up';
      case LaundryBookingStatus.inProcess:
        return 'In Process';
      case LaundryBookingStatus.ready:
        return 'Ready';
      case LaundryBookingStatus.delivered:
        return 'Delivered';
      case LaundryBookingStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Check if booking can be cancelled
  bool get canBeCancelled {
    return overallStatus == LaundryBookingStatus.pending ||
           overallStatus == LaundryBookingStatus.confirmed;
  }

  /// Check if booking is completed
  bool get isCompleted {
    return overallStatus == LaundryBookingStatus.delivered;
  }

  /// Get total items count
  int get totalItemsCount {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  /// Get items by service type
  List<LaundryBookingItem> getItemsByService(String serviceId) {
    return items.where((item) => item.serviceId == serviceId).toList();
  }

  /// Get unique service IDs in this booking
  List<String> get uniqueServiceIds {
    return items.map((item) => item.serviceId).toSet().toList();
  }

  /// Check if booking has multiple services
  bool get hasMultipleServices {
    return uniqueServiceIds.length > 1;
  }
}

/// Laundry vendor entity
class LaundryVendor extends Equatable {
  final String id;
  final String vendorId;
  final int dailyCapacityKg;
  final List<LaundryServiceType> serviceTypes;
  final List<String> pickupAreas;
  final Map<String, dynamic> operatingHours;
  final Map<String, dynamic> pricingConfig;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LaundryVendor({
    required this.id,
    required this.vendorId,
    required this.dailyCapacityKg,
    this.serviceTypes = const [],
    this.pickupAreas = const [],
    this.operatingHours = const {},
    this.pricingConfig = const {},
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        vendorId,
        dailyCapacityKg,
        serviceTypes,
        pickupAreas,
        operatingHours,
        pricingConfig,
        isActive,
        createdAt,
        updatedAt,
      ];

  /// Check if vendor supports a specific service type
  bool supportsServiceType(LaundryServiceType serviceType) {
    return serviceTypes.contains(serviceType);
  }

  /// Check if vendor serves a specific area
  bool servesArea(String area) {
    return pickupAreas.contains(area);
  }
}
