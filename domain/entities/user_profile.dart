import 'package:equatable/equatable.dart';
import 'address.dart';

/// Entity class representing a user profile in the domain layer
class UserProfile extends Equatable {
  final String id;
  final String userId;
  final String? fullName;
  final String? displayName;
  final String? bio;
  final String? profileImageUrl;
  final DateTime? dateOfBirth;
  final String? gender;
  final bool isPublic;
  final DateTime? lastUpdated;
  final Map<String, dynamic>? preferences;
  final List<Address>? addresses;

  const UserProfile({
    required this.id,
    required this.userId,
    this.fullName,
    this.displayName,
    this.bio,
    this.profileImageUrl,
    this.dateOfBirth,
    this.gender,
    this.isPublic = true,
    this.lastUpdated,
    this.preferences,
    this.addresses,
  });

  /// Create a copy of the user profile with updated fields
  UserProfile copyWith({
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
    return UserProfile(
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

  @override
  List<Object?> get props => [
        id,
        userId,
        fullName,
        displayName,
        bio,
        profileImageUrl,
        dateOfBirth,
        gender,
        isPublic,
        lastUpdated,
        preferences,
        addresses,
      ];
} 