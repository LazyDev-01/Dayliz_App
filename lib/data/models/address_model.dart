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
    String label = 'Home',
    String? additionalInfo,
    Map<String, double>? coordinates,
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
          label: label,
          additionalInfo: additionalInfo,
          coordinates: coordinates,
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
      label: map['label'] ?? 'Home',
      additionalInfo: map['additional_info'],
      coordinates: map['coordinates'] != null
          ? Map<String, double>.from(map['coordinates'])
          : null,
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
      'label': label,
      'additional_info': additionalInfo,
      'coordinates': coordinates,
    };
  }
  
  // For backward compatibility with existing code
  factory AddressModel.fromJson(Map<String, dynamic> json) => AddressModel.fromMap(json);
  Map<String, dynamic> toJson() => toMap();
} 