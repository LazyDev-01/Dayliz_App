import 'package:equatable/equatable.dart';

class PaymentMethod extends Equatable {
  final String? id;
  final String userId;
  final String type; // credit_card, upi, cod, etc.
  final String? cardNumber; // Last 4 digits for saved cards
  final String? cardHolderName;
  final String? expiryDate;
  final String? cardType; // visa, mastercard, etc.
  final String? upiId;
  final String? bankName;
  final bool isDefault;
  final String? nickName; // User-friendly name
  
  const PaymentMethod({
    this.id,
    required this.userId,
    required this.type,
    this.cardNumber,
    this.cardHolderName,
    this.expiryDate,
    this.cardType,
    this.upiId,
    this.bankName,
    this.isDefault = false,
    this.nickName,
  });

  PaymentMethod copyWith({
    String? id,
    String? userId,
    String? type,
    String? cardNumber,
    String? cardHolderName,
    String? expiryDate,
    String? cardType,
    String? upiId,
    String? bankName,
    bool? isDefault,
    String? nickName,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      cardNumber: cardNumber ?? this.cardNumber,
      cardHolderName: cardHolderName ?? this.cardHolderName,
      expiryDate: expiryDate ?? this.expiryDate,
      cardType: cardType ?? this.cardType,
      upiId: upiId ?? this.upiId,
      bankName: bankName ?? this.bankName,
      isDefault: isDefault ?? this.isDefault,
      nickName: nickName ?? this.nickName,
    );
  }

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'],
      userId: json['user_id'],
      type: json['type'],
      cardNumber: json['card_number'],
      cardHolderName: json['card_holder_name'],
      expiryDate: json['expiry_date'],
      cardType: json['card_type'],
      upiId: json['upi_id'],
      bankName: json['bank_name'],
      isDefault: json['is_default'] ?? false,
      nickName: json['nick_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'type': type,
      'card_number': cardNumber,
      'card_holder_name': cardHolderName,
      'expiry_date': expiryDate,
      'card_type': cardType,
      'upi_id': upiId,
      'bank_name': bankName,
      'is_default': isDefault,
      'nick_name': nickName,
    };
  }

  // For displaying in the UI
  String get displayName {
    if (nickName != null && nickName!.isNotEmpty) {
      return nickName!;
    }
    
    switch (type) {
      case 'credit_card':
      case 'debit_card':
        if (cardNumber != null && cardHolderName != null) {
          return '$cardType **** $cardNumber - $cardHolderName';
        }
        return 'Card';
      case 'upi':
        return upiId ?? 'UPI';
      case 'cod':
        return 'Cash on Delivery';
      default:
        return type;
    }
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    type,
    cardNumber,
    cardHolderName,
    expiryDate,
    cardType,
    upiId,
    bankName,
    isDefault,
    nickName,
  ];
} 