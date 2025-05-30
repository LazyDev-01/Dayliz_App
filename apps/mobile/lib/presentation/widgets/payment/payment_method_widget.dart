import 'package:flutter/material.dart';
import 'package:dayliz_app/theme/dayliz_theme.dart';

class PaymentMethodWidget extends StatelessWidget {
  final String selectedMethod;
  final Function(String) onMethodSelected;

  const PaymentMethodWidget({
    Key? key,
    required this.selectedMethod,
    required this.onMethodSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Payment Method',
          style: theme.textTheme.titleLarge,
        ),
        AppSpacing.vMD,
        
        // Credit/Debit Card
        _buildPaymentMethodCard(
          context,
          id: 'card',
          title: 'Credit/Debit Card',
          subtitle: 'Pay securely with your card',
          icon: Icons.credit_card,
          isSelected: selectedMethod == 'card',
        ),

        // PayPal
        _buildPaymentMethodCard(
          context,
          id: 'paypal',
          title: 'PayPal',
          subtitle: 'Fast and secure payment with PayPal',
          icon: Icons.account_balance_wallet,
          isSelected: selectedMethod == 'paypal',
        ),

        // Cash on Delivery
        _buildPaymentMethodCard(
          context,
          id: 'cod',
          title: 'Cash on Delivery',
          subtitle: 'Pay when you receive your order',
          icon: Icons.money,
          isSelected: selectedMethod == 'cod',
        ),
      ],
    );
  }

  Widget _buildPaymentMethodCard(
    BuildContext context, {
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
  }) {
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
        onTap: () => onMethodSelected(id),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Radio<String>(
                value: id,
                groupValue: selectedMethod,
                onChanged: (value) => onMethodSelected(value!),
                activeColor: theme.colorScheme.primary,
              ),
              Icon(icon, size: 28, color: theme.colorScheme.primary),
              AppSpacing.hMD,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium,
                    ),
                    AppSpacing.vXS,
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
} 