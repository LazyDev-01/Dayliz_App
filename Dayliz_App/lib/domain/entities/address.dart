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

  /// Type of address (e.g., "home", "work", "other")
  final String? addressType;

  /// Additional information about the address
  final String? additionalInfo;

  /// Latitude coordinate for this address
  final double? latitude;

  /// Longitude coordinate for this address
  final double? longitude;

  /// Landmark for easier location identification (critical for Tura)
  final String? landmark;

  /// ID of the zone this address belongs to
  final String? zoneId;

  /// Name of the recipient at this address
  final String? recipientName;

  /// When this address was created
  final DateTime? createdAt;

  /// When this address was last updated
  final DateTime? updatedAt;

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
    this.addressType,
    this.additionalInfo,
    this.latitude,
    this.longitude,
    this.landmark,
    this.zoneId,
    this.recipientName,
    this.createdAt,
    this.updatedAt,
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
    String? addressType,
    String? additionalInfo,
    double? latitude,
    double? longitude,
    String? landmark,
    String? zoneId,
    String? recipientName,
    DateTime? createdAt,
    DateTime? updatedAt,
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
      addressType: addressType ?? this.addressType,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      landmark: landmark ?? this.landmark,
      zoneId: zoneId ?? this.zoneId,
      recipientName: recipientName ?? this.recipientName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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

        addressType,
        additionalInfo,
        latitude,
        longitude,
        landmark,
        zoneId,
        recipientName,
        createdAt,
        updatedAt,
      ];
}