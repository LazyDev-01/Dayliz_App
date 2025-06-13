import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:confetti/confetti.dart';
import '../../../domain/entities/payment_method.dart' as domain;
import 'dart:math';

import '../../../domain/entities/order.dart' as domain;
import '../../providers/order_providers.dart';
import '../../widgets/common/unified_app_bar.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_state.dart';

/// A screen that displays order confirmation details after a successful order placement
class CleanOrderConfirmationScreen extends ConsumerStatefulWidget {
  /// The ID of the order that was just placed
  final String orderId;

  const CleanOrderConfirmationScreen({
    Key? key,
    required this.orderId,
  }) : super(key: key);

  @override
  ConsumerState<CleanOrderConfirmationScreen> createState() => _CleanOrderConfirmationScreenState();
}

class _CleanOrderConfirmationScreenState extends ConsumerState<CleanOrderConfirmationScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();

    // Initialize confetti controller
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));

    // Start confetti animation after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _confettiController.play();
      }
    });

    // Fetch order details if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchOrderDetails(ref, widget.orderId);
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderAsyncValue = ref.watch(orderDetailProvider(widget.orderId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: UnifiedAppBars.withBackButton(
        title: 'Order Confirmation',
        fallbackRoute: '/',
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/'),
            tooltip: 'Go to Home',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Confetti overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2, // straight down
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              maxBlastForce: 20,
              minBlastForce: 10,
              gravity: 0.2,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
              ],
            ),
          ),

          // Main content
          orderAsyncValue.when(
            data: (order) => order != null
                ? _buildOrderConfirmation(context, order)
                : _buildBasicConfirmation(context),
            loading: () => const Center(
              child: LoadingIndicator(message: 'Loading order details...'),
            ),
            error: (error, stackTrace) => _buildBasicConfirmation(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicConfirmation(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 80,
            ),
            const SizedBox(height: 24),
            Text(
              'Order Placed Successfully!',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Order ID: ${widget.orderId}',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Thank you for your order! We\'ll send you a confirmation email shortly.',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderConfirmation(BuildContext context, domain.Order order) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMMM d, yyyy');
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 80,
          ),
          const SizedBox(height: 24),
          Text(
            'Order Placed Successfully!',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Order ID: ${order.id}',
            style: theme.textTheme.titleMedium,
          ),
          Text(
            'Placed on: ${dateFormat.format(order.createdAt)}',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),

          // Order summary card
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order Summary',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(height: 24),

                  // Order items summary
                  Text(
                    '${order.items.length} ${order.items.length == 1 ? 'item' : 'items'}',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),

                  // Price breakdown
                  _buildPriceRow('Subtotal:', currencyFormat.format(order.subtotal)),
                  _buildPriceRow('Shipping:', currencyFormat.format(order.shipping)),
                  _buildPriceRow('Tax:', currencyFormat.format(order.tax)),
                  if (order.discount != null && order.discount! > 0)
                    _buildPriceRow('Discount:', '-${currencyFormat.format(order.discount!)}'),
                  const Divider(height: 16),
                  _buildPriceRow(
                    'Total:',
                    currencyFormat.format(order.total),
                    isTotal: true,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Shipping info
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Shipping Information',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(height: 24),

                  // Address details
                  if (order.shippingAddress.recipientName != null)
                    Text('Recipient: ${order.shippingAddress.recipientName}'),
                  const SizedBox(height: 4),
                  Text(order.shippingAddress.addressLine1),
                  if (order.shippingAddress.addressLine2?.isNotEmpty ?? false)
                    Text(order.shippingAddress.addressLine2!),
                  Text(
                    '${order.shippingAddress.city}, ${order.shippingAddress.state} ${order.shippingAddress.postalCode}',
                  ),
                  Text(order.shippingAddress.country),
                  if (order.shippingAddress.phoneNumber != null) ...[
                    const SizedBox(height: 4),
                    Text('Phone: ${order.shippingAddress.phoneNumber}'),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Payment method
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment Method',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(height: 24),

                  // Payment details
                  Row(
                    children: [
                      _getPaymentIcon(order.paymentMethod.type),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _getPaymentMethodName(order.paymentMethod),
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isTotal = false}) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isTotal
                ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
                : theme.textTheme.bodyMedium,
          ),
          Text(
            value,
            style: isTotal
                ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
                : theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () => context.go('/clean/orders'),
          icon: const Icon(Icons.receipt_long),
          label: const Text('View My Orders'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.shopping_bag),
          label: const Text('Continue Shopping'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ],
    );
  }

  Widget _getPaymentIcon(String paymentType) {
    switch (paymentType) {
      case 'card':
        return const Icon(Icons.credit_card);
      case 'paypal':
        return const Icon(Icons.account_balance_wallet);
      case 'cod':
        return const Icon(Icons.money);
      case 'wallet':
        return const Icon(Icons.account_balance_wallet);
      default:
        return const Icon(Icons.payment);
    }
  }

  String _getPaymentMethodName(domain.PaymentMethod method) {
    if (method.type == 'card' && method.maskedCardNumber != null) {
      return '${method.cardBrand ?? 'Card'} ending in ${method.maskedCardNumber!.substring(method.maskedCardNumber!.length - 4)}';
    }

    switch (method.type) {
      case 'card':
        return 'Credit/Debit Card';
      case 'paypal':
        return 'PayPal';
      case 'cod':
        return 'Cash on Delivery';
      case 'wallet':
        return 'Wallet';
      default:
        return method.name;
    }
  }
}
