import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PaymentMethodSelectionWidget extends ConsumerWidget {
  final String selectedMethod;
  final Function(String) onMethodSelected;

  const PaymentMethodSelectionWidget({
    Key? key,
    required this.selectedMethod,
    required this.onMethodSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Payment Method',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              RadioListTile<String>(
                title: const Row(
                  children: [
                    Icon(Icons.credit_card),
                    SizedBox(width: 8),
                    Text('Credit/Debit Card'),
                  ],
                ),
                value: 'card',
                groupValue: selectedMethod,
                onChanged: (value) {
                  if (value != null) {
                    onMethodSelected(value);
                  }
                },
              ),
              RadioListTile<String>(
                title: const Row(
                  children: [
                    Icon(Icons.account_balance_wallet),
                    SizedBox(width: 8),
                    Text('PayPal'),
                  ],
                ),
                value: 'paypal',
                groupValue: selectedMethod,
                onChanged: (value) {
                  if (value != null) {
                    onMethodSelected(value);
                  }
                },
              ),
              RadioListTile<String>(
                title: const Row(
                  children: [
                    Icon(Icons.money),
                    SizedBox(width: 8),
                    Text('Cash on Delivery'),
                  ],
                ),
                value: 'cod',
                groupValue: selectedMethod,
                onChanged: (value) {
                  if (value != null) {
                    onMethodSelected(value);
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
