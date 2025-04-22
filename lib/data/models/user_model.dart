import '../../domain/entities/user.dart';

/// User model class extending User entity for data layer operations
class UserModel extends User {
  const UserModel({
    required String id,
    required String email,
    required String name,
    String? phone,
    String? profileImageUrl,
    bool? isEmailVerified,
    Map<String, dynamic>? metadata,
  }) : super(
          id: id,
          email: email,
          name: name,
          phone: phone,
          profileImageUrl: profileImageUrl,
          isEmailVerified: isEmailVerified,
          metadata: metadata,
        );

  /// Create a UserModel from a JSON map
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      phone: json['phone'],
      profileImageUrl: json['profile_image'] ?? json['profile_image_url'],
      isEmailVerified: json['is_email_verified'] ?? false,
      metadata: json['metadata'],
    );
  }

  /// Convert this UserModel to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'profile_image_url': profileImageUrl,
      'is_email_verified': isEmailVerified,
      'metadata': metadata,
    };
  }

  /// Create a copy of this UserModel with the given fields replaced
  UserModel copyWithModel({
    String? id,
    String? email,
    String? name,
    String? phone,
    String? profileImageUrl,
    bool? isEmailVerified,
    Map<String, dynamic>? metadata,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      metadata: metadata ?? this.metadata,
    );
  }
} 