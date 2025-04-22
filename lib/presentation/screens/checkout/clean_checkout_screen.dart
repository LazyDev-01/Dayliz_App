import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/cart_item.dart';
import '../../../models/payment_method.dart';
import '../../providers/auth_providers.dart';
import '../../providers/cart_providers.dart';
import '../../providers/payment_method_providers.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/payment/payment_method_card.dart';

class CleanCheckoutScreen extends ConsumerStatefulWidget {
  const CleanCheckoutScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CleanCheckoutScreen> createState() => _CleanCheckoutScreenState();
}

class _CleanCheckoutScreenState extends ConsumerState<CleanCheckoutScreen> {
  int _currentStep = 0;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    // Watch cart state
    final cartState = ref.watch(cartNotifierProvider);
    
    // Get current user
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final isAuthenticated = authState.isAuthenticated;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
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
    // In a real app, you would have a shipping address selection widget here
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Shipping Address',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        // Placeholder for shipping address selection
        // This would be replaced with a real widget in your app
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Home',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Default',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('John Doe'),
                const Text('123 Main Street'),
                const Text('Apt 4B'),
                const Text('New York, NY 10001'),
                const Text('United States'),
                const SizedBox(height: 8),
                const Text('Phone: (123) 456-7890'),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Change address button - would navigate to address selection
        OutlinedButton.icon(
          onPressed: () {
            // Navigate to address selection screen
          },
          icon: const Icon(Icons.edit_location_alt),
          label: const Text('Change Address'),
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
          _buildNoPaymentMethodsState(userId)
        else
          _buildPaymentMethodsList(paymentMethodState, userId),
        
        const SizedBox(height: 16),
        
        // Add payment method button
        OutlinedButton.icon(
          onPressed: () => context.push('/clean/payment-methods'),
          icon: const Icon(Icons.add),
          label: const Text('Manage Payment Methods'),
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
              text: 'Add Payment Method',
              onPressed: () => context.push('/clean/payment-methods'),
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
              .selectPaymentMethod(method.id!),
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
        const Text('John Doe'),
        const Text('123 Main Street, Apt 4B'),
        const Text('New York, NY 10001'),
        const Text('United States'),
        const Text('Phone: (123) 456-7890'),
        
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
      case 'credit_card':
      case 'debit_card':
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
      case 'upi':
        iconData = Icons.account_balance;
        iconColor = Colors.green;
        break;
      case 'cod':
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
      if (_currentStep == 1) {
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
    // Get cart items and payment method
    final cartState = ref.read(cartNotifierProvider);
    final selectedMethod = ref.read(paymentMethodNotifierProvider(userId)).selectedMethod;
    
    // Validate required data
    if (selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method')),
      );
      return;
    }
    
    setState(() {
      _isProcessing = true;
    });
    
    try {
      // Simulate order processing
      await Future.delayed(const Duration(seconds: 2));
      
      // Clear cart
      await ref.read(cartNotifierProvider.notifier).clearCart();
      
      // Show order success and navigate to order confirmation
      if (mounted) {
        context.go('/clean/order-confirmation/123'); // Sample order ID
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error placing order: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
} 