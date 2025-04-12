import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

class Address extends Equatable {
  final String id;
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
  final String? street;
  final String? phone;

  const Address({
    required this.id,
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
    this.addressType,
    this.street,
    this.phone,
  });

  factory Address.create({
    String? id,
    required String userId,
    required String name,
    required String addressLine1,
    String? addressLine2,
    required String city,
    required String state,
    required String country,
    required String postalCode,
    required String phoneNumber,
    bool isDefault = false,
    double? latitude,
    double? longitude,
    String? landmark,
    String? addressType,
    String? street,
    String? phone,
  }) {
    return Address(
      id: id ?? const Uuid().v4(),
      userId: userId,
      name: name,
      addressLine1: addressLine1,
      addressLine2: addressLine2,
      city: city,
      state: state,
      country: country,
      postalCode: postalCode,
      phoneNumber: phoneNumber,
      isDefault: isDefault,
      latitude: latitude,
      longitude: longitude,
      landmark: landmark,
      addressType: addressType,
      street: street,
      phone: phone,
    );
  }

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
      street: street ?? this.street,
      phone: phone ?? this.phone,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'address_line1': addressLine1,
      'address_line2': addressLine2,
      'city': city,
      'state': state,
      'country': country,
      'postal_code': postalCode,
      'phone': phoneNumber,
      'is_default': isDefault,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] ?? const Uuid().v4(),
      userId: json['user_id'] ?? '',
      name: json['name'] ?? '',
      addressLine1: json['address_line1'] ?? '',
      addressLine2: json['address_line2'],
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      country: json['country'] ?? '',
      postalCode: json['postal_code'] ?? '',
      phoneNumber: json['phone'] ?? '',
      isDefault: json['is_default'] ?? false,
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      landmark: null,
      addressType: null,
      street: null,
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