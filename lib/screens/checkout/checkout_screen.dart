import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dayliz_app/providers/cart_provider.dart';
import 'package:dayliz_app/providers/address_provider.dart';
import 'package:dayliz_app/models/address.dart';
import 'package:dayliz_app/models/cart_item.dart';
import 'package:dayliz_app/models/order.dart';
import 'package:dayliz_app/providers/order_provider.dart';
import 'package:dayliz_app/providers/auth_provider.dart';
import 'package:dayliz_app/widgets/address_selection_widget.dart';
import 'package:dayliz_app/widgets/payment_method_widget.dart';
import 'package:dayliz_app/theme/dayliz_theme.dart';
import 'package:dayliz_app/widgets/dayliz_button.dart';
import 'package:go_router/go_router.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  int _currentStep = 0;
  String _selectedPaymentMethod = 'card';
  bool _isProcessing = false;
  
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final addressState = ref.watch(addressProvider);
    final selectedAddress = ref.watch(selectedAddressProvider);
    
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: cartState.isEmpty
          ? _buildEmptyCart()
          : Column(
              children: [
                Expanded(
                  child: Stepper(
                    type: StepperType.horizontal,
        currentStep: _currentStep,
        onStepContinue: () {
                      if (_currentStep < 2) {
                        if (_currentStep == 0 && selectedAddress == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please select or add an address')),
                          );
                          return;
                        }
              setState(() {
                          _currentStep++;
              });
                      } else {
            _placeOrder();
          }
        },
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
                            DaylizButton(
                              label: _currentStep == 2 ? 'Place Order' : 'Continue',
                              onPressed: details.onStepContinue!,
                              loading: _isProcessing,
                            ),
                            if (_currentStep > 0)
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: TextButton(
                                  onPressed: details.onStepCancel,
                                  child: const Text('Back'),
                                ),
                              ),
                          ],
                        ),
                      );
        },
        steps: [
          Step(
                        title: const Text('Address'),
                        content: _buildAddressStep(),
            isActive: _currentStep >= 0,
          ),
          Step(
                        title: const Text('Payment'),
                        content: _buildPaymentStep(),
            isActive: _currentStep >= 1,
          ),
          Step(
                        title: const Text('Review'),
            content: _buildOrderSummary(),
            isActive: _currentStep >= 2,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shopping_cart_outlined, size: 72, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Your cart is empty',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add items to your cart to proceed with checkout',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          DaylizButton(
            label: 'Continue Shopping',
            onPressed: () => context.go('/home'),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressStep() {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
          'Select a delivery address',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        // Address selection widget that shows the list of addresses
        // and allows adding new addresses
        const AddressSelectionWidget(),
        
        const SizedBox(height: 16),
        // Display selected address details
        _buildSelectedAddressSection(),
      ],
    );
  }
  
  Widget _buildSelectedAddressSection() {
    final selectedAddress = ref.watch(selectedAddressProvider);
    
    if (selectedAddress == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Please select an address for delivery'),
        ),
      );
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Delivering to:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                if (selectedAddress.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Default',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              selectedAddress.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(selectedAddress.addressLine1),
            if (selectedAddress.addressLine2 != null && selectedAddress.addressLine2!.isNotEmpty)
              Text(selectedAddress.addressLine2!),
            Text('${selectedAddress.city}, ${selectedAddress.state} ${selectedAddress.postalCode}'),
            Text(selectedAddress.country),
            if (selectedAddress.phone != null) ...[
              const SizedBox(height: 4),
              Text('Phone: ${selectedAddress.phone}'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentStep() {
    return PaymentMethodWidget(
      selectedMethod: _selectedPaymentMethod,
      onMethodSelected: (method) {
        setState(() {
          _selectedPaymentMethod = method;
        });
      },
    );
  }

  Widget _buildOrderSummary() {
    final cartState = ref.watch(cartProvider);
    final selectedAddress = ref.watch(selectedAddressProvider);
    
    // Calculate totals
    final subtotal = cartState.fold<double>(
      0, (sum, item) => sum + (item.price * item.quantity));
    
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
        ...cartState.map((item) => _buildOrderItem(item)),
        
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
        if (selectedAddress != null) ...[
          const Text(
            'Shipping Address',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
          Text(selectedAddress.name),
          Text(selectedAddress.formattedAddress),
          if (selectedAddress.phone != null)
            Text('Phone: ${selectedAddress.phone}'),
        ],
        
        const SizedBox(height: 16),
        
        // Payment method summary
        const Text(
          'Payment Method',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(_getPaymentIcon(), size: 20),
            const SizedBox(width: 8),
            Text(_getPaymentMethodName()),
          ],
        ),
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
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage(item.imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
                  '${item.quantity} x \$${item.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.grey[600],
              ),
            ),
          ],
        ),
          ),
          Text(
            '\$${(item.price * item.quantity).toStringAsFixed(2)}',
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
  
  IconData _getPaymentIcon() {
    switch (_selectedPaymentMethod) {
      case 'card':
        return Icons.credit_card;
      case 'paypal':
        return Icons.account_balance_wallet;
      case 'cod':
        return Icons.money;
      default:
        return Icons.payment;
    }
  }
  
  String _getPaymentMethodName() {
    switch (_selectedPaymentMethod) {
      case 'card':
        return 'Credit/Debit Card';
      case 'paypal':
        return 'PayPal';
      case 'cod':
        return 'Cash on Delivery';
      default:
        return 'Unknown Payment Method';
    }
  }
  
  Future<void> _placeOrder() async {
    final cartState = ref.read(cartProvider);
    final selectedAddress = ref.read(selectedAddressProvider);
    final currentUser = ref.read(currentUserProvider);
    
    // Validate address
    if (selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery address')),
      );
      setState(() {
        _currentStep = 0; // Go back to address step
      });
      return;
    }
    
    // Validate user is logged in
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to place an order')),
      );
      return;
    }
    
    setState(() {
      _isProcessing = true;
    });
    
    try {
      // Calculate totals
      final subtotal = cartState.fold<double>(
        0, (sum, item) => sum + (item.price * item.quantity));
      
      final shipping = 5.99;
      final tax = subtotal * 0.07;
      final total = subtotal + shipping + tax;
      
      // Convert to order items
      final orderItems = cartState.map((item) => OrderItem(
        productId: item.productId,
        name: item.name,
        imageUrl: item.imageUrl,
        price: item.price,
        quantity: item.quantity,
        discountAmount: item.discountedPrice != null ? 
          item.price - item.discountedPrice! : null,
        attributes: item.attributes,
      )).toList();
      
      // Determine payment method enum from string
      final paymentMethod = _getPaymentMethodEnum();
      
      // Create order
      final orderNotifier = ref.read(orderNotifierProvider.notifier);
      final order = await orderNotifier.createOrder(
        userId: currentUser.id,
        items: orderItems,
        totalAmount: total,
        shippingAddress: OrderAddress.fromAddress(selectedAddress),
        paymentMethod: paymentMethod,
      );
      
      // Clear cart on successful order
      if (order != null) {
        ref.read(cartProvider.notifier).clearCart();
        
        // Navigate to order confirmation
        if (mounted) {
          context.go('/order-confirmation/${order.id}');
        }
      } else {
        throw Exception('Failed to create order');
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
  
  PaymentMethod _getPaymentMethodEnum() {
    switch (_selectedPaymentMethod) {
      case 'card':
        return PaymentMethod.creditCard;
      case 'paypal':
        return PaymentMethod.wallet;
      case 'cod':
        return PaymentMethod.cashOnDelivery;
      default:
        return PaymentMethod.cashOnDelivery;
    }
  }
  
  @override
  void dispose() {
    super.dispose();
  }
} 