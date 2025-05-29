import 'package:flutter/material.dart';
import '../../../domain/entities/payment_method.dart';

class PaymentMethodCard extends StatelessWidget {
  final PaymentMethod paymentMethod;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onSetDefault;

  const PaymentMethodCard({
    Key? key,
    required this.paymentMethod,
    required this.isSelected,
    required this.onTap,
    this.onDelete,
    this.onSetDefault,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: isSelected
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildPaymentMethodIcon(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              paymentMethod.nickName ?? _getDefaultTitle(),
                              style: theme.textTheme.titleMedium,
                            ),
                            if (paymentMethod.isDefault) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Default',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getCardDetails(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Radio<bool>(
                    value: true,
                    groupValue: isSelected,
                    onChanged: (_) => onTap(),
                    activeColor: theme.colorScheme.primary,
                  ),
                ],
              ),
              if (onDelete != null || onSetDefault != null) ...[
                const SizedBox(height: 8),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onSetDefault != null && !paymentMethod.isDefault)
                      TextButton(
                        onPressed: onSetDefault,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 0,
                          ),
                        ),
                        child: const Text('Set as Default'),
                      ),
                    if (onDelete != null) ...[
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: onDelete,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 0,
                          ),
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Delete'),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodIcon() {
    IconData iconData;
    Color iconColor;

    switch (paymentMethod.type) {
      case PaymentMethod.typeCreditCard:
      case PaymentMethod.typeDebitCard:
        if (paymentMethod.cardType == 'visa') {
          iconData = Icons.credit_card;
          iconColor = Colors.blue;
        } else if (paymentMethod.cardType == 'mastercard') {
          iconData = Icons.credit_card;
          iconColor = Colors.deepOrange;
        } else {
          iconData = Icons.credit_card;
          iconColor = Colors.grey;
        }
        break;
      case PaymentMethod.typeUpi:
        iconData = Icons.account_balance;
        iconColor = Colors.green;
        break;
      case PaymentMethod.typeCod:
        iconData = Icons.money;
        iconColor = Colors.green.shade800;
        break;
      default:
        iconData = Icons.payment;
        iconColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
      ),
    );
  }

  String _getDefaultTitle() {
    switch (paymentMethod.type) {
      case PaymentMethod.typeCreditCard:
      case PaymentMethod.typeDebitCard:
        return paymentMethod.cardType?.toUpperCase() ?? 'Card';
      case PaymentMethod.typeUpi:
        return 'UPI';
      case PaymentMethod.typeCod:
        return 'Cash on Delivery';
      default:
        return paymentMethod.type;
    }
  }

  String _getCardDetails() {
    switch (paymentMethod.type) {
      case PaymentMethod.typeCreditCard:
      case PaymentMethod.typeDebitCard:
        if (paymentMethod.cardNumber != null && paymentMethod.expiryDate != null) {
          return '•••• ${paymentMethod.cardNumber} | Expires ${paymentMethod.expiryDate}';
        } else if (paymentMethod.cardNumber != null) {
          return '•••• ${paymentMethod.cardNumber}';
        }
        return 'Credit/Debit Card';
      case PaymentMethod.typeUpi:
        return paymentMethod.upiId ?? 'UPI Payment';
      case PaymentMethod.typeCod:
        return 'Pay when you receive your order';
      default:
        return '';
    }
  }
}