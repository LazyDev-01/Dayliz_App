import 'package:equatable/equatable.dart';

/// Enhanced payment models for UPI integration

enum PaymentMethodType {
  upi('upi'),
  cod('cod'),
  card('card'),
  wallet('wallet');

  const PaymentMethodType(this.value);
  final String value;
}

enum UpiApp {
  googlepay('googlepay'),
  paytm('paytm'),
  phonepe('phonepe'),
  other('other');

  const UpiApp(this.value);
  final String value;

  String get displayName {
    switch (this) {
      case UpiApp.googlepay:
        return 'Google Pay';
      case UpiApp.paytm:
        return 'Paytm';
      case UpiApp.phonepe:
        return 'PhonePe';
      case UpiApp.other:
        return 'Other UPI';
    }
  }

  String get iconAsset {
    switch (this) {
      case UpiApp.googlepay:
        return 'assets/icons/googlepay.png';
      case UpiApp.paytm:
        return 'assets/icons/paytm.png';
      case UpiApp.phonepe:
        return 'assets/icons/phonepe.png';
      case UpiApp.other:
        return 'assets/icons/upi.png';
    }
  }
}

enum PaymentStatus {
  pending('pending'),
  processing('payment_processing'),
  completed('completed'),
  failed('payment_failed'),
  timeout('payment_timeout'),
  refunded('refunded');

  const PaymentStatus(this.value);
  final String value;

  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.processing:
        return 'Processing';
      case PaymentStatus.completed:
        return 'Completed';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.timeout:
        return 'Timeout';
      case PaymentStatus.refunded:
        return 'Refunded';
    }
  }

  bool get isCompleted => this == PaymentStatus.completed;
  bool get isFailed => this == PaymentStatus.failed || this == PaymentStatus.timeout;
  bool get isProcessing => this == PaymentStatus.processing;
  bool get canRetry => this == PaymentStatus.failed || this == PaymentStatus.timeout;
}

/// Order creation request with payment method
class OrderWithPaymentRequest extends Equatable {
  final List<Map<String, dynamic>> cartItems;
  final String shippingAddressId;
  final PaymentMethodType paymentMethod;
  final UpiApp? upiApp;
  final double totalAmount;

  const OrderWithPaymentRequest({
    required this.cartItems,
    required this.shippingAddressId,
    required this.paymentMethod,
    this.upiApp,
    required this.totalAmount,
  });

  Map<String, dynamic> toJson() {
    return {
      'cart_items': cartItems,
      'shipping_address_id': shippingAddressId,
      'payment_method': paymentMethod.value,
      'upi_app': upiApp?.value,
      'total_amount': totalAmount,
    };
  }

  @override
  List<Object?> get props => [
        cartItems,
        shippingAddressId,
        paymentMethod,
        upiApp,
        totalAmount,
      ];
}

/// Razorpay order response
class RazorpayOrderResponse extends Equatable {
  final String orderId;
  final String currency;
  final int amount; // Amount in paisa
  final String key;
  final String internalOrderId;
  final String? upiIntentUrl;
  final DateTime timeoutAt;

  const RazorpayOrderResponse({
    required this.orderId,
    required this.currency,
    required this.amount,
    required this.key,
    required this.internalOrderId,
    this.upiIntentUrl,
    required this.timeoutAt,
  });

  factory RazorpayOrderResponse.fromJson(Map<String, dynamic> json) {
    return RazorpayOrderResponse(
      orderId: json['order_id'],
      currency: json['currency'],
      amount: json['amount'],
      key: json['key'],
      internalOrderId: json['internal_order_id'],
      upiIntentUrl: json['upi_intent_url'],
      timeoutAt: DateTime.parse(json['timeout_at']),
    );
  }

  @override
  List<Object?> get props => [
        orderId,
        currency,
        amount,
        key,
        internalOrderId,
        upiIntentUrl,
        timeoutAt,
      ];
}

/// Order creation response
class OrderCreationResponse extends Equatable {
  final String orderId;
  final bool paymentRequired;
  final String paymentMethod;
  final RazorpayOrderResponse? razorpayOrder;
  final String? message;

  const OrderCreationResponse({
    required this.orderId,
    required this.paymentRequired,
    required this.paymentMethod,
    this.razorpayOrder,
    this.message,
  });

  factory OrderCreationResponse.fromJson(Map<String, dynamic> json) {
    return OrderCreationResponse(
      orderId: json['order_id'],
      paymentRequired: json['payment_required'],
      paymentMethod: json['payment_method'],
      razorpayOrder: json['razorpay_order'] != null
          ? RazorpayOrderResponse.fromJson(json['razorpay_order'])
          : null,
      message: json['message'],
    );
  }

  @override
  List<Object?> get props => [
        orderId,
        paymentRequired,
        paymentMethod,
        razorpayOrder,
        message,
      ];
}

/// Payment status response
class PaymentStatusResponse extends Equatable {
  final String orderId;
  final PaymentStatus paymentStatus;
  final String? razorpayOrderId;
  final String? paymentId;
  final DateTime? timeoutAt;
  final int retryCount;
  final bool canRetry;
  final String? failureReason;

  const PaymentStatusResponse({
    required this.orderId,
    required this.paymentStatus,
    this.razorpayOrderId,
    this.paymentId,
    this.timeoutAt,
    required this.retryCount,
    required this.canRetry,
    this.failureReason,
  });

  factory PaymentStatusResponse.fromJson(Map<String, dynamic> json) {
    return PaymentStatusResponse(
      orderId: json['order_id'],
      paymentStatus: PaymentStatus.values.firstWhere(
        (status) => status.value == json['payment_status'],
        orElse: () => PaymentStatus.pending,
      ),
      razorpayOrderId: json['razorpay_order_id'],
      paymentId: json['payment_id'],
      timeoutAt: json['timeout_at'] != null 
          ? DateTime.parse(json['timeout_at']) 
          : null,
      retryCount: json['retry_count'] ?? 0,
      canRetry: json['can_retry'] ?? false,
      failureReason: json['failure_reason'],
    );
  }

  @override
  List<Object?> get props => [
        orderId,
        paymentStatus,
        razorpayOrderId,
        paymentId,
        timeoutAt,
        retryCount,
        canRetry,
        failureReason,
      ];
}

/// Payment retry request
class PaymentRetryRequest extends Equatable {
  final String orderId;
  final UpiApp? upiApp;

  const PaymentRetryRequest({
    required this.orderId,
    this.upiApp,
  });

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'upi_app': upiApp?.value,
    };
  }

  @override
  List<Object?> get props => [orderId, upiApp];
}

/// Payment verification request
class PaymentVerificationRequest extends Equatable {
  final String razorpayOrderId;
  final String razorpayPaymentId;
  final String razorpaySignature;

  const PaymentVerificationRequest({
    required this.razorpayOrderId,
    required this.razorpayPaymentId,
    required this.razorpaySignature,
  });

  Map<String, dynamic> toJson() {
    return {
      'razorpay_order_id': razorpayOrderId,
      'razorpay_payment_id': razorpayPaymentId,
      'razorpay_signature': razorpaySignature,
    };
  }

  @override
  List<Object?> get props => [
        razorpayOrderId,
        razorpayPaymentId,
        razorpaySignature,
      ];
}

/// Payment response
class PaymentResponse extends Equatable {
  final bool success;
  final String orderId;
  final String? paymentId;
  final PaymentStatus status;
  final String message;
  final String? razorpayOrderId;

  const PaymentResponse({
    required this.success,
    required this.orderId,
    this.paymentId,
    required this.status,
    required this.message,
    this.razorpayOrderId,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      success: json['success'],
      orderId: json['order_id'],
      paymentId: json['payment_id'],
      status: PaymentStatus.values.firstWhere(
        (status) => status.value == json['status'],
        orElse: () => PaymentStatus.pending,
      ),
      message: json['message'],
      razorpayOrderId: json['razorpay_order_id'],
    );
  }

  @override
  List<Object?> get props => [
        success,
        orderId,
        paymentId,
        status,
        message,
        razorpayOrderId,
      ];
}
