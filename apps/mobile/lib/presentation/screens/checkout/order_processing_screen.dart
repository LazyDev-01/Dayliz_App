import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/order_service.dart';
import '../../../core/services/network_service.dart';
import '../order/order_summary_screen.dart';

/// Order processing screen with beautiful animations
/// Shows while the order is being processed in the backend
class OrderProcessingScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> orderData;
  final VoidCallback? onSuccess;
  final VoidCallback? onError;

  const OrderProcessingScreen({
    Key? key,
    required this.orderData,
    this.onSuccess,
    this.onError,
  }) : super(key: key);

  @override
  ConsumerState<OrderProcessingScreen> createState() => _OrderProcessingScreenState();
}

class _OrderProcessingScreenState extends ConsumerState<OrderProcessingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

  String _currentMessage = 'Processing your order...';
  bool _isProcessing = true;
  bool _isSuccess = false;
  bool _isError = false;
  String? _errorMessage;

  final List<String> _processingMessages = [
    'Processing your order...',
    'Verifying payment details...',
    'Confirming product availability...',
    'Preparing your order...',
    'Almost done...',
  ];

  int _messageIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startOrderProcessing();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
    _fadeController.forward();
  }

  void _startOrderProcessing() {
    // Cycle through processing messages
    _cycleMessages();

    // Simulate order processing
    Future.delayed(const Duration(seconds: 6), () {
      _processOrder();
    });
  }

  void _cycleMessages() {
    if (!_isProcessing) return;

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted && _isProcessing) {
        setState(() {
          _messageIndex = (_messageIndex + 1) % _processingMessages.length;
          _currentMessage = _processingMessages[_messageIndex];
        });
        _cycleMessages();
      }
    });
  }

  Future<void> _processOrder() async {
    try {
      debugPrint('OrderProcessingScreen: Starting order processing');

      // Get current user
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        _showError('User not authenticated. Please login again.');
        return;
      }

      // Extract order data
      final orderData = widget.orderData;
      final items = orderData['items'] as List<dynamic>;
      final subtotal = (orderData['subtotal'] as num).toDouble();
      final tax = (orderData['tax'] as num).toDouble();
      final shipping = (orderData['shipping'] as num).toDouble();
      final total = (orderData['total'] as num).toDouble();
      final paymentMethod = orderData['paymentMethod'] as String;

      debugPrint('OrderProcessingScreen: Order data extracted - Total: $total, Items: ${items.length}');

      // Validate required data
      if (items.isEmpty) {
        _showError('No items in cart. Please add items before placing order.');
        return;
      }

      if (total <= 0) {
        _showError('Invalid order total. Please check your cart.');
        return;
      }

      // Get delivery address ID from the selected address in orderData
      String? deliveryAddressId;

      // Extract address from orderData (passed from checkout screen)
      final shippingAddress = orderData['shippingAddress'] as Map<String, dynamic>?;

      if (shippingAddress != null && shippingAddress['id'] != null) {
        // Use the selected address ID from checkout
        deliveryAddressId = shippingAddress['id'] as String;
        debugPrint('OrderProcessingScreen: Using selected address ID: $deliveryAddressId');
      } else {
        // Fallback: find any address for the user (this should rarely happen)
        debugPrint('OrderProcessingScreen: No address ID in orderData, falling back to first address');
        try {
          final addressResponse = await Supabase.instance.client
              .from('addresses')
              .select('id')
              .eq('user_id', user.id)
              .limit(1);

          if (addressResponse.isNotEmpty) {
            deliveryAddressId = addressResponse.first['id'];
            debugPrint('OrderProcessingScreen: Using fallback address ID: $deliveryAddressId');
          }
        } catch (e) {
          debugPrint('OrderProcessingScreen: Error getting fallback address: $e');
        }
      }

      if (deliveryAddressId == null) {
        _showError('No delivery address found. Please add an address first.');
        return;
      }

      // Prepare order items for database
      final orderItems = items.map((item) => {
        'product_id': item['productId'],
        'product_name': item['productName'],
        'quantity': item['quantity'],
        'price': (item['price'] as num).toDouble(),
        'total': (item['total'] as num).toDouble(),
        'image_url': item['imageUrl'] ?? '', // Include product image
        'weight': item['weight'] ?? '', // Include product weight
      }).toList();

      debugPrint('OrderProcessingScreen: Creating order with ${orderItems.length} items');

      // Create order service
      final orderService = OrderService(supabaseClient: Supabase.instance.client);

      // Create order
      final order = await orderService.createOrder(
        userId: user.id,
        items: orderItems,
        subtotal: subtotal,
        tax: tax,
        shipping: shipping,
        total: total,
        paymentMethod: paymentMethod,
        deliveryAddressId: deliveryAddressId,
        notes: 'Order placed via mobile app',
      );

      debugPrint('OrderProcessingScreen: Order created successfully - ID: ${order.id}');

      // Clear cart after successful order
      widget.onSuccess?.call();

      // Check if this is an offline order
      if (order.status == 'queued') {
        // Handle offline order
        _showOfflineSuccess(order.orderNumber ?? 'OFFLINE-ORDER');
      } else {
        // Show normal success and navigate to order summary
        _showSuccess(order.id);
      }

    } catch (e) {
      debugPrint('OrderProcessingScreen: Order failed - ${e.toString()}');

      // Classify error type for appropriate handling
      final errorType = NetworkService.classifyError(e);
      String? errorMessage;

      switch (errorType) {
        case NetworkErrorType.connectivity:
          errorMessage = 'Poor network connection. Please check your internet and try again.';
          break;

        case NetworkErrorType.server:
          errorMessage = 'Our servers are temporarily busy. Please try again in a moment.';
          break;

        case NetworkErrorType.authentication:
          errorMessage = 'Please login again to place your order.';
          break;

        case NetworkErrorType.business:
          // Handle specific business logic errors
          if (e.toString().contains('Product not found')) {
            errorMessage = 'Some products in your cart are no longer available.';
          } else if (e.toString().contains('out of stock') || e.toString().contains('Insufficient stock')) {
            final errorString = e.toString();
            if (errorString.contains('Insufficient stock for some items:')) {
              errorMessage = errorString.replaceFirst('ServerException: ', '');
            } else {
              errorMessage = 'Some products in your cart are out of stock. Please update quantities and try again.';
            }
          } else if (e.toString().contains('delivery_address_id')) {
            errorMessage = 'Please add a delivery address before placing your order.';
          } else if (e.toString().contains('Invalid payment method')) {
            errorMessage = 'Please select a valid payment method.';
          } else if (e.toString().contains('Minimum order amount')) {
            errorMessage = 'Minimum order amount is ₹99. Please add more items to your cart.';
          } else if (e.toString().contains('Maximum order amount')) {
            errorMessage = 'Order amount exceeds maximum limit. Please contact support.';
          } else if (e.toString().contains('COD order') && e.toString().contains('limit')) {
            final errorString = e.toString();
            if (errorString.contains('ServerException: ')) {
              errorMessage = errorString.replaceFirst('ServerException: ', '');
            } else {
              errorMessage = 'COD order limit exceeded. Please use online payment.';
            }
          } else {
            errorMessage = 'Please check your order details and try again.';
          }
          break;
      }

      // Use fallback message if none set
      final finalErrorMessage = errorMessage ?? 'Something went wrong. Please try again.';

      _showError(finalErrorMessage);
    }
  }

  void _showSuccess(String orderId) {
    if (!mounted) return;

    setState(() {
      _isProcessing = false;
      _isSuccess = true;
      _currentMessage = 'Order placed successfully!';
    });

    _pulseController.stop();

    // Navigate to order summary after delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        widget.onSuccess?.call();
        // Navigate to order summary with real order ID
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => OrderSummaryScreen(
              orderId: orderId,
              orderData: widget.orderData,
            ),
          ),
        );
      }
    });
  }

  void _showError(String message) {
    if (!mounted) return;

    setState(() {
      _isProcessing = false;
      _isError = true;
      _errorMessage = message;
      _currentMessage = 'Order failed';
    });

    _pulseController.stop();
    widget.onError?.call();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back navigation during processing
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  _buildAnimationSection(),
                  const SizedBox(height: 48),
                  _buildMessageSection(),
                  const Spacer(),
                  if (_isError) _buildErrorActions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimationSection() {
    if (_isSuccess) {
      return _buildSuccessAnimation();
    } else if (_isError) {
      return _buildErrorAnimation();
    } else {
      return _buildProcessingAnimation();
    }
  }

  Widget _buildProcessingAnimation() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.7),
                  Theme.of(context).primaryColor,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  spreadRadius: 5,
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuccessAnimation() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.green,
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            spreadRadius: 5,
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.check,
          color: Colors.white,
          size: 60,
        ),
      ),
    );
  }

  Widget _buildErrorAnimation() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.red,
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            spreadRadius: 5,
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.close,
          color: Colors.white,
          size: 60,
        ),
      ),
    );
  }

  Widget _buildMessageSection() {
    return Column(
      children: [
        Text(
          _currentMessage,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        if (_isError && _errorMessage != null) ...[
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ] else if (_isProcessing) ...[
          const SizedBox(height: 16),
          Text(
            'Please wait while we process your order',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ] else if (_isSuccess) ...[
          const SizedBox(height: 16),
          Text(
            'Thank you for your order! You will receive a confirmation shortly.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildErrorActions() {
    return Column(
      children: [
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Try Again',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            context.go('/home');
          },
          child: const Text(
            'Back to Home',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  void _showOfflineSuccess(String orderNumber) {
    setState(() {
      _isProcessing = false;
      _isSuccess = true;
      _isError = false;
      _currentMessage = 'Order queued successfully!';
      _errorMessage = 'Your order will be processed when connection is restored.\nOrder Number: $orderNumber';
    });

    // Auto-navigate after delay
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        context.go('/home');
      }
    });
  }
}
