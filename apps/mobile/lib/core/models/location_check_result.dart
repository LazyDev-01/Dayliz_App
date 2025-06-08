import '../../domain/entities/geofencing/delivery_zone.dart';

/// Enum for location check status
enum LocationStatus {
  success,
  outsideZone,
  gpsDisabled,
  permissionDenied,
  lowAccuracy,
  timeout,
  error,
}

/// Result of background location check
class LocationCheckResult {
  final LocationStatus status;
  final LatLng? coordinates;
  final DeliveryZone? zone;
  final String? errorMessage;
  final double? accuracy;

  const LocationCheckResult._({
    required this.status,
    this.coordinates,
    this.zone,
    this.errorMessage,
    this.accuracy,
  });

  /// Location check successful - user is in a delivery zone
  factory LocationCheckResult.success(LatLng coordinates, DeliveryZone? zone, {double? accuracy}) {
    return LocationCheckResult._(
      status: LocationStatus.success,
      coordinates: coordinates,
      zone: zone,
      accuracy: accuracy,
    );
  }

  /// User location is outside all delivery zones
  factory LocationCheckResult.outsideZone(LatLng coordinates, {double? accuracy}) {
    return LocationCheckResult._(
      status: LocationStatus.outsideZone,
      coordinates: coordinates,
      accuracy: accuracy,
    );
  }

  /// GPS/Location services are disabled
  factory LocationCheckResult.gpsDisabled() {
    return const LocationCheckResult._(
      status: LocationStatus.gpsDisabled,
      errorMessage: 'Location services are disabled',
    );
  }

  /// Location permission denied
  factory LocationCheckResult.permissionDenied() {
    return const LocationCheckResult._(
      status: LocationStatus.permissionDenied,
      errorMessage: 'Location permission denied',
    );
  }

  /// GPS accuracy is too low for reliable zone detection
  factory LocationCheckResult.lowAccuracy(LatLng coordinates, double accuracy) {
    return LocationCheckResult._(
      status: LocationStatus.lowAccuracy,
      coordinates: coordinates,
      accuracy: accuracy,
      errorMessage: 'GPS accuracy too low: ${accuracy.toStringAsFixed(0)}m',
    );
  }

  /// Location check timed out
  factory LocationCheckResult.timeout() {
    return const LocationCheckResult._(
      status: LocationStatus.timeout,
      errorMessage: 'Location check timed out',
    );
  }

  /// Error occurred during location check
  factory LocationCheckResult.error(String message) {
    return LocationCheckResult._(
      status: LocationStatus.error,
      errorMessage: message,
    );
  }

  /// Check if location check was successful
  bool get isSuccess => status == LocationStatus.success;

  /// Check if user is outside delivery zones
  bool get isOutsideZone => status == LocationStatus.outsideZone;

  /// Check if location setup screen should be shown
  bool get shouldShowSetupScreen => !isSuccess;

  /// Get user-friendly error message
  String get userFriendlyMessage {
    switch (status) {
      case LocationStatus.success:
        return 'Location confirmed';
      case LocationStatus.outsideZone:
        return 'We\'re not in your neighborhood yet, but we\'re working on it!';
      case LocationStatus.gpsDisabled:
        return 'Please enable location services to continue';
      case LocationStatus.permissionDenied:
        return 'Location permission is required to use Dayliz';
      case LocationStatus.lowAccuracy:
        return 'Unable to get accurate location. Please try again.';
      case LocationStatus.timeout:
        return 'Location detection is taking too long. Please try again.';
      case LocationStatus.error:
        return errorMessage ?? 'Something went wrong. Please try again.';
    }
  }

  @override
  String toString() {
    return 'LocationCheckResult(status: $status, coordinates: $coordinates, zone: ${zone?.name}, error: $errorMessage)';
  }
}
