import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dayliz_app/screens/cart_screen.dart';
import 'package:dayliz_app/providers/cart_provider.dart';
import 'package:dayliz_app/screens/order_confirmation_screen.dart';
import 'package:go_router/go_router.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  int _currentStep = 0;
  final _addressFormKey = GlobalKey<FormState>();
  final _paymentFormKey = GlobalKey<FormState>();
  
  // Form controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipController = TextEditingController();
  
  // Payment method selection
  String _selectedPaymentMethod = 'Credit Card';
  
  @override
  void initState() {
    super.initState();
    _loadSavedAddress();
  }
  
  Future<void> _loadSavedAddress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('checkout_name') ?? '';
      _phoneController.text = prefs.getString('checkout_phone') ?? '';
      _addressController.text = prefs.getString('checkout_address') ?? '';
      _cityController.text = prefs.getString('checkout_city') ?? '';
      _zipController.text = prefs.getString('checkout_zip') ?? '';
    });
  }
  
  Future<void> _saveAddress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('checkout_name', _nameController.text);
    await prefs.setString('checkout_phone', _phoneController.text);
    await prefs.setString('checkout_address', _addressController.text);
    await prefs.setString('checkout_city', _cityController.text);
    await prefs.setString('checkout_zip', _zipController.text);
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: Stepper(
        type: StepperType.vertical,
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep == 0) {
            if (_addressFormKey.currentState!.validate()) {
              _saveAddress();
              setState(() {
                _currentStep += 1;
              });
            }
          } else if (_currentStep == 1) {
            if (_paymentFormKey.currentState!.validate()) {
              setState(() {
                _currentStep += 1;
              });
            }
          } else if (_currentStep == 2) {
            _placeOrder();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() {
              _currentStep -= 1;
            });
          }
        },
        steps: [
          Step(
            title: const Text('Shipping Address'),
            content: _buildAddressForm(),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Payment Method'),
            content: _buildPaymentForm(),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Order Summary'),
            content: _buildOrderSummary(),
            isActive: _currentStep >= 2,
            state: _currentStep > 2 ? StepState.complete : StepState.indexed,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressForm() {
    return Form(
      key: _addressFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your phone number';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Address',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your address';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'City',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your city';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _zipController,
                  decoration: const InputDecoration(
                    labelText: 'ZIP Code',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter ZIP code';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPaymentForm() {
    return Form(
      key: _paymentFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Payment Method',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // Payment options
          RadioListTile<String>(
            title: const Row(
              children: [
                Icon(Icons.credit_card),
                SizedBox(width: 10),
                Text('Credit/Debit Card'),
              ],
            ),
            value: 'Credit Card',
            groupValue: _selectedPaymentMethod,
            onChanged: (value) {
              setState(() {
                _selectedPaymentMethod = value!;
              });
            },
          ),
          RadioListTile<String>(
            title: const Row(
              children: [
                Icon(Icons.account_balance_wallet),
                SizedBox(width: 10),
                Text('Digital Wallet'),
              ],
            ),
            value: 'Digital Wallet',
            groupValue: _selectedPaymentMethod,
            onChanged: (value) {
              setState(() {
                _selectedPaymentMethod = value!;
              });
            },
          ),
          RadioListTile<String>(
            title: const Row(
              children: [
                Icon(Icons.money),
                SizedBox(width: 10),
                Text('Cash on Delivery'),
              ],
            ),
            value: 'Cash on Delivery',
            groupValue: _selectedPaymentMethod,
            onChanged: (value) {
              setState(() {
                _selectedPaymentMethod = value!;
              });
            },
          ),
          
          const SizedBox(height: 12),
          
          // If card payment is selected, show card form
          if (_selectedPaymentMethod == 'Credit Card')
            Column(
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Card Number',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (_selectedPaymentMethod == 'Credit Card' && 
                        (value == null || value.isEmpty)) {
                      return 'Please enter card number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Expiry Date (MM/YY)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (_selectedPaymentMethod == 'Credit Card' && 
                              (value == null || value.isEmpty)) {
                            return 'Please enter expiry date';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'CVV',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        validator: (value) {
                          if (_selectedPaymentMethod == 'Credit Card' && 
                              (value == null || value.isEmpty)) {
                            return 'Please enter CVV';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    final cartItems = ref.watch(cartProvider);
    final cartNotifier = ref.watch(cartProvider.notifier);
    
    final subtotal = cartNotifier.totalAmount;
    final shipping = subtotal > 100 ? 0.0 : 5.99;
    final tax = subtotal * 0.08; // 8% tax
    final total = subtotal + shipping + tax;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Order Items',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        
        // Order items
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cartItems.length,
          itemBuilder: (context, index) {
            final item = cartItems[index];
            final product = item.product;
            final itemPrice = product.price * item.quantity;
            
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(product.name),
              subtitle: Text('Qty: ${item.quantity}'),
              trailing: Text(
                '\$${itemPrice.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            );
          },
        ),
        
        const Divider(),
        
        // Price summary
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Subtotal'),
            Text('\$${subtotal.toStringAsFixed(2)}'),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Shipping'),
            shipping > 0 
                ? Text('\$${shipping.toStringAsFixed(2)}')
                : const Text('FREE', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Tax'),
            Text('\$${tax.toStringAsFixed(2)}'),
          ],
        ),
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              '\$${total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.green,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 20),
        
        // Shipping address summary
        const Text(
          'Shipping Address',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(_nameController.text.isNotEmpty ? _nameController.text : 'Not provided'),
        Text(_addressController.text.isNotEmpty ? _addressController.text : 'Not provided'),
        Text(
          '${_cityController.text.isNotEmpty ? _cityController.text : 'Not provided'}, ${_zipController.text.isNotEmpty ? _zipController.text : 'Not provided'}',
        ),
        Text(_phoneController.text.isNotEmpty ? _phoneController.text : 'Not provided'),
        
        const SizedBox(height: 20),
        
        // Payment method summary
        const Text(
          'Payment Method',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(_selectedPaymentMethod),
      ],
    );
  }

  void _placeOrder() {
    final cartNotifier = ref.read(cartProvider.notifier);
    final cartItems = ref.read(cartProvider);
    
    // Create order details to pass to confirmation screen
    final orderDetails = {
      'orderId': 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(0, 10)}',
      'orderDate': DateTime.now(),
      'items': cartItems,
      'shippingAddress': {
        'name': _nameController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
        'city': _cityController.text,
        'zip': _zipController.text,
      },
      'paymentMethod': _selectedPaymentMethod,
      'subtotal': cartNotifier.totalAmount,
      'shipping': cartNotifier.totalAmount > 100 ? 0.0 : 5.99,
      'tax': cartNotifier.totalAmount * 0.08,
      'total': cartNotifier.totalAmount + (cartNotifier.totalAmount > 100 ? 0.0 : 5.99) + (cartNotifier.totalAmount * 0.08),
    };
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    // Simulate order processing
    Future.delayed(const Duration(seconds: 2), () {
      // Clear the cart
      cartNotifier.clearCart();
      
      Navigator.pop(context); // Close loading dialog
      
      // Navigate to order confirmation screen using Go Router
      context.go('/order-confirmation', extra: orderDetails);
    });
  }
} 