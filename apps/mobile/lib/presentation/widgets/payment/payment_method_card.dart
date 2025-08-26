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
    final isComingSoon = paymentMethod.details['isComingSoon'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: isComingSoon ? null : onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  // Icon
                  _buildModernPaymentMethodIcon(),
                  const SizedBox(width: 16),
                  
                  // Payment method details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              paymentMethod.nickName ?? _getDefaultTitle(),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: isComingSoon ? Colors.grey[500] : Colors.black87,
                              ),
                            ),
                            if (paymentMethod.isDefault) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Default',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                            ],
                            if (isComingSoon) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Coming Soon',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getCardDetails(),
                          style: TextStyle(
                            fontSize: 13,
                            color: isComingSoon ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Circular checkbox (hidden for coming soon methods)
                  if (!isComingSoon)
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.green : Colors.grey[400]!,
                          width: 2,
                        ),
                        color: isSelected ? Colors.green : Colors.transparent,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            )
                          : null,
                    )
                  else
                    const SizedBox(width: 24), // Maintain spacing
                ],
              ),
            ),
          ),
          if (onDelete != null || onSetDefault != null) ...[
            const Divider(height: 1, color: Colors.grey),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
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
                  if (onDelete != null)
                    TextButton(
                      onPressed: onDelete,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 0,
                        ),
                      ),
                      child: const Text('Delete'),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModernPaymentMethodIcon() {
    IconData iconData = Icons.payment;
    Color iconColor = Colors.grey;
    String? iconAsset;

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
        // Check if it's a specific UPI app
        final upiId = paymentMethod.details['upi_id'] as String? ?? '';
        if (upiId.contains('googlepay') || upiId.contains('gpay')) {
          iconAsset = 'assets/icons/googlepay.png';
          iconColor = const Color(0xFF4285F4);
        } else if (upiId.contains('paytm')) {
          iconAsset = 'assets/icons/paytm.png';
          iconColor = const Color(0xFF00BAF2);
        } else if (upiId.contains('phonepe')) {
          iconAsset = 'assets/icons/phonepe.png';
          iconColor = const Color(0xFF5F259F);
        } else {
          iconData = Icons.account_balance_wallet;
          iconColor = Colors.purple;
        }
        break;
      case PaymentMethod.typeCod:
        iconAsset = 'assets/icons/cash.png';
        iconColor = Colors.green;
        break;
      default:
        iconData = Icons.payment;
        iconColor = Colors.grey;
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: iconAsset != null ? Colors.transparent : iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: iconAsset != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                iconAsset,
                width: 32,
                height: 32,
                fit: BoxFit.contain,
              ),
            )
          : Icon(
              iconData,
              color: iconColor,
              size: 20,
            ),
    );
  }

  String _getDefaultTitle() {
    switch (paymentMethod.type) {
      case PaymentMethod.typeCreditCard:
        return 'Credit Card';
      case PaymentMethod.typeDebitCard:
        return 'Debit Card';
      case PaymentMethod.typeUpi:
        return 'UPI';
      case PaymentMethod.typeCod:
        return 'Cash on Delivery';
      default:
        return 'Payment Method';
    }
  }

  String _getCardDetails() {
    switch (paymentMethod.type) {
      case PaymentMethod.typeCreditCard:
      case PaymentMethod.typeDebitCard:
        final cardNumber = paymentMethod.details['card_number'] as String? ?? '';
        if (cardNumber.isNotEmpty) {
          return '**** **** **** ${cardNumber.substring(cardNumber.length - 4)}';
        }
        return 'Card ending in ****';
      case PaymentMethod.typeUpi:
        final upiId = paymentMethod.details['upi_id'] as String? ?? '';
        return upiId.isNotEmpty ? upiId : 'UPI ID';
      case PaymentMethod.typeCod:
        return 'Pay when your order is delivered';
      default:
        return paymentMethod.displayName;
    }
  }
}
