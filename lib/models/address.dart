class Address {
  final String? id;
  final String name;
  final String street;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final String? phone;
  final bool isDefault;
  final String? additionalInfo;
  final double? latitude;
  final double? longitude;

  Address({
    this.id,
    required this.name,
    required this.street,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    this.phone,
    this.isDefault = false,
    this.additionalInfo,
    this.latitude,
    this.longitude,
  });

  Address copyWith({
    String? id,
    String? name,
    String? street,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    String? phone,
    bool? isDefault,
    String? additionalInfo,
    double? latitude,
    double? longitude,
  }) {
    return Address(
      id: id ?? this.id,
      name: name ?? this.name,
      street: street ?? this.street,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      phone: phone ?? this.phone,
      isDefault: isDefault ?? this.isDefault,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'street': street,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'country': country,
      'phone': phone,
      'is_default': isDefault,
      'additional_info': additionalInfo,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'],
      name: json['name'] ?? '',
      street: json['street'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      postalCode: json['postal_code'] ?? '',
      country: json['country'] ?? '',
      phone: json['phone'],
      isDefault: json['is_default'] ?? false,
      additionalInfo: json['additional_info'],
      latitude: json['latitude'],
      longitude: json['longitude'],
    );
  }

  String get formattedAddress {
    final parts = [
      street,
      city,
      state,
      postalCode,
      country,
    ];
    return parts.where((part) => part.isNotEmpty).join(', ');
  }

  String get shortAddress {
    return '$city, $state, $postalCode';
  }
} 