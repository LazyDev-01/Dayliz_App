import 'package:flutter/material.dart';
import '../../widgets/payment/modern_payment_options_widget.dart';

/// Standalone payment options screen for testing and direct access
class PaymentOptionsScreen extends StatelessWidget {
  const PaymentOptionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ModernPaymentOptionsWidget(
      selectedPaymentMethod: null,
      onPaymentMethodSelected: (method) {
        // Navigate back immediately without snackbar
        Navigator.pop(context, method);
      },
    );
  }
}
