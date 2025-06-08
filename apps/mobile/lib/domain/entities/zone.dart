import 'package:equatable/equatable.dart';

/// Domain entity representing a delivery zone
class Zone extends Equatable {
  final String id;
  final String name;
  final String? description;
  final double? deliveryFee;
  final double? minimumOrderAmount;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Zone({
    required this.id,
    required this.name,
    this.description,
    this.deliveryFee,
    this.minimumOrderAmount,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        deliveryFee,
        minimumOrderAmount,
        isActive,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'Zone(id: $id, name: $name, isActive: $isActive)';
  }
}

/// Domain entity representing location coordinates
class LocationCoordinates extends Equatable {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final DateTime? timestamp;

  const LocationCoordinates({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.timestamp,
  });

  @override
  List<Object?> get props => [latitude, longitude, accuracy, timestamp];

  @override
  String toString() {
    return 'LocationCoordinates(lat: $latitude, lng: $longitude, accuracy: $accuracy)';
  }
}

/// Domain entity representing zone validation result
class ZoneValidationResult extends Equatable {
  final bool isValid;
  final Zone? zone;
  final String? errorMessage;
  final LocationCoordinates coordinates;

  const ZoneValidationResult({
    required this.isValid,
    this.zone,
    this.errorMessage,
    required this.coordinates,
  });

  const ZoneValidationResult.valid({
    required Zone zone,
    required LocationCoordinates coordinates,
  }) : this(
          isValid: true,
          zone: zone,
          coordinates: coordinates,
        );

  const ZoneValidationResult.invalid({
    required String errorMessage,
    required LocationCoordinates coordinates,
  }) : this(
          isValid: false,
          errorMessage: errorMessage,
          coordinates: coordinates,
        );

  @override
  List<Object?> get props => [isValid, zone, errorMessage, coordinates];

  @override
  String toString() {
    return 'ZoneValidationResult(isValid: $isValid, zone: $zone, error: $errorMessage)';
  }
}
