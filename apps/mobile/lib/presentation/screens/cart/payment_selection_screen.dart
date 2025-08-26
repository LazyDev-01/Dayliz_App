import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../../../core/constants/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../../../core/services/order_service.dart';
import '../../../core/services/connectivity_checker.dart';

import '../../../data/models/upi_payment_model.dart';
import '../../providers/cart_providers.dart';
import '../../providers/user_profile_providers.dart';
import '../../providers/auth_providers.dart';
import '../../providers/supabase_providers.dart';

import '../payment/payment_processing_screen.dart';

// HTTP client provider
final httpClientProvider = Provider<http.Client>((ref) => http.Client());

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
  bool _isCreatingOrder = false; // Loading state for order creation
  bool _isNavigating = false; // Prevent double navigation

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
          // GooglePay (First) - Coming Soon
          _buildUpiOption(
            id: 'googlepay',
            name: 'GooglePay',
            iconAsset: 'assets/icons/googlepay.png',
            color: const Color(0xFF4285F4),
            isFirst: true,
            isComingSoon: true,
          ),
          _buildDivider(),

          // Paytm (Second) - Coming Soon
          _buildUpiOption(
            id: 'paytm',
            name: 'Paytm',
            iconAsset: 'assets/icons/paytm.png',
            color: const Color(0xFF00BAF2),
            isComingSoon: true,
          ),
          _buildDivider(),

          // PhonePe (Third) - Coming Soon
          _buildUpiOption(
            id: 'phonepe',
            name: 'PhonePe',
            iconAsset: 'assets/icons/phonepe.png',
            color: const Color(0xFF5F259F),
            isLast: true,
            isComingSoon: true,
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
    bool isComingSoon = false,
  }) {
    final isSelected = _selectedPaymentMethod == id && !isComingSoon;

    return InkWell(
      onTap: isComingSoon ? null : () => _selectPaymentMethod(id),
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

            // Name with Coming Soon
            Expanded(
              child: Row(
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isComingSoon ? Colors.grey[500] : Colors.black87,
                    ),
                  ),
                  if (isComingSoon) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
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
              onTap: (_selectedPaymentMethod != null && !_isCreatingOrder)
                  ? () => _handleProceed(context)
                  : null,
              child: Center(
                child: _isCreatingOrder
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        _selectedPaymentMethod == 'cod'
                            ? 'Place Order (COD)'
                            : 'Proceed to Pay',
                        style: const TextStyle(
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
  Future<void> _handleProceed(BuildContext context) async {
    if (_isCreatingOrder || _isNavigating) return; // Prevent multiple taps and navigation

    // Store context references for safe usage
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Check if trying to use UPI (which is coming soon)
    if (_selectedPaymentMethod != 'cod') {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('UPI payments are coming soon! Please use Cash on Delivery for now.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _isCreatingOrder = true;
    });

    try {
      // Check network connectivity first
      final hasConnection = await ConnectivityChecker.hasConnection(fastMode: true);
      if (!hasConnection) {
        if (!mounted) return;

        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: const Text('No internet connection. Please check your network and try again.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _handleProceed(context),
            ),
          ),
        );
        return;
      }

      // Create order first
      final orderId = await _createOrder();

      if (!mounted) return;

      // Set navigation lock
      setState(() {
        _isNavigating = true;
      });

      // For COD, validate and navigate directly to order summary
      await _handleCODOrderCompletion(context, orderId);

    } catch (e) {
      if (!mounted) return;

      // Classify error type for appropriate user message
      final errorMessage = _getUserFriendlyErrorMessage(e);

      // Show user-friendly error message
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () => _createOrderAndNavigate(context),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingOrder = false;
          _isNavigating = false;
        });
      }
    }
  }

  /// Creates order and returns order ID
  Future<String> _createOrder() async {
    // Get cart data from provider
    final cartState = ref.read(cartNotifierProvider);

    // Get current user
    final authState = ref.read(authNotifierProvider);
    final user = authState.user;

    if (user == null) {
      throw Exception('User not authenticated');
    }

    // Get selected address
    final selectedAddress = ref.read(defaultAddressProvider);

    if (selectedAddress == null) {
      throw Exception('Please select a delivery address');
    }

    // Calculate totals
    final subtotal = cartState.items.fold<double>(
      0.0,
      (sum, item) => sum + (item.product.price * item.quantity),
    );

    final deliveryFee = subtotal >= 999 ? 0.0 : 25.0;
    final total = subtotal + deliveryFee;

    // Create order using OrderService
    final orderService = OrderService(supabaseClient: Supabase.instance.client);

    final items = cartState.items.map((item) => {
      'product_id': item.product.id,
      'quantity': item.quantity,
      'price': item.product.price,
      'product_name': item.product.name,
    }).toList();

    final order = await orderService.createOrder(
      userId: user.id,
      items: items,
      subtotal: subtotal,
      tax: 0.0, // No tax for now
      shipping: deliveryFee,
      total: total,
      deliveryAddressId: selectedAddress.id,
      paymentMethod: _selectedPaymentMethod == 'cod' ? 'Cash on Delivery' : 'UPI Payment',
      notes: null,
      couponCode: null,
    );

    return order.id;
  }

  /// Handle COD order completion with validation
  Future<void> _handleCODOrderCompletion(BuildContext context, String orderId) async {
    // Store context reference for safe usage
    final router = GoRouter.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // Validate order was created successfully
      final orderService = OrderService(supabaseClient: Supabase.instance.client);
      await orderService.getOrderById(orderId);

      // Order should exist since we just created it
      debugPrint('COD Order validation: Order $orderId retrieved successfully');

      // For COD, update order status to processing (confirmed and ready for preparation)
      await orderService.updateOrderStatus(orderId, 'processing');

      // Order data is not needed since GoRouter will handle navigation
      // The order confirmation screen will fetch order details using the orderId

      if (!mounted) return;

      // Navigate directly to order summary screen using GoRouter
      router.push('/clean/order-summary/$orderId');

      // Clear cart after successful COD order
      ref.read(cartNotifierProvider.notifier).clearCart();

    } catch (e) {
      if (!mounted) return;

      // Show error message for COD validation failure
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Failed to confirm COD order: ${e.toString()}'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () => _handleCODOrderCompletion(context, orderId),
          ),
        ),
      );
    }
  }

  /// Navigate to payment processing screen for UPI payments
  Future<void> _navigateToPaymentProcessing(BuildContext context, String orderId) async {
    // Store context references for safe usage
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      // Get cart data for payment processing
      final cartState = ref.read(cartNotifierProvider);
      final user = ref.read(currentUserProvider);
      final userProfile = ref.read(userProfileProvider);
      final supabaseClient = ref.read(supabaseClientProvider);

      if (user == null) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Authentication required for payment'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Get auth token from Supabase session
      final session = supabaseClient.auth.currentSession;
      final authToken = session?.accessToken;

      if (authToken == null) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Authentication token not available. Please login again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Calculate total for payment
      final subtotal = cartState.items.fold<double>(
        0.0,
        (sum, item) => sum + (item.product.price * item.quantity),
      );
      final deliveryFee = subtotal >= 999 ? 0.0 : 25.0;
      final total = subtotal + deliveryFee;

      // Create mock Razorpay order for payment processing
      // Since order is already created in Supabase, we just need payment details
      final razorpayOrder = RazorpayOrderResponse(
        orderId: 'rzp_test_mock_${DateTime.now().millisecondsSinceEpoch}',
        currency: 'INR',
        amount: (total * 100).toInt(), // Convert to paisa
        key: 'rzp_test_mock_payment_gateway',
        internalOrderId: orderId,
        upiIntentUrl: null, // Will use Razorpay checkout
        timeoutAt: DateTime.now().add(const Duration(minutes: 15)),
      );

      // Create order data for payment processing
      final orderData = {
        'items': cartState.items.map((item) => {
          'productId': item.product.id,
          'quantity': item.quantity,
          'price': item.product.price,
          'name': item.product.name,
        }).toList(),
        'total': total,
        'subtotal': subtotal,
        'deliveryFee': deliveryFee,
      };

      // Navigate to payment processing screen (check mounted before using context)
      if (!mounted) return;

      navigator.push(
        MaterialPageRoute(
          builder: (context) => PaymentProcessingScreen(
            orderId: orderId, // Use the orderId from Supabase order creation
            razorpayOrder: razorpayOrder,
            orderData: orderData,
          ),
        ),
      );

      // Clear cart after successful order creation
      ref.read(cartNotifierProvider.notifier).clearCart();

    } catch (e) {
      if (!mounted) return;

      // Classify error type for appropriate user message
      final errorMessage = _getUserFriendlyErrorMessage(e);

      // Show user-friendly error message
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () => _navigateToPaymentProcessing(context, orderId),
          ),
        ),
      );
    }
  }

  /// Get user-friendly error message based on error type
  String _getUserFriendlyErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Network connectivity errors
    if (errorString.contains('socketexception') ||
        errorString.contains('failed host lookup') ||
        errorString.contains('network is unreachable') ||
        errorString.contains('no address associated with hostname')) {
      return 'No internet connection. Please check your network and try again.';
    }

    // Timeout errors
    if (errorString.contains('timeout') ||
        errorString.contains('timed out')) {
      return 'Request timed out. Please check your connection and try again.';
    }

    // Authentication errors
    if (errorString.contains('authentication') ||
        errorString.contains('unauthorized') ||
        errorString.contains('token')) {
      return 'Authentication failed. Please login again.';
    }

    // Server errors
    if (errorString.contains('server') ||
        errorString.contains('internal error') ||
        errorString.contains('500')) {
      return 'Server temporarily unavailable. Please try again later.';
    }

    // Supabase specific errors
    if (errorString.contains('supabase') ||
        errorString.contains('postgrest')) {
      return 'Service temporarily unavailable. Please try again.';
    }

    // Payment specific errors
    if (errorString.contains('payment') ||
        errorString.contains('razorpay')) {
      return 'Payment service unavailable. Please try again or use Cash on Delivery.';
    }

    // Generic fallback
    return 'Something went wrong. Please try again.';
  }

  /// Wrapper method for retry functionality
  void _createOrderAndNavigate(BuildContext context) {
    _handleProceed(context);
  }


}
