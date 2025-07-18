import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../../providers/cart_providers.dart';
import '../../providers/user_profile_providers.dart';
import '../../providers/auth_providers.dart';
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
  String? _selectedPaymentMethod; // No default selection

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daylizTheme = theme.extension<DaylizThemeExtension>();

    return Scaffold(
      backgroundColor: Colors.grey[100], // Light grey background
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
          // UPI Section
          _buildSectionHeader('Pay by UPI'),
          const SizedBox(height: 12),
          _buildUpiSection(),

          const SizedBox(height: 32),

          // Cash on Delivery Section
          _buildSectionHeader('Pay on Delivery'),
          const SizedBox(height: 12),
          _buildCodSection(),
        ],
      ),
    );
  }

  /// Builds section header
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  /// Builds UPI payment section
  Widget _buildUpiSection() {
    return Container(
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
          // GooglePay (First)
          _buildUpiOption(
            id: 'googlepay',
            name: 'GooglePay',
            iconAsset: 'assets/icons/googlepay.png',
            color: const Color(0xFF4285F4),
            isFirst: true,
          ),
          _buildDivider(),

          // Paytm (Second)
          _buildUpiOption(
            id: 'paytm',
            name: 'Paytm',
            iconAsset: 'assets/icons/paytm.png',
            color: const Color(0xFF00BAF2),
          ),
          _buildDivider(),

          // PhonePe (Third)
          _buildUpiOption(
            id: 'phonepe',
            name: 'PhonePe',
            iconAsset: 'assets/icons/phonepe.png',
            color: const Color(0xFF5F259F),
            isLast: true,
          ),
        ],
      ),
    );
  }

  /// Builds Cash on Delivery section
  Widget _buildCodSection() {
    return Container(
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
      child: _buildPaymentOption(
        id: 'cod',
        name: 'Pay by Cash/QR',
        iconAsset: 'assets/icons/cash.png',
        color: Colors.green,
        isEnabled: true,
        isFirst: true,
        isLast: true,
      ),
    );
  }

  /// Builds UPI option row
  Widget _buildUpiOption({
    required String id,
    required String name,
    IconData? icon,
    String? iconAsset,
    required Color color,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final isSelected = _selectedPaymentMethod == id;

    return InkWell(
      onTap: () => _selectPaymentMethod(id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.vertical(
            top: isFirst ? const Radius.circular(12) : Radius.zero,
            bottom: isLast ? const Radius.circular(12) : Radius.zero,
          ),
        ),
        child: Row(
          children: [
            // Icon or Image
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconAsset != null ? Colors.transparent : color.withValues(alpha: 0.1),
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
                      icon!,
                      color: color,
                      size: 20,
                    ),
            ),
            const SizedBox(width: 16),

            // Name
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),

            // Circular checkbox
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
            ),
          ],
        ),
      ),
    );
  }

  /// Builds divider between options
  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.grey[200],
    );
  }

  /// Builds payment option (for COD)
  Widget _buildPaymentOption({
    required String id,
    required String name,
    IconData? icon,
    String? iconAsset,
    required Color color,
    required bool isEnabled,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final isSelected = _selectedPaymentMethod == id;

    return InkWell(
      onTap: isEnabled ? () => _selectPaymentMethod(id) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.vertical(
            top: isFirst ? const Radius.circular(12) : Radius.zero,
            bottom: isLast ? const Radius.circular(12) : Radius.zero,
          ),
        ),
        child: Row(
          children: [
            // Icon or SVG
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconAsset != null ? Colors.transparent : color.withValues(alpha: 0.1),
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
                      icon!,
                      color: color,
                      size: 20,
                    ),
            ),
            const SizedBox(width: 16),

            // Name
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isEnabled ? Colors.black87 : Colors.grey[500],
                ),
              ),
            ),

            // Circular checkbox
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: (isSelected && isEnabled) ? Colors.green : Colors.grey[400]!,
                  width: 2,
                ),
                color: (isSelected && isEnabled) ? Colors.green : Colors.transparent,
              ),
              child: (isSelected && isEnabled)
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



  /// Handles payment method selection
  void _selectPaymentMethod(String methodId) {
    setState(() {
      _selectedPaymentMethod = methodId;
    });
  }

  /// Handles proceed to pay action
  void _handleProceed(BuildContext context) {
    // Create a simple payment method object for the selected method
    final selectedMethod = {
      'id': _selectedPaymentMethod,
      'title': _selectedPaymentMethod == 'cod' ? 'Cash on Delivery' : 'UPI Payment',
    };

    // Navigate to order processing screen with order data
    _navigateToOrderProcessing(context, selectedMethod);
  }

  /// Navigate to order processing with complete order data
  void _navigateToOrderProcessing(BuildContext context, Map<String, dynamic> paymentMethod) {
    // Get cart data from provider
    final cartState = ref.read(cartNotifierProvider);

    // Get current user
    final authState = ref.read(authNotifierProvider);
    final user = authState.user;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to place an order')),
      );
      return;
    }

    // Get selected address
    final selectedAddress = ref.read(defaultAddressProvider);

    if (selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery address')),
      );
      return;
    }

    // Prepare order data with actual user and address data
    final orderData = {
      'userId': user.id,
      'items': cartState.items.map((item) => {
        'productId': item.product.id,
        'productName': item.product.name,
        'quantity': item.quantity,
        'price': item.product.price,
        'total': item.product.price * item.quantity,
        'image': item.product.mainImageUrl,
      }).toList(),
      'subtotal': cartState.totalPrice,
      'tax': cartState.totalPrice * 0.18, // 18% tax
      'shipping': 0.0, // Free shipping for early launch
      'total': cartState.totalPrice + (cartState.totalPrice * 0.18),
      'paymentMethod': _selectedPaymentMethod,
      'shippingAddress': {
        'id': selectedAddress.id, // Include address ID for proper order creation
        'addressLine1': selectedAddress.addressLine1,
        'addressLine2': selectedAddress.addressLine2,
        'city': selectedAddress.city,
        'state': selectedAddress.state,
        'postalCode': selectedAddress.postalCode,
        'country': selectedAddress.country,
        'latitude': selectedAddress.latitude,
        'longitude': selectedAddress.longitude,
        'landmark': selectedAddress.landmark,
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
