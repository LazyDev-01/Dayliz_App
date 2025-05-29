import 'dart:convert';
import 'package:dayliz_app/domain/entities/user_profile.dart';

/// Model class for [UserProfile] with additional functionality for the data layer
class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required String id,
    required String userId,
    String? fullName,
    String? profileImageUrl,
    DateTime? dateOfBirth,
    String? gender,
    DateTime? lastUpdated,
    Map<String, dynamic>? preferences,
  }) : super(
          id: id,
          userId: userId,
          fullName: fullName,
          profileImageUrl: profileImageUrl,
          dateOfBirth: dateOfBirth,
          gender: gender,
          lastUpdated: lastUpdated,
          preferences: preferences,
        );

  /// Factory constructor to create a [UserProfileModel] from a map (JSON)
  factory UserProfileModel.fromMap(Map<String, dynamic> map) {
    // Handle preferences field properly
    Map<String, dynamic>? preferences;
    try {
      final prefsValue = map['preferences'];
      if (prefsValue is String) {
        // If it's a JSON string, parse it
        preferences = prefsValue.isEmpty ? {} : json.decode(prefsValue);
      } else if (prefsValue is Map<String, dynamic>) {
        // If it's already a map, use it directly
        preferences = prefsValue;
      } else {
        // Default to empty map
        preferences = {};
      }
    } catch (e) {
      // If parsing fails, use empty map
      preferences = {};
    }

    return UserProfileModel(
      id: map['id'],
      userId: map['user_id'],
      fullName: map['full_name'],
      profileImageUrl: map['profile_image_url'],
      dateOfBirth: map['date_of_birth'] != null
          ? DateTime.parse(map['date_of_birth'])
          : null,
      gender: map['gender'],
      lastUpdated: map['last_updated'] != null
          ? DateTime.parse(map['last_updated'])
          : null,
      preferences: preferences,
    );
  }

  /// Convert this [UserProfileModel] to a map (JSON)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'full_name': fullName,
      'profile_image_url': profileImageUrl,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'last_updated': lastUpdated?.toIso8601String(),
      'preferences': preferences,
    };
  }

  /// Create a copy of this UserProfileModel with the given fields replaced
  UserProfileModel copyWithModel({
    String? id,
    String? userId,
    String? fullName,
    String? profileImageUrl,
    DateTime? dateOfBirth,
    String? gender,
    DateTime? lastUpdated,
    Map<String, dynamic>? preferences,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      preferences: preferences ?? this.preferences,
    );
  }

  // For backward compatibility
  factory UserProfileModel.fromJson(Map<String, dynamic> json) => UserProfileModel.fromMap(json);
  Map<String, dynamic> toJson() => toMap();
}