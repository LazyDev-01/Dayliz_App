import 'package:equatable/equatable.dart';
import 'delivery_zone.dart';
import 'town.dart';

/// Result of zone detection for a given coordinate
class ZoneDetectionResult extends Equatable {
  final bool isInZone;
  final DeliveryZone? zone;
  final Town? town;
  final LatLng coordinates;
  final String? errorMessage;
  
  // Delivery information (derived from zone/town)
  final int? deliveryFee;
  final int? minOrderAmount;
  final String? estimatedDeliveryTime;

  const ZoneDetectionResult._({
    required this.isInZone,
    this.zone,
    this.town,
    required this.coordinates,
    this.errorMessage,
    this.deliveryFee,
    this.minOrderAmount,
    this.estimatedDeliveryTime,
  });

  /// Factory constructor for successful zone detection
  factory ZoneDetectionResult.found({
    required DeliveryZone zone,
    required Town town,
    required LatLng coordinates,
  }) {
    return ZoneDetectionResult._(
      isInZone: true,
      zone: zone,
      town: town,
      coordinates: coordinates,
      deliveryFee: zone.customDeliveryFee ?? town.deliveryFee,
      minOrderAmount: zone.customMinOrder ?? town.minOrderAmount,
      estimatedDeliveryTime: zone.customDeliveryTime ?? town.estimatedDeliveryTime,
    );
  }

  /// Factory constructor for when no zone is found
  factory ZoneDetectionResult.notFound({
    required LatLng coordinates,
    String? message,
  }) {
    return ZoneDetectionResult._(
      isInZone: false,
      coordinates: coordinates,
      errorMessage: message ?? 'No delivery zone found for this location',
    );
  }

  /// Factory constructor for errors during detection
  factory ZoneDetectionResult.error({
    required LatLng coordinates,
    required String errorMessage,
  }) {
    return ZoneDetectionResult._(
      isInZone: false,
      coordinates: coordinates,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        isInZone,
        zone,
        town,
        coordinates,
        errorMessage,
        deliveryFee,
        minOrderAmount,
        estimatedDeliveryTime,
      ];

  /// Check if the result represents a successful zone detection
  bool get isSuccess => isInZone && zone != null && town != null;

  /// Check if the result represents an error
  bool get isError => errorMessage != null;

  /// Get the zone name or a default message
  String get zoneName => zone?.name ?? 'Unknown Zone';

  /// Get the town name or a default message
  String get townName => town?.name ?? 'Unknown Town';

  /// Get a user-friendly message about the detection result
  String get userMessage {
    if (isSuccess) {
      return 'Great! We deliver to ${zone!.name} in ${town!.name}';
    } else if (errorMessage != null) {
      return errorMessage!;
    } else {
      return 'Sorry, we don\'t deliver to this area yet';
    }
  }

  /// Get delivery information as a formatted string
  String get deliveryInfo {
    if (!isSuccess) return '';
    
    final fee = deliveryFee ?? 0;
    final minOrder = minOrderAmount ?? 0;
    final time = estimatedDeliveryTime ?? 'Unknown';
    
    return 'Delivery: ₹$fee • Min Order: ₹$minOrder • Time: $time';
  }

  @override
  String toString() {
    return 'ZoneDetectionResult(isInZone: $isInZone, zone: ${zone?.name}, town: ${town?.name}, coordinates: $coordinates)';
  }
}
