import 'package:equatable/equatable.dart';

/// Enum for bakery service types
enum BakeryServiceType {
  freshBakery,
  customCake,
  occasionCake,
}

/// Enum for bakery order status
enum BakeryOrderStatus {
  pending,
  confirmed,
  inPreparation,
  ready,
  delivered,
  cancelled,
}

/// Bakery service entity
class BakeryService extends Equatable {
  final String id;
  final String name;
  final BakeryServiceType serviceType;
  final double basePrice;
  final bool customizationAvailable;
  final int leadTimeHours;
  final bool designUploadRequired;
  final List<String> sizeOptions;
  final List<String> flavorOptions;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BakeryService({
    required this.id,
    required this.name,
    required this.serviceType,
    required this.basePrice,
    this.customizationAvailable = false,
    this.leadTimeHours = 24,
    this.designUploadRequired = false,
    this.sizeOptions = const [],
    this.flavorOptions = const [],
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
        customizationAvailable,
        leadTimeHours,
        designUploadRequired,
        sizeOptions,
        flavorOptions,
        isActive,
        createdAt,
        updatedAt,
      ];

  /// Get service type display name
  String get serviceTypeDisplayName {
    switch (serviceType) {
      case BakeryServiceType.freshBakery:
        return 'Fresh Bakery';
      case BakeryServiceType.customCake:
        return 'Custom Cake';
      case BakeryServiceType.occasionCake:
        return 'Occasion Cake';
    }
  }

  /// Get lead time display
  String get leadTimeDisplay {
    if (leadTimeHours < 24) {
      return '$leadTimeHours hours';
    } else {
      final days = (leadTimeHours / 24).round();
      return '$days ${days == 1 ? 'day' : 'days'}';
    }
  }

  /// Check if service requires advance booking
  bool get requiresAdvanceBooking {
    return leadTimeHours > 2;
  }
}

/// Bakery order specifications entity
class BakeryOrderSpecifications extends Equatable {
  final String? size;
  final String? flavor;
  final String? design;
  final String? message;
  final Map<String, dynamic> customOptions;

  const BakeryOrderSpecifications({
    this.size,
    this.flavor,
    this.design,
    this.message,
    this.customOptions = const {},
  });

  @override
  List<Object?> get props => [size, flavor, design, message, customOptions];

  Map<String, dynamic> toJson() {
    return {
      'size': size,
      'flavor': flavor,
      'design': design,
      'message': message,
      'custom_options': customOptions,
    };
  }

  factory BakeryOrderSpecifications.fromJson(Map<String, dynamic> json) {
    return BakeryOrderSpecifications(
      size: json['size'],
      flavor: json['flavor'],
      design: json['design'],
      message: json['message'],
      customOptions: json['custom_options'] ?? {},
    );
  }

  /// Create a copy with updated values
  BakeryOrderSpecifications copyWith({
    String? size,
    String? flavor,
    String? design,
    String? message,
    Map<String, dynamic>? customOptions,
  }) {
    return BakeryOrderSpecifications(
      size: size ?? this.size,
      flavor: flavor ?? this.flavor,
      design: design ?? this.design,
      message: message ?? this.message,
      customOptions: customOptions ?? this.customOptions,
    );
  }
}

/// Bakery order entity
class BakeryOrder extends Equatable {
  final String id;
  final String userId;
  final String serviceId;
  final String? vendorId;
  final String? deliveryAddressId;
  final BakeryServiceType orderType;
  final BakeryOrderSpecifications specifications;
  final List<String> designImages;
  final DateTime? deliveryDate;
  final String? deliveryTimeSlot;
  final double? estimatedPrice;
  final double? finalPrice;
  final BakeryOrderStatus status;
  final String? specialInstructions;
  final String? vendorNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BakeryOrder({
    required this.id,
    required this.userId,
    required this.serviceId,
    this.vendorId,
    this.deliveryAddressId,
    required this.orderType,
    this.specifications = const BakeryOrderSpecifications(),
    this.designImages = const [],
    this.deliveryDate,
    this.deliveryTimeSlot,
    this.estimatedPrice,
    this.finalPrice,
    this.status = BakeryOrderStatus.pending,
    this.specialInstructions,
    this.vendorNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        serviceId,
        vendorId,
        deliveryAddressId,
        orderType,
        specifications,
        designImages,
        deliveryDate,
        deliveryTimeSlot,
        estimatedPrice,
        finalPrice,
        status,
        specialInstructions,
        vendorNotes,
        createdAt,
        updatedAt,
      ];

  /// Get status display name
  String get statusDisplayName {
    switch (status) {
      case BakeryOrderStatus.pending:
        return 'Pending';
      case BakeryOrderStatus.confirmed:
        return 'Confirmed';
      case BakeryOrderStatus.inPreparation:
        return 'In Preparation';
      case BakeryOrderStatus.ready:
        return 'Ready';
      case BakeryOrderStatus.delivered:
        return 'Delivered';
      case BakeryOrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Check if order can be cancelled
  bool get canBeCancelled {
    return status == BakeryOrderStatus.pending ||
           status == BakeryOrderStatus.confirmed;
  }

  /// Check if order is completed
  bool get isCompleted {
    return status == BakeryOrderStatus.delivered;
  }

  /// Check if order requires design upload
  bool get requiresDesignUpload {
    return orderType == BakeryServiceType.customCake ||
           orderType == BakeryServiceType.occasionCake;
  }

  /// Get order type display name
  String get orderTypeDisplayName {
    switch (orderType) {
      case BakeryServiceType.freshBakery:
        return 'Fresh Bakery';
      case BakeryServiceType.customCake:
        return 'Custom Order';
      case BakeryServiceType.occasionCake:
        return 'Occasion Cake';
    }
  }
}

/// Bakery vendor entity
class BakeryVendor extends Equatable {
  final String id;
  final String vendorId;
  final List<BakeryServiceType> specializations;
  final int customOrderCapacity;
  final int leadTimeHours;
  final Map<String, dynamic> designCapabilities;
  final List<String> deliveryAreas;
  final Map<String, dynamic> pricingConfig;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BakeryVendor({
    required this.id,
    required this.vendorId,
    this.specializations = const [],
    this.customOrderCapacity = 5,
    this.leadTimeHours = 24,
    this.designCapabilities = const {},
    this.deliveryAreas = const [],
    this.pricingConfig = const {},
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        vendorId,
        specializations,
        customOrderCapacity,
        leadTimeHours,
        designCapabilities,
        deliveryAreas,
        pricingConfig,
        isActive,
        createdAt,
        updatedAt,
      ];

  /// Check if vendor specializes in a specific service type
  bool specializesIn(BakeryServiceType serviceType) {
    return specializations.contains(serviceType);
  }

  /// Check if vendor delivers to a specific area
  bool deliversTo(String area) {
    return deliveryAreas.contains(area);
  }

  /// Check if vendor can handle custom designs
  bool get canHandleCustomDesigns {
    return designCapabilities['custom_designs'] == true;
  }

  /// Check if vendor can make photo cakes
  bool get canMakePhotoCakes {
    return designCapabilities['photo_cakes'] == true;
  }

  /// Check if vendor can make 3D cakes
  bool get canMake3DCakes {
    return designCapabilities['3d_cakes'] == true;
  }
}
