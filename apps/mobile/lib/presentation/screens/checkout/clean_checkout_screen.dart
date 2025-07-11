import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/cart_item.dart';
import '../../../domain/entities/address.dart';
import '../../../domain/entities/payment_method.dart';
import '../../providers/auth_providers.dart';
import '../../providers/cart_providers.dart';
import '../../providers/payment_method_providers.dart';
import '../../providers/user_profile_providers.dart';
import '../../widgets/address/clean_address_selection_widget.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/common/unified_app_bar.dart';
import '../../widgets/payment/payment_method_card.dart';
import '../../widgets/payment/modern_payment_options_widget.dart';
import 'order_processing_screen.dart';

class CleanCheckoutScreen extends ConsumerStatefulWidget {
  const CleanCheckoutScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CleanCheckoutScreen> createState() => _CleanCheckoutScreenState();
}

class _CleanCheckoutScreenState extends ConsumerState<CleanCheckoutScreen> {
  int _currentStep = 0;
  bool _isProcessing = false;
  String? _selectedPaymentMethod; // Selected payment method

  @override
  Widget build(BuildContext context) {
    // Watch cart state
    final cartState = ref.watch(cartNotifierProvider);

    // Get current user
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final isAuthenticated = authState.isAuthenticated;

    return Scaffold(
      appBar: UnifiedAppBars.withBackButton(
        title: 'Checkout',
        fallbackRoute: '/cart',
      ),
      body: !isAuthenticated
          ? _buildNotLoggedInState()
          : (cartState.items.isEmpty
              ? _buildEmptyCartState()
              : _buildCheckoutStepper(cartState, user?.id ?? ''))
    );
  }

  Widget _buildNotLoggedInState() {
    return EmptyState(
      icon: Icons.login,
      title: 'Not Logged In',
      message: 'Please log in to proceed with checkout',
      buttonText: 'Log In',
      onButtonPressed: () => context.go('/clean/login'),
    );
  }

  Widget _buildEmptyCartState() {
    return EmptyState(
      icon: Icons.shopping_cart_outlined,
      title: 'Your cart is empty',
      message: 'Add items to your cart to proceed with checkout',
      buttonText: 'Continue Shopping',
      onButtonPressed: () => context.go('/clean/home'),
    );
  }

  Widget _buildCheckoutStepper(CartState cartState, String userId) {
    return Stepper(
      type: StepperType.horizontal,
      currentStep: _currentStep,
      onStepContinue: () => _handleStepContinue(userId),
      onStepCancel: () {
        if (_currentStep > 0) {
          setState(() {
            _currentStep--;
          });
        }
      },
      controlsBuilder: (context, details) {
        return Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Row(
            children: [
              PrimaryButton(
                text: _currentStep == 2 ? 'Place Order' : 'Continue',
                onPressed: details.onStepContinue!,
                isLoading: _isProcessing,
                isFullWidth: false,
              ),
              if (_currentStep > 0) ...[
                const SizedBox(width: 12),
                TextButton(
                  onPressed: details.onStepCancel,
                  child: const Text('Back'),
                ),
              ],
            ],
          ),
        );
      },
      steps: [
        Step(
          title: const Text('Shipping'),
          content: _buildShippingStep(),
          isActive: _currentStep >= 0,
          state: _currentStep > 0 ? StepState.complete : StepState.indexed,
        ),
        Step(
          title: const Text('Payment'),
          content: _buildPaymentStep(userId),
          isActive: _currentStep >= 1,
          state: _currentStep > 1 ? StepState.complete : StepState.indexed,
        ),
        Step(
          title: const Text('Review'),
          content: _buildReviewStep(cartState, userId),
          isActive: _currentStep >= 2,
          state: _currentStep > 2 ? StepState.complete : StepState.indexed,
        ),
      ],
    );
  }

  Widget _buildShippingStep() {
    // Get the selected address
    final selectedAddress = ref.watch(defaultAddressProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Shipping Address',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Use our clean architecture address selection widget
        const CleanAddressSelectionWidget(),

        const SizedBox(height: 16),

        // Add address button
        if (selectedAddress == null)
          OutlinedButton.icon(
            onPressed: () => context.push('/address/add'),
            icon: const Icon(Icons.add_location_alt),
            label: const Text('Add New Address'),
          ),
      ],
    );
  }

  Widget _buildPaymentStep(String userId) {
    // Watch payment methods state
    final paymentMethodState = ref.watch(paymentMethodNotifierProvider(userId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Method',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        if (paymentMethodState.isLoading)
          const Center(child: LoadingIndicator())
        else if (paymentMethodState.errorMessage != null)
          ErrorState(
            message: paymentMethodState.errorMessage!,
            onRetry: () => ref.read(paymentMethodNotifierProvider(userId).notifier).loadPaymentMethods(),
          )
        else if (paymentMethodState.methods.isEmpty)
          // Modern payment options button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.payment,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 12),
                Text(
                  _selectedPaymentMethod != null
                      ? _getPaymentMethodDisplayName(_selectedPaymentMethod!)
                      : 'Select Payment Method',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose from UPI, Wallets & Cash on Delivery',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _openPaymentOptions(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Choose Payment Method'),
                ),
              ],
            ),
          )
        else
          _buildPaymentMethodsList(paymentMethodState, userId),

        const SizedBox(height: 16),

        // Add payment method button
        OutlinedButton.icon(
          onPressed: () => context.push('/payment-methods'),
          icon: const Icon(Icons.add),
          label: const Text('Choose Payment Method'),
        ),
      ],
    );
  }

  Widget _buildNoPaymentMethodsState(String userId) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.credit_card_off, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No Payment Methods',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please add a payment method to continue with checkout',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              text: 'Choose Payment Method',
              onPressed: () => context.push('/payment-methods'),
              isFullWidth: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodsList(PaymentMethodState state, String userId) {
    return Column(
      children: state.methods.map((method) {
        final isSelected = state.selectedMethod?.id == method.id;

        return PaymentMethodCard(
          paymentMethod: method,
          isSelected: isSelected,
          onTap: () => ref.read(paymentMethodNotifierProvider(userId).notifier)
              .selectPaymentMethod(method.id),
        );
      }).toList(),
    );
  }

  Widget _buildReviewStep(CartState cartState, String userId) {
    // Get selected payment method
    final selectedMethod = ref.watch(paymentMethodNotifierProvider(userId)).selectedMethod;

    // Calculate totals
    final subtotal = cartState.totalPrice;
    final shipping = 5.99; // Example shipping cost
    final tax = subtotal * 0.07; // Example tax rate (7%)
    final total = subtotal + shipping + tax;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Order Summary',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Items in cart
        ...cartState.items.map((item) => _buildOrderItem(item)),

        const Divider(height: 32),

        // Price breakdown
        _buildPriceRow('Subtotal', '\$${subtotal.toStringAsFixed(2)}'),
        _buildPriceRow('Shipping', '\$${shipping.toStringAsFixed(2)}'),
        _buildPriceRow('Tax', '\$${tax.toStringAsFixed(2)}'),
        const Divider(height: 16),
        _buildPriceRow(
          'Total',
          '\$${total.toStringAsFixed(2)}',
          isTotal: true,
        ),

        const SizedBox(height: 24),

        // Shipping address summary
        const Text(
          'Shipping Address',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Builder(builder: (context) {
          final address = ref.watch(defaultAddressProvider);
          if (address != null) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(address.recipientName ?? 'Recipient'),
                Text(address.addressLine1),
                if (address.addressLine2.isNotEmpty) Text(address.addressLine2),
                Text('${address.city}, ${address.state} ${address.postalCode}'),
                Text(address.country),
                if (address.phoneNumber != null) Text('Phone: ${address.phoneNumber}'),
              ],
            );
          } else {
            return const Text('Please select a shipping address');
          }
        }),

        const SizedBox(height: 16),

        // Payment method summary
        const Text(
          'Payment Method',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (selectedMethod != null)
          Row(
            children: [
              _buildPaymentMethodIcon(selectedMethod),
              const SizedBox(width: 8),
              Text(selectedMethod.displayName),
            ],
          )
        else
          const Text('Please select a payment method'),
      ],
    );
  }

  Widget _buildOrderItem(CartItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade200,
            ),
            child: Center(
              child: Text(
                item.product.name.substring(0, 1),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${item.quantity} x \$${item.product.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\$${(item.product.price * item.quantity).toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodIcon(PaymentMethod method) {
    IconData iconData;
    Color iconColor;

    switch (method.type) {
      case PaymentMethod.typeCreditCard:
      case PaymentMethod.typeDebitCard:
        if (method.cardType == 'visa') {
          iconData = Icons.credit_card;
          iconColor = Colors.blue;
        } else if (method.cardType == 'mastercard') {
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

    return Icon(iconData, color: iconColor);
  }

  void _handleStepContinue(String userId) async {
    if (_currentStep < 2) {
      // Validate current step before proceeding
      if (_currentStep == 0) {
        // Check if an address is selected
        final selectedAddress = ref.read(defaultAddressProvider);
        if (selectedAddress == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a delivery address')),
          );
          return;
        }
      } else if (_currentStep == 1) {
        // Check if a payment method is selected
        final selectedMethod = ref.read(paymentMethodNotifierProvider(userId)).selectedMethod;
        if (selectedMethod == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a payment method')),
          );
          return;
        }
      }

      setState(() {
        _currentStep++;
      });
    } else {
      // Place order
      await _placeOrder(userId);
    }
  }

  Future<void> _placeOrder(String userId) async {
    // Get cart items, address, and payment method
    final cartState = ref.read(cartNotifierProvider);
    final selectedAddress = ref.read(defaultAddressProvider);

    // Validate required data
    if (selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery address')),
      );
      setState(() {
        _currentStep = 0; // Go back to address step
      });
      return;
    }

    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method')),
      );
      setState(() {
        _currentStep = 1; // Go back to payment step
      });
      return;
    }

    // Prepare order data
    final orderData = {
      'userId': userId,
      'items': cartState.items.map((item) => {
        'productId': item.product.id,
        'productName': item.product.name,
        'quantity': item.quantity,
        'price': item.product.discountedPrice, // Use discounted price
        'total': item.product.discountedPrice * item.quantity,
        'imageUrl': item.product.mainImageUrl, // Include product image
        'weight': item.product.attributes?['weight'] ?? '', // Include weight from attributes
      }).toList(),
      'subtotal': cartState.totalPrice,
      'tax': cartState.totalPrice * 0.18, // 18% tax
      'shipping': 0.0, // Free shipping for now
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
    if (mounted) {
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
            },
          ),
        ),
      );
    }
  }

  /// Opens the modern payment options screen
  void _openPaymentOptions(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModernPaymentOptionsWidget(
          selectedPaymentMethod: _selectedPaymentMethod,
          onPaymentMethodSelected: (method) {
            setState(() {
              _selectedPaymentMethod = method;
            });
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  /// Gets display name for payment method
  String _getPaymentMethodDisplayName(String method) {
    switch (method) {
      case 'phonepe':
        return 'PhonePe';
      case 'googlepay':
        return 'Google Pay';
      case 'paytm':
        return 'Paytm';
      case 'amazonpay':
        return 'Amazon Pay';
      case 'mobikwik':
        return 'Mobikwik';
      case 'cod':
        return 'Cash on Delivery';
      default:
        return 'Payment Method';
    }
  }
}