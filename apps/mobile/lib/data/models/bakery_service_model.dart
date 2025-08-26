import '../../domain/entities/bakery_service.dart';

/// BakeryService model extending the domain entity
class BakeryServiceModel extends BakeryService {
  const BakeryServiceModel({
    required String id,
    required String name,
    required BakeryServiceType serviceType,
    required double basePrice,
    bool customizationAvailable = false,
    int leadTimeHours = 24,
    bool designUploadRequired = false,
    List<String> sizeOptions = const [],
    List<String> flavorOptions = const [],
    bool isActive = true,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(
          id: id,
          name: name,
          serviceType: serviceType,
          basePrice: basePrice,
          customizationAvailable: customizationAvailable,
          leadTimeHours: leadTimeHours,
          designUploadRequired: designUploadRequired,
          sizeOptions: sizeOptions,
          flavorOptions: flavorOptions,
          isActive: isActive,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  /// Create BakeryServiceModel from JSON
  factory BakeryServiceModel.fromJson(Map<String, dynamic> json) {
    return BakeryServiceModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      serviceType: _parseServiceType(json['service_type']),
      basePrice: (json['base_price'] ?? 0.0).toDouble(),
      customizationAvailable: json['customization_available'] ?? false,
      leadTimeHours: json['lead_time_hours'] ?? 24,
      designUploadRequired: json['design_upload_required'] ?? false,
      sizeOptions: _parseOptions(json['size_options']),
      flavorOptions: _parseOptions(json['flavor_options']),
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// Convert BakeryServiceModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'service_type': _serviceTypeToString(serviceType),
      'base_price': basePrice,
      'customization_available': customizationAvailable,
      'lead_time_hours': leadTimeHours,
      'design_upload_required': designUploadRequired,
      'size_options': sizeOptions,
      'flavor_options': flavorOptions,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Parse service type from string
  static BakeryServiceType _parseServiceType(String? serviceType) {
    switch (serviceType) {
      case 'fresh_bakery':
        return BakeryServiceType.freshBakery;
      case 'custom_cake':
        return BakeryServiceType.customCake;
      case 'occasion_cake':
        return BakeryServiceType.occasionCake;
      default:
        return BakeryServiceType.freshBakery;
    }
  }

  /// Convert service type to string
  static String _serviceTypeToString(BakeryServiceType serviceType) {
    switch (serviceType) {
      case BakeryServiceType.freshBakery:
        return 'fresh_bakery';
      case BakeryServiceType.customCake:
        return 'custom_cake';
      case BakeryServiceType.occasionCake:
        return 'occasion_cake';
    }
  }

  /// Parse options from JSON
  static List<String> _parseOptions(dynamic options) {
    if (options == null) return [];
    if (options is List) {
      return options.map((option) => option.toString()).toList();
    }
    return [];
  }
}

/// BakeryOrder model extending the domain entity
class BakeryOrderModel extends BakeryOrder {
  const BakeryOrderModel({
    required String id,
    required String userId,
    required String serviceId,
    String? vendorId,
    String? deliveryAddressId,
    required BakeryServiceType orderType,
    BakeryOrderSpecifications specifications = const BakeryOrderSpecifications(),
    List<String> designImages = const [],
    DateTime? deliveryDate,
    String? deliveryTimeSlot,
    double? estimatedPrice,
    double? finalPrice,
    BakeryOrderStatus status = BakeryOrderStatus.pending,
    String? specialInstructions,
    String? vendorNotes,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(
          id: id,
          userId: userId,
          serviceId: serviceId,
          vendorId: vendorId,
          deliveryAddressId: deliveryAddressId,
          orderType: orderType,
          specifications: specifications,
          designImages: designImages,
          deliveryDate: deliveryDate,
          deliveryTimeSlot: deliveryTimeSlot,
          estimatedPrice: estimatedPrice,
          finalPrice: finalPrice,
          status: status,
          specialInstructions: specialInstructions,
          vendorNotes: vendorNotes,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  /// Create BakeryOrderModel from JSON
  factory BakeryOrderModel.fromJson(Map<String, dynamic> json) {
    return BakeryOrderModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      serviceId: json['service_id'] ?? '',
      vendorId: json['vendor_id'],
      deliveryAddressId: json['delivery_address_id'],
      orderType: BakeryServiceModel._parseServiceType(json['order_type']),
      specifications: _parseSpecifications(json['specifications']),
      designImages: _parseDesignImages(json['design_images']),
      deliveryDate: json['delivery_date'] != null ? DateTime.parse(json['delivery_date']) : null,
      deliveryTimeSlot: json['delivery_time_slot'],
      estimatedPrice: json['estimated_price']?.toDouble(),
      finalPrice: json['final_price']?.toDouble(),
      status: _parseOrderStatus(json['status']),
      specialInstructions: json['special_instructions'],
      vendorNotes: json['vendor_notes'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// Convert BakeryOrderModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'service_id': serviceId,
      'vendor_id': vendorId,
      'delivery_address_id': deliveryAddressId,
      'order_type': BakeryServiceModel._serviceTypeToString(orderType),
      'specifications': specifications.toJson(),
      'design_images': designImages,
      'delivery_date': deliveryDate?.toIso8601String().split('T')[0],
      'delivery_time_slot': deliveryTimeSlot,
      'estimated_price': estimatedPrice,
      'final_price': finalPrice,
      'status': _orderStatusToString(status),
      'special_instructions': specialInstructions,
      'vendor_notes': vendorNotes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Parse specifications from JSON
  static BakeryOrderSpecifications _parseSpecifications(dynamic specifications) {
    if (specifications == null) return const BakeryOrderSpecifications();
    if (specifications is Map<String, dynamic>) {
      return BakeryOrderSpecifications.fromJson(specifications);
    }
    return const BakeryOrderSpecifications();
  }

  /// Parse design images from JSON
  static List<String> _parseDesignImages(dynamic designImages) {
    if (designImages == null) return [];
    if (designImages is List) {
      return designImages.map((image) => image.toString()).toList();
    }
    return [];
  }

  /// Parse order status from string
  static BakeryOrderStatus _parseOrderStatus(String? status) {
    switch (status) {
      case 'pending':
        return BakeryOrderStatus.pending;
      case 'confirmed':
        return BakeryOrderStatus.confirmed;
      case 'in_preparation':
        return BakeryOrderStatus.inPreparation;
      case 'ready':
        return BakeryOrderStatus.ready;
      case 'delivered':
        return BakeryOrderStatus.delivered;
      case 'cancelled':
        return BakeryOrderStatus.cancelled;
      default:
        return BakeryOrderStatus.pending;
    }
  }

  /// Convert order status to string
  static String _orderStatusToString(BakeryOrderStatus status) {
    switch (status) {
      case BakeryOrderStatus.pending:
        return 'pending';
      case BakeryOrderStatus.confirmed:
        return 'confirmed';
      case BakeryOrderStatus.inPreparation:
        return 'in_preparation';
      case BakeryOrderStatus.ready:
        return 'ready';
      case BakeryOrderStatus.delivered:
        return 'delivered';
      case BakeryOrderStatus.cancelled:
        return 'cancelled';
    }
  }
}

/// BakeryVendor model extending the domain entity
class BakeryVendorModel extends BakeryVendor {
  const BakeryVendorModel({
    required String id,
    required String vendorId,
    List<BakeryServiceType> specializations = const [],
    int customOrderCapacity = 5,
    int leadTimeHours = 24,
    Map<String, dynamic> designCapabilities = const {},
    List<String> deliveryAreas = const [],
    Map<String, dynamic> pricingConfig = const {},
    bool isActive = true,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(
          id: id,
          vendorId: vendorId,
          specializations: specializations,
          customOrderCapacity: customOrderCapacity,
          leadTimeHours: leadTimeHours,
          designCapabilities: designCapabilities,
          deliveryAreas: deliveryAreas,
          pricingConfig: pricingConfig,
          isActive: isActive,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  /// Create BakeryVendorModel from JSON
  factory BakeryVendorModel.fromJson(Map<String, dynamic> json) {
    return BakeryVendorModel(
      id: json['id'] ?? '',
      vendorId: json['vendor_id'] ?? '',
      specializations: _parseSpecializations(json['specializations']),
      customOrderCapacity: json['custom_order_capacity'] ?? 5,
      leadTimeHours: json['lead_time_hours'] ?? 24,
      designCapabilities: json['design_capabilities'] ?? {},
      deliveryAreas: _parseDeliveryAreas(json['delivery_areas']),
      pricingConfig: json['pricing_config'] ?? {},
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// Parse specializations from JSON
  static List<BakeryServiceType> _parseSpecializations(dynamic specializations) {
    if (specializations == null) return [];
    if (specializations is List) {
      return specializations
          .map((type) => BakeryServiceModel._parseServiceType(type.toString()))
          .toList();
    }
    return [];
  }

  /// Parse delivery areas from JSON
  static List<String> _parseDeliveryAreas(dynamic deliveryAreas) {
    if (deliveryAreas == null) return [];
    if (deliveryAreas is List) {
      return deliveryAreas.map((area) => area.toString()).toList();
    }
    return [];
  }
}
