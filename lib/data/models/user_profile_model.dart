import 'package:dayliz_app/domain/entities/user_profile.dart';
import 'package:dayliz_app/domain/entities/address.dart';

/// Model class for [UserProfile] with additional functionality for the data layer
class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required String id,
    required String userId,
    String? fullName,
    String? displayName,
    String? bio,
    String? profileImageUrl,
    DateTime? dateOfBirth,
    String? gender,
    bool isPublic = true,
    DateTime? lastUpdated,
    Map<String, dynamic>? preferences,
    List<Address>? addresses,
  }) : super(
          id: id,
          userId: userId,
          fullName: fullName,
          displayName: displayName,
          bio: bio,
          profileImageUrl: profileImageUrl,
          dateOfBirth: dateOfBirth,
          gender: gender,
          isPublic: isPublic,
          lastUpdated: lastUpdated,
          preferences: preferences,
          addresses: addresses,
        );

  /// Factory constructor to create a [UserProfileModel] from a map (JSON)
  factory UserProfileModel.fromMap(Map<String, dynamic> map) {
    return UserProfileModel(
      id: map['id'],
      userId: map['user_id'],
      fullName: map['full_name'],
      displayName: map['display_name'],
      bio: map['bio'],
      profileImageUrl: map['profile_image_url'],
      dateOfBirth: map['date_of_birth'] != null 
          ? DateTime.parse(map['date_of_birth']) 
          : null,
      gender: map['gender'],
      isPublic: map['is_public'] ?? true,
      lastUpdated: map['last_updated'] != null 
          ? DateTime.parse(map['last_updated']) 
          : null,
      preferences: map['preferences'],
      addresses: map['addresses'] != null 
          ? List<Address>.from(
              map['addresses'].map((x) => Address(
                id: x['id'],
                userId: x['user_id'],
                addressLine1: x['address_line1'],
                addressLine2: x['address_line2'] ?? '',
                city: x['city'],
                state: x['state'],
                postalCode: x['postal_code'],
                country: x['country'],
                phoneNumber: x['phone_number'],
                isDefault: x['is_default'] ?? false,
                label: x['label'] ?? 'Home',
                additionalInfo: x['additional_info'],
                coordinates: x['coordinates'] != null 
                    ? Map<String, double>.from(x['coordinates'])
                    : null,
              )))
          : null,
    );
  }

  /// Convert this [UserProfileModel] to a map (JSON)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'full_name': fullName,
      'display_name': displayName,
      'bio': bio,
      'profile_image_url': profileImageUrl,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'is_public': isPublic,
      'last_updated': lastUpdated?.toIso8601String(),
      'preferences': preferences,
      'addresses': addresses?.map((a) => {
        'id': a.id,
        'user_id': a.userId,
        'address_line1': a.addressLine1,
        'address_line2': a.addressLine2,
        'city': a.city,
        'state': a.state,
        'postal_code': a.postalCode,
        'country': a.country,
        'phone_number': a.phoneNumber,
        'is_default': a.isDefault,
        'label': a.label,
        'additional_info': a.additionalInfo,
        'coordinates': a.coordinates,
      }).toList(),
    };
  }

  /// Create a copy of this UserProfileModel with the given fields replaced
  UserProfileModel copyWithModel({
    String? id,
    String? userId,
    String? fullName,
    String? displayName,
    String? bio,
    String? profileImageUrl,
    DateTime? dateOfBirth,
    String? gender,
    bool? isPublic,
    DateTime? lastUpdated,
    Map<String, dynamic>? preferences,
    List<Address>? addresses,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      isPublic: isPublic ?? this.isPublic,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      preferences: preferences ?? this.preferences,
      addresses: addresses ?? this.addresses,
    );
  }

  // For backward compatibility
  factory UserProfileModel.fromJson(Map<String, dynamic> json) => UserProfileModel.fromMap(json);
  Map<String, dynamic> toJson() => toMap();
} 