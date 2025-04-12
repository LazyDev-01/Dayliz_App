import 'package:equatable/equatable.dart';

class Address extends Equatable {
  final String? id;
  final String userId;
  final String name;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String country;
  final String postalCode;
  final String phoneNumber;
  final bool isDefault;
  final double? latitude;
  final double? longitude;
  final String? landmark;
  final String? addressType; // 'home', 'work', 'other'
  final String? additionalInfo;
  final String? street;
  final String? phone;

  const Address({
    this.id,
    required this.userId,
    required this.name,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.country,
    required this.postalCode,
    required this.phoneNumber,
    this.isDefault = false,
    this.latitude,
    this.longitude,
    this.landmark,
    this.addressType = 'home',
    this.additionalInfo,
    this.street,
    this.phone,
  });

  Address copyWith({
    String? id,
    String? userId,
    String? name,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? country,
    String? postalCode,
    String? phoneNumber,
    bool? isDefault,
    double? latitude,
    double? longitude,
    String? landmark,
    String? addressType,
    String? additionalInfo,
    String? street,
    String? phone,
  }) {
    return Address(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      postalCode: postalCode ?? this.postalCode,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isDefault: isDefault ?? this.isDefault,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      landmark: landmark ?? this.landmark,
      addressType: addressType ?? this.addressType,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      street: street ?? this.street,
      phone: phone ?? this.phone,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'name': name,
      'address_line1': addressLine1,
      'address_line2': addressLine2,
      'city': city,
      'state': state,
      'country': country,
      'postal_code': postalCode,
      'phone_number': phoneNumber,
      'is_default': isDefault,
      'latitude': latitude,
      'longitude': longitude,
      'landmark': landmark,
      'address_type': addressType,
      'additional_info': additionalInfo,
      if (street != null) 'street': street,
      if (phone != null) 'phone': phone,
    };
  }

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'],
      userId: json['user_id'] ?? '',
      name: json['name'] ?? '',
      addressLine1: json['address_line1'] ?? '',
      addressLine2: json['address_line2'],
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      country: json['country'] ?? '',
      postalCode: json['postal_code'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      isDefault: json['is_default'] ?? false,
      latitude: json['latitude'],
      longitude: json['longitude'],
      landmark: json['landmark'],
      addressType: json['address_type'] ?? 'home',
      additionalInfo: json['additional_info'],
      street: json['street'],
      phone: json['phone'],
    );
  }

  @override
  List<Object?> get props => [
    id, 
    userId, 
    name, 
    addressLine1, 
    addressLine2, 
    city, 
    state, 
    country, 
    postalCode, 
    phoneNumber, 
    isDefault,
    latitude,
    longitude,
    landmark,
    addressType,
    additionalInfo,
    street,
    phone,
  ];

  String get fullAddress {
    final parts = [
      addressLine1,
      if (addressLine2 != null && addressLine2!.isNotEmpty) addressLine2,
      if (landmark != null && landmark!.isNotEmpty) 'Landmark: $landmark',
      '$city, $state',
      '$country - $postalCode',
    ];
    return parts.join(', ');
  }

  String get formattedAddress {
    return street != null ? 
      '$street, $city, $state, $postalCode, $country' : 
      '$addressLine1, ${addressLine2 != null ? "$addressLine2, " : ""}$city, $state, $postalCode, $country';
  }

  String get shortAddress {
    return '$city, $state, $postalCode';
  }
} 