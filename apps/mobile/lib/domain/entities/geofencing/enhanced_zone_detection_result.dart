import 'package:equatable/equatable.dart';
import 'delivery_zone.dart';
import 'city_boundary.dart';
import 'town.dart';

/// Enum representing different levels of access based on location
enum AccessLevel {
  /// User is within delivery zone - full app access with ordering
  fullAccess,
  
  /// User is within city but outside delivery zone - viewing only
  viewingOnly,
  
  /// User is outside city boundaries - no access
  noAccess,
}

/// Enhanced zone detection result for two-tier location validation
class EnhancedZoneDetectionResult extends Equatable {
  final AccessLevel accessLevel;
  final LatLng coordinates;
  final DeliveryZone? deliveryZone;
  final Town? town;
  final CityBoundary? cityBoundary;
  final bool canOrder;
  final bool canBrowse;
  final String message;
  final String? errorMessage;
  final DateTime detectedAt;

  const EnhancedZoneDetectionResult({
    required this.accessLevel,
    required this.coordinates,
    this.deliveryZone,
    this.town,
    this.cityBoundary,
    required this.canOrder,
    required this.canBrowse,
    required this.message,
    this.errorMessage,
    required this.detectedAt,
  });

  /// Factory constructor for full access (within delivery zone)
  factory EnhancedZoneDetectionResult.fullAccess({
    required LatLng coordinates,
    required DeliveryZone deliveryZone,
    required Town town,
    CityBoundary? cityBoundary,
  }) {
    return EnhancedZoneDetectionResult(
      accessLevel: AccessLevel.fullAccess,
      coordinates: coordinates,
      deliveryZone: deliveryZone,
      town: town,
      cityBoundary: cityBoundary,
      canOrder: true,
      canBrowse: true,
      message: 'Great! We deliver to your area.',
      detectedAt: DateTime.now(),
    );
  }

  /// Factory constructor for viewing only (in city but outside delivery zone)
  factory EnhancedZoneDetectionResult.viewingOnly({
    required LatLng coordinates,
    required CityBoundary cityBoundary,
    String? customMessage,
  }) {
    return EnhancedZoneDetectionResult(
      accessLevel: AccessLevel.viewingOnly,
      coordinates: coordinates,
      cityBoundary: cityBoundary,
      canOrder: false,
      canBrowse: true,
      message: customMessage ?? 'You can browse our products, but we don\'t deliver to this area yet.',
      detectedAt: DateTime.now(),
    );
  }

  /// Factory constructor for no access (outside city)
  factory EnhancedZoneDetectionResult.noAccess({
    required LatLng coordinates,
    String? customMessage,
  }) {
    return EnhancedZoneDetectionResult(
      accessLevel: AccessLevel.noAccess,
      coordinates: coordinates,
      canOrder: false,
      canBrowse: false,
      message: customMessage ?? 'We don\'t serve this area yet, but we\'re expanding soon!',
      detectedAt: DateTime.now(),
    );
  }

  /// Factory constructor for error cases
  factory EnhancedZoneDetectionResult.error({
    required LatLng coordinates,
    required String errorMessage,
  }) {
    return EnhancedZoneDetectionResult(
      accessLevel: AccessLevel.noAccess,
      coordinates: coordinates,
      canOrder: false,
      canBrowse: false,
      message: 'Unable to determine service availability.',
      errorMessage: errorMessage,
      detectedAt: DateTime.now(),
    );
  }

  /// Check if this result indicates success (any level of access)
  bool get isSuccess => accessLevel != AccessLevel.noAccess && errorMessage == null;

  /// Check if this result has an error
  bool get hasError => errorMessage != null;

  /// Get user-friendly access description
  String get accessDescription {
    switch (accessLevel) {
      case AccessLevel.fullAccess:
        return 'Full access with delivery';
      case AccessLevel.viewingOnly:
        return 'Viewing mode - no delivery';
      case AccessLevel.noAccess:
        return 'No access';
    }
  }

  /// Get delivery zone name if available
  String? get deliveryZoneName => deliveryZone?.name;

  /// Get city name if available
  String? get cityName => cityBoundary?.name;

  /// Get town name if available
  String? get townName => town?.name;

  /// Creates a copy of this result with the given fields replaced
  EnhancedZoneDetectionResult copyWith({
    AccessLevel? accessLevel,
    LatLng? coordinates,
    DeliveryZone? deliveryZone,
    Town? town,
    CityBoundary? cityBoundary,
    bool? canOrder,
    bool? canBrowse,
    String? message,
    String? errorMessage,
    DateTime? detectedAt,
    bool clearError = false,
  }) {
    return EnhancedZoneDetectionResult(
      accessLevel: accessLevel ?? this.accessLevel,
      coordinates: coordinates ?? this.coordinates,
      deliveryZone: deliveryZone ?? this.deliveryZone,
      town: town ?? this.town,
      cityBoundary: cityBoundary ?? this.cityBoundary,
      canOrder: canOrder ?? this.canOrder,
      canBrowse: canBrowse ?? this.canBrowse,
      message: message ?? this.message,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      detectedAt: detectedAt ?? this.detectedAt,
    );
  }

  @override
  List<Object?> get props => [
        accessLevel,
        coordinates,
        deliveryZone,
        town,
        cityBoundary,
        canOrder,
        canBrowse,
        message,
        errorMessage,
        detectedAt,
      ];

  @override
  String toString() {
    return 'EnhancedZoneDetectionResult('
           'accessLevel: $accessLevel, '
           'canOrder: $canOrder, '
           'canBrowse: $canBrowse, '
           'message: $message, '
           'deliveryZone: ${deliveryZone?.name}, '
           'city: ${cityBoundary?.name}'
           ')';
  }
}
