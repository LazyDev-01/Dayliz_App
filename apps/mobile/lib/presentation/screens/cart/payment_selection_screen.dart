import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../theme/app_theme.dart';
import '../../providers/cart_providers.dart';
import '../checkout/order_processing_screen.dart';

/// Payment Selection Screen for Cart Checkout Flow
/// This screen allows users to select their preferred payment method
/// after placing an order from the cart
class PaymentSelectionScreen extends ConsumerStatefulWidget {
  const PaymentSelectionScreen({super.key});

  @override
  ConsumerState<PaymentSelectionScreen> createState() => _PaymentSelectionScreenState();
}

class _PaymentSelectionScreenState extends ConsumerState<PaymentSelectionScreen> {
  // State for selected payment method
  String? _selectedPaymentMethod = 'cod'; // Default to COD for Indian market

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daylizTheme = theme.extension<DaylizThemeExtension>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context, theme),
      body: _buildBody(context, theme, daylizTheme),
      bottomNavigationBar: _buildBottomSection(context, theme),
    );
  }

  /// Builds the app bar with back button and title
  PreferredSizeWidget _buildAppBar(BuildContext context, ThemeData theme) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        'Payment Method',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: false,
    );
  }

  /// Builds the main body content
  Widget _buildBody(BuildContext context, ThemeData theme, DaylizThemeExtension? daylizTheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header text
          const Text(
            'Choose your payment method',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select how you\'d like to pay for your order',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Payment methods list
          ..._buildPaymentMethods(),
        ],
      ),
    );
  }

  /// Builds the list of payment method options
  List<Widget> _buildPaymentMethods() {
    final paymentMethods = _getPaymentMethods();

    return paymentMethods.map((method) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: _buildPaymentMethodCard(method),
      );
    }).toList();
  }

  /// Builds individual payment method card
  Widget _buildPaymentMethodCard(Map<String, dynamic> method) {
    final isSelected = _selectedPaymentMethod == method['id'];
    final isEnabled = method['enabled'] ?? true;

    return Container(
      decoration: BoxDecoration(
        color: isEnabled ? Colors.white : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.success : AppColors.textSecondary.withValues(alpha: 0.2),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: isEnabled ? () => _selectPaymentMethod(method['id']) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Payment method icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: method['color'].withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  method['icon'],
                  color: method['color'],
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // Payment method details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method['title'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: !isEnabled
                          ? Colors.grey[500]
                          : isSelected
                            ? AppColors.success
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      method['subtitle'],
                      style: TextStyle(
                        fontSize: 14,
                        color: !isEnabled ? Colors.grey[500] : AppColors.textSecondary,
                      ),
                    ),
                    if (method['badge'] != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: method['badgeColor'].withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          method['badge'],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: method['badgeColor'],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Selection indicator
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: !isEnabled
                      ? Colors.grey[400]!
                      : isSelected
                        ? AppColors.success
                        : AppColors.textSecondary.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  color: isSelected && isEnabled ? AppColors.success : Colors.transparent,
                ),
                child: isSelected && isEnabled
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the bottom section with proceed button
  Widget _buildBottomSection(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: _selectedPaymentMethod != null ? AppColors.success : AppColors.textSecondary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _selectedPaymentMethod != null ? () => _handleProceed(context) : null,
              child: const Center(
                child: Text(
                  'Proceed to Pay',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Gets the list of available payment methods
  List<Map<String, dynamic>> _getPaymentMethods() {
    return [
      {
        'id': 'cod',
        'title': 'Cash on Delivery',
        'subtitle': 'Pay when your order arrives at your doorstep',
        'icon': Icons.money,
        'color': AppColors.success,
        'badge': 'Most Popular',
        'badgeColor': AppColors.success,
        'enabled': true,
      },
      {
        'id': 'upi',
        'title': 'UPI (Google Pay, PhonePe, Paytm)',
        'subtitle': 'Coming Soon!',
        'icon': Icons.account_balance_wallet,
        'color': Colors.grey,
        'badge': null,
        'badgeColor': null,
        'enabled': false,
      },
      {
        'id': 'card',
        'title': 'Credit/Debit Card',
        'subtitle': 'Coming Soon!',
        'icon': Icons.credit_card,
        'color': Colors.grey,
        'badge': null,
        'badgeColor': null,
        'enabled': false,
      },
      {
        'id': 'amazonpay',
        'title': 'Amazon Pay',
        'subtitle': 'Coming Soon!',
        'icon': Icons.shopping_bag,
        'color': Colors.grey,
        'badge': null,
        'badgeColor': null,
        'enabled': false,
      },
    ];
  }

  /// Handles payment method selection
  void _selectPaymentMethod(String methodId) {
    setState(() {
      _selectedPaymentMethod = methodId;
    });
  }

  /// Handles proceed to pay action
  void _handleProceed(BuildContext context) {
    final selectedMethod = _getPaymentMethods().firstWhere(
      (method) => method['id'] == _selectedPaymentMethod,
    );

    // Navigate to order processing screen with order data
    _navigateToOrderProcessing(context, selectedMethod);
  }

  /// Navigate to order processing with complete order data
  void _navigateToOrderProcessing(BuildContext context, Map<String, dynamic> paymentMethod) {
    // Get cart data from provider
    final cartState = ref.read(cartNotifierProvider);

    // Prepare order data
    final orderData = {
      'userId': 'current_user_id', // TODO: Get from auth provider
      'items': cartState.items.map((item) => {
        'productId': item.product.id,
        'productName': item.product.name,
        'quantity': item.quantity,
        'price': item.product.price,
        'total': item.product.price * item.quantity,
        'image': 'assets/images/placeholder.png', // TODO: Use actual product image
      }).toList(),
      'subtotal': cartState.totalPrice,
      'tax': cartState.totalPrice * 0.18, // 18% tax
      'shipping': 0.0, // Free shipping for early launch
      'total': cartState.totalPrice + (cartState.totalPrice * 0.18),
      'paymentMethod': _selectedPaymentMethod,
      'shippingAddress': {
        'addressLine1': '123 Main Street', // TODO: Get from address provider
        'city': 'New York',
        'state': 'NY',
        'postalCode': '10001',
        'country': 'USA',
      },
      'status': 'pending',
      'createdAt': DateTime.now(),
      'estimatedDelivery': DateTime.now().add(const Duration(hours: 2)),
    };

    // Navigate to order processing screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OrderProcessingScreen(
          orderData: orderData,
          onSuccess: () {
            // Clear cart after successful order
            ref.read(cartNotifierProvider.notifier).clearCart();
          },
          onError: () {
            // Handle error if needed
            debugPrint('Order processing failed');
          },
        ),
      ),
    );
  }
}
