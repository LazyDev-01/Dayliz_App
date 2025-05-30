import 'package:equatable/equatable.dart';

/// Entity class representing a user profile in the domain layer
class UserProfile extends Equatable {
  final String id;
  final String userId;
  final String? fullName;
  final String? profileImageUrl;
  final DateTime? dateOfBirth;
  final String? gender;
  final DateTime? lastUpdated;
  final Map<String, dynamic>? preferences;

  const UserProfile({
    required this.id,
    required this.userId,
    this.fullName,
    this.profileImageUrl,
    this.dateOfBirth,
    this.gender,
    this.lastUpdated,
    this.preferences,
  });

  /// Create a copy of the user profile with updated fields
  UserProfile copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? profileImageUrl,
    DateTime? dateOfBirth,
    String? gender,
    DateTime? lastUpdated,
    Map<String, dynamic>? preferences,
  }) {
    return UserProfile(
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

  @override
  List<Object?> get props => [
        id,
        userId,
        fullName,
        profileImageUrl,
        dateOfBirth,
        gender,
        lastUpdated,
        preferences,
      ];
}