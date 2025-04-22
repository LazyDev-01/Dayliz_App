import 'package:equatable/equatable.dart';

/// Entity class representing a user address in the domain layer
class Address extends Equatable {
  final String id;
  final String name;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final String? phoneNumber;
  final bool isDefault;
  final String? additionalInfo;
  final Map<String, double>? coordinates;

  const Address({
    required this.id,
    required this.name,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    this.phoneNumber,
    this.isDefault = false,
    this.additionalInfo,
    this.coordinates,
  });

  /// Create a copy of the address with updated fields
  Address copyWith({
    String? id,
    String? name,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    String? phoneNumber,
    bool? isDefault,
    String? additionalInfo,
    Map<String, double>? coordinates,
  }) {
    return Address(
      id: id ?? this.id,
      name: name ?? this.name,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isDefault: isDefault ?? this.isDefault,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      coordinates: coordinates ?? this.coordinates,
    );
  }

  // This getter is needed for compatibility with the clean_address_list_screen.dart
  String get street => addressLine1;

  @override
  List<Object?> get props => [
    id,
    name,
    addressLine1,
    addressLine2,
    city,
    state,
    postalCode,
    country,
    phoneNumber,
    isDefault,
    additionalInfo,
    coordinates,
  ];
} 