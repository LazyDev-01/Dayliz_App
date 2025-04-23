import '../../domain/entities/payment_method.dart';

/// Data model for PaymentMethod entity
class PaymentMethodModel extends PaymentMethod {
  const PaymentMethodModel({
    required String id,
    required String userId,
    required String type,
    required String name,
    required bool isDefault,
    required Map<String, dynamic> details,
  }) : super(
          id: id,
          userId: userId,
          type: type,
          name: name,
          isDefault: isDefault,
          details: details,
        );

  /// Create a PaymentMethodModel from JSON data
  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      id: json['id'],
      userId: json['user_id'],
      type: json['type'],
      name: json['name'],
      isDefault: json['is_default'] ?? false,
      details: json['details'] != null
          ? Map<String, dynamic>.from(json['details'])
          : {},
    );
  }

  /// Convert PaymentMethodModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'name': name,
      'is_default': isDefault,
      'details': details,
    };
  }

  /// Create a copy of this PaymentMethodModel with the given fields replaced with the new values
  PaymentMethodModel copyWithModel({
    String? id,
    String? userId,
    String? type,
    String? name,
    bool? isDefault,
    Map<String, dynamic>? details,
  }) {
    return PaymentMethodModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      name: name ?? this.name,
      isDefault: isDefault ?? this.isDefault,
      details: details ?? this.details,
    );
  }

  // Convert domain entity to model
  factory PaymentMethodModel.fromEntity(PaymentMethod entity) {
    return PaymentMethodModel(
      id: entity.id,
      userId: entity.userId,
      type: entity.type,
      name: entity.name,
      isDefault: entity.isDefault,
      details: entity.details,
    );
  }

  // For backward compatibility with code using the pattern method.fromMap/toMap
  factory PaymentMethodModel.fromMap(Map<String, dynamic> map) => PaymentMethodModel.fromJson(map);
  Map<String, dynamic> toMap() => toJson();
} 