import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Represents a user address entity
@immutable
class Address extends Equatable {
  /// Unique identifier for this address
  final String id;
  
  /// The user ID this address belongs to
  final String userId;
  
  /// First line of the address
  final String addressLine1;
  
  /// Second line of the address (optional)
  final String addressLine2;
  
  /// City name
  final String city;
  
  /// State or province
  final String state;
  
  /// Postal or ZIP code
  final String postalCode;
  
  /// Country name
  final String country;
  
  /// Phone number associated with this address
  final String? phoneNumber;
  
  /// Whether this is the default address
  final bool isDefault;
  
  /// A label for this address (e.g., "Home", "Work")
  final String label;
  
  /// Additional information about the address
  final String? additionalInfo;
  
  /// Geographic coordinates for this address
  final Map<String, double>? coordinates;

  /// Creates a new Address instance
  const Address({
    required this.id,
    required this.userId,
    required this.addressLine1,
    this.addressLine2 = '',
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    this.phoneNumber,
    this.isDefault = false,
    this.label = 'Home',
    this.additionalInfo,
    this.coordinates,
  });

  /// Creates a copy of this address with the given fields replaced with new values
  Address copyWith({
    String? id,
    String? userId,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    String? phoneNumber,
    bool? isDefault,
    String? label,
    String? additionalInfo,
    Map<String, double>? coordinates,
  }) {
    return Address(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isDefault: isDefault ?? this.isDefault,
      label: label ?? this.label,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      coordinates: coordinates ?? this.coordinates,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        addressLine1,
        addressLine2,
        city,
        state,
        postalCode,
        country,
        phoneNumber,
        isDefault,
        label,
        additionalInfo,
        coordinates,
      ];
} 