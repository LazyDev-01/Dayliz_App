import 'package:equatable/equatable.dart';

/// Represents a payment method in the domain layer
class PaymentMethod extends Equatable {
  final String id;
  final String userId;
  final String type;
  final String name;
  final bool isDefault;
  final Map<String, dynamic> details;

  const PaymentMethod({
    required this.id,
    required this.userId,
    required this.type,
    required this.name,
    required this.isDefault,
    required this.details,
  });

  /// Payment method types
  static const String typeCard = 'card';
  static const String typeCreditCard = 'credit_card';
  static const String typeDebitCard = 'debit_card';
  static const String typeUpi = 'upi';
  static const String typePaypal = 'paypal';
  static const String typeCod = 'cod'; // Cash on delivery
  static const String typeBank = 'bank_transfer';
  static const String typeWallet = 'wallet';

  /// Helper method to get masked card number
  String? get maskedCardNumber {
    if ((type == typeCard || type == typeCreditCard || type == typeDebitCard) && details.containsKey('last4')) {
      return '**** **** **** ${details['last4']}';
    }
    return null;
  }

  /// Helper to get card brand/type if applicable
  String? get cardBrand {
    if ((type == typeCard || type == typeCreditCard || type == typeDebitCard) && details.containsKey('brand')) {
      return details['brand'] as String?;
    }
    return null;
  }

  /// Legacy compatibility getters
  String? get cardNumber => details['cardNumber'] as String?;
  String? get cardHolderName => details['cardHolderName'] as String?;
  String? get expiryDate => details['expiryDate'] as String?;
  String? get cardType => details['cardType'] as String?;
  String? get upiId => details['upiId'] as String?;
  String? get bankName => details['bankName'] as String?;
  String? get nickName => name; // Use name as nickName for compatibility

  /// For displaying in the UI (legacy compatibility)
  String get displayName {
    if (name.isNotEmpty) {
      return name;
    }

    switch (type) {
      case typeCreditCard:
      case typeDebitCard:
        if (cardNumber != null && cardHolderName != null) {
          return '$cardType ****$cardNumber - $cardHolderName';
        }
        return 'Card';
      case typeUpi:
        return upiId ?? 'UPI';
      case typeCod:
        return 'Cash on Delivery';
      default:
        return type;
    }
  }

  /// Returns a copy of this PaymentMethod with the given fields replaced with the new values
  PaymentMethod copyWith({
    String? id,
    String? userId,
    String? type,
    String? name,
    bool? isDefault,
    Map<String, dynamic>? details,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      name: name ?? this.name,
      isDefault: isDefault ?? this.isDefault,
      details: details ?? this.details,
    );
  }

  @override
  List<Object?> get props => [id, userId, type, name, isDefault, details];
}