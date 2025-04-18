import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

class Address extends Equatable {
  final String id;
  final String userId;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final bool isDefault;
  final String? addressType;
  final String? recipientName;
  final String? recipientPhone;
  final String? landmark;
  final double? latitude;
  final double? longitude;
  final String? zone;
  final String? zoneId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Address({
    required this.id,
    required this.userId,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    this.isDefault = false,
    this.addressType,
    this.recipientName,
    this.recipientPhone,
    this.landmark,
    this.latitude,
    this.longitude,
    this.zone,
    this.zoneId,
    this.createdAt,
    this.updatedAt,
  });

  factory Address.create({
    String? id,
    required String userId,
    required String addressLine1,
    String? addressLine2,
    required String city,
    required String state,
    required String postalCode,
    required String country,
    bool isDefault = false,
    String? addressType,
    String? recipientName,
    String? recipientPhone,
    String? landmark,
    double? latitude,
    double? longitude,
    String? zone,
    String? zoneId,
  }) {
    return Address(
      id: id ?? const Uuid().v4(),
      userId: userId,
      addressLine1: addressLine1,
      addressLine2: addressLine2,
      city: city,
      state: state,
      postalCode: postalCode,
      country: country,
      isDefault: isDefault,
      addressType: addressType,
      recipientName: recipientName,
      recipientPhone: recipientPhone,
      landmark: landmark,
      latitude: latitude,
      longitude: longitude,
      zone: zone,
      zoneId: zoneId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Address copyWith({
    String? id,
    String? userId,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    bool? isDefault,
    String? addressType,
    String? recipientName,
    String? recipientPhone,
    String? landmark,
    double? latitude,
    double? longitude,
    String? zone,
    String? zoneId,
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
      isDefault: isDefault ?? this.isDefault,
      addressType: addressType ?? this.addressType,
      recipientName: recipientName ?? this.recipientName,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      landmark: landmark ?? this.landmark,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      zone: zone ?? this.zone,
      zoneId: zoneId ?? this.zoneId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'address_line1': addressLine1,
      'address_line2': addressLine2,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'country': country,
      'is_default': isDefault,
      'address_type': addressType,
      'recipient_name': recipientName,
      'recipient_phone': recipientPhone,
      'landmark': landmark,
      'latitude': latitude,
      'longitude': longitude,
      'zone': zone,
      'zone_id': zoneId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] ?? const Uuid().v4(),
      userId: json['user_id'] ?? '',
      addressLine1: json['address_line1'] ?? '',
      addressLine2: json['address_line2'],
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      postalCode: json['postal_code'] ?? '',
      country: json['country'] ?? '',
      isDefault: json['is_default'] ?? false,
      addressType: json['address_type'],
      recipientName: json['recipient_name'],
      recipientPhone: json['recipient_phone'],
      landmark: json['landmark'],
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      zone: json['zone'],
      zoneId: json['zone_id'],
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString()) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.tryParse(json['updated_at'].toString()) 
          : null,
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
    isDefault,
    addressType,
    recipientName,
    recipientPhone,
    landmark,
    latitude,
    longitude,
    zone,
    zoneId,
    createdAt,
    updatedAt,
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
    return '$addressLine1, ${addressLine2 != null ? "$addressLine2, " : ""}$city, $state, $postalCode, $country';
  }

  String get shortAddress {
    return '$city, $state, $postalCode';
  }
  
  // Helper method to get coordinates as a string
  String? get coordinates {
    if (latitude != null && longitude != null) {
      return '$latitude, $longitude';
    }
    return null;
  }
} 