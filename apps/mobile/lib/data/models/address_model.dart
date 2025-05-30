import 'package:dayliz_app/domain/entities/address.dart';

/// Model class for [Address] with additional functionality for the data layer
class AddressModel extends Address {
  const AddressModel({
    required String id,
    required String userId,
    required String addressLine1,
    String addressLine2 = '',
    required String city,
    required String state,
    required String postalCode,
    required String country,
    String? phoneNumber,
    bool isDefault = false,
    // Label field removed
    String? addressType,
    String? additionalInfo,
    double? latitude,
    double? longitude,
    String? landmark,
    String? zoneId,
    String? recipientName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : super(
          id: id,
          userId: userId,
          addressLine1: addressLine1,
          addressLine2: addressLine2,
          city: city,
          state: state,
          postalCode: postalCode,
          country: country,
          phoneNumber: phoneNumber,
          isDefault: isDefault,
          // Label field removed
          addressType: addressType,
          additionalInfo: additionalInfo,
          latitude: latitude,
          longitude: longitude,
          landmark: landmark,
          zoneId: zoneId,
          recipientName: recipientName,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  /// Factory constructor to create an [AddressModel] from a map (JSON)
  factory AddressModel.fromMap(Map<String, dynamic> map) {
    return AddressModel(
      id: map['id'],
      userId: map['user_id'] ?? '',
      addressLine1: map['address_line1'],
      addressLine2: map['address_line2'] ?? '',
      city: map['city'],
      state: map['state'],
      postalCode: map['postal_code'],
      country: map['country'],
      phoneNumber: map['phone_number'],
      isDefault: map['is_default'] ?? false,
      // Label field removed
      addressType: map['address_type'],
      additionalInfo: map['additional_info'],
      latitude: map['latitude'] != null ?
          double.tryParse(map['latitude'].toString()) : null,
      longitude: map['longitude'] != null ?
          double.tryParse(map['longitude'].toString()) : null,
      landmark: map['landmark'],
      zoneId: map['zone_id'],
      recipientName: map['recipient_name'],
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'].toString()) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'].toString()) : null,
    );
  }

  /// Convert this [AddressModel] to a map (JSON)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'address_line1': addressLine1,
      'address_line2': addressLine2,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'country': country,
      'phone_number': phoneNumber,
      'is_default': isDefault,
      // Label field removed
      'address_type': addressType,
      'additional_info': additionalInfo,
      'latitude': latitude,
      'longitude': longitude,
      'landmark': landmark,
      'zone_id': zoneId,
      'recipient_name': recipientName,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // For backward compatibility with existing code
  factory AddressModel.fromJson(Map<String, dynamic> json) => AddressModel.fromMap(json);
  Map<String, dynamic> toJson() => toMap();
}