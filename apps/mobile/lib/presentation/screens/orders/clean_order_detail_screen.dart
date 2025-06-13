import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:timeline_tile/timeline_tile.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/order.dart' as domain;
import '../../../domain/entities/order_item.dart';
import '../../../domain/entities/payment_method.dart';
import '../../../domain/entities/address.dart';
import '../../providers/order_providers.dart';
import '../../widgets/common/error_message.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/unified_app_bar.dart';

class CleanOrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;

  const CleanOrderDetailScreen({
    Key? key,
    required this.orderId,
  }) : super(key: key);

  @override
  ConsumerState<CleanOrderDetailScreen> createState() => _CleanOrderDetailScreenState();
}

class _CleanOrderDetailScreenState extends ConsumerState<CleanOrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Schedule the fetch for after the build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchOrderDetails(ref, widget.orderId);
    });
  }

  /// Handle back navigation from order detail screen
  void _handleBackNavigation(BuildContext context) {
    debugPrint('🔙 Handling back navigation from order detail');

    // Check if we can pop (there's a previous screen)
    if (Navigator.of(context).canPop()) {
      debugPrint('🔙 Can pop - going to previous screen');
      Navigator.of(context).pop();
    } else {
      debugPrint('🔙 Cannot pop - navigating to categories instead of home');
      // Instead of going to home (which shows bottom nav), go to categories
      // This provides a better UX as categories is the main shopping entry point
      context.go('/clean/categories');
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderAsyncValue = ref.watch(orderDetailProvider(widget.orderId));

    return Scaffold(
      appBar: UnifiedAppBars.withBackButton(
        title: 'Order Details',
        onBackPressed: () => _handleBackNavigation(context),
        fallbackRoute: '/home',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF374151)),
            onPressed: () => fetchOrderDetails(ref, widget.orderId),
            tooltip: 'Refresh order',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          fetchOrderDetails(ref, widget.orderId);
        },
        child: orderAsyncValue.when(
          data: (order) => order != null
              ? _buildOrderDetails(context, order, ref)
              : const Center(child: LoadingIndicator(message: 'Loading order details...')),
          loading: () => const Center(
            child: LoadingIndicator(message: 'Loading order details...'),
          ),
          error: (error, stackTrace) => ErrorState(
            error: error.toString(),
            onRetry: () => fetchOrderDetails(ref, widget.orderId),
          ),
        ),
      ),
    );
  }
  
  Widget _buildOrderDetails(BuildContext context, domain.Order order, WidgetRef ref) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order header with ID and status
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Order #${order.id}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      _buildStatusChip(context, order.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Placed on: ${DateFormat('MMM d, yyyy').format(order.createdAt)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (order.trackingNumber != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Tracking Number: ${order.trackingNumber}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Order items
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Items',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...order.items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: item.imageUrl != null
                            ? Image.network(item.imageUrl!, fit: BoxFit.cover)
                            : const Icon(Icons.image, color: Colors.grey),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text('${item.quantity} x ${currencyFormat.format(item.unitPrice)}'),
                            ],
                          ),
                        ),
                        Text(
                          currencyFormat.format(item.totalPrice),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Order summary (price breakdown)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order Summary',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Subtotal:'),
                      Text(currencyFormat.format(order.subtotal)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Shipping:'),
                      Text(currencyFormat.format(order.shipping)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tax:'),
                      Text(currencyFormat.format(order.tax)),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        currencyFormat.format(order.total),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Shipping address
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Shipping Address',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(order.shippingAddress.addressLine1),
                  if (order.shippingAddress.addressLine2 != null && 
                      order.shippingAddress.addressLine2!.isNotEmpty)
                    Text(order.shippingAddress.addressLine2!),
                  Text('${order.shippingAddress.city}, ${order.shippingAddress.state} ${order.shippingAddress.postalCode}'),
                  Text(order.shippingAddress.country),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Payment information
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment Method',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(order.paymentMethod.type),
                  // Show card info if applicable
                  if (order.paymentMethod.type == PaymentMethod.typeCard) 
                    Text(order.paymentMethod.maskedCardNumber ?? ''),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Show cancel button if order can be cancelled
          if (order.canBeCancelled)
            _buildCancelButton(context, ref),
        ],
      ),
    );
  }
  
  Widget _buildStatusChip(BuildContext context, String status) {
    Color color;
    switch (status) {
      case domain.Order.statusDelivered:
        color = Colors.green;
        break;
      case domain.Order.statusShipped:
        color = Colors.blue;
        break;
      case domain.Order.statusProcessing:
        color = Colors.orange;
        break;
      case domain.Order.statusCancelled:
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        _formatStatus(status),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
  
  Widget _buildCancelButton(BuildContext context, WidgetRef ref) {
    return Consumer(
      builder: (context, ref, child) {
        // Check if we're currently loading
        final isLoading = ref.watch(ordersLoadingProvider);
        
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading 
              ? null 
              : () => _handleCancelOrder(context, ref),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Cancel Order'),
          ),
        );
      },
    );
  }
  
  void _handleCancelOrder(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text(
          'Are you sure you want to cancel this order? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No, Keep Order'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              
              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const AlertDialog(
                  content: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Cancelling order...'),
                    ],
                  ),
                ),
              );
              
              // Call cancel order with the OrdersNotifier
              ref.read(ordersNotifierProvider.notifier).cancelOrder(widget.orderId).then((result) {
                // Close loading dialog
                Navigator.of(context).pop();
                
                // Show result notification
                result.fold(
                  (failure) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to cancel order: ${failure.message}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  },
                  (success) {
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Order cancelled successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      // Navigate back to the orders list
                      Navigator.of(context).pop();
                    }
                  }
                );
              });
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel Order'),
          ),
        ],
      ),
    );
  }

  String _formatStatus(String status) {
    if (status.isEmpty) return '';
    return status[0].toUpperCase() + status.substring(1);
  }
}

class _OrderDetailView extends StatelessWidget {
  final domain.Order order;

  const _OrderDetailView({required this.order});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOrderHeader(context),
          const SizedBox(height: 24),
          _buildStatusTimeline(context),
          const SizedBox(height: 24),
          _buildSection(
            context,
            title: 'Items',
            child: _buildOrderItems(context),
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            title: 'Shipping Address',
            child: _buildAddressCard(context, order.shippingAddress),
          ),
          const SizedBox(height: 16),
          if (order.billingAddress != null) ...[
            _buildSection(
              context,
              title: 'Billing Address',
              child: _buildAddressCard(context, order.billingAddress!),
            ),
            const SizedBox(height: 16),
          ],
          _buildSection(
            context,
            title: 'Payment Information',
            child: _buildPaymentInfo(context),
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            title: 'Order Summary',
            child: _buildOrderSummary(context),
          ),
          const SizedBox(height: 24),
          if (order.canBeCancelled)
            _buildCancelButton(context)
          else if (order.status == domain.Order.statusDelivered)
            _buildReorderButton(context),
        ],
      ),
    );
  }

  Widget _buildOrderHeader(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Order #${order.id}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            _buildStatusChip(context, order.status),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Placed on: ${dateFormat.format(order.createdAt)}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (order.trackingNumber != null) ...[
          const SizedBox(height: 8),
          Text(
            'Tracking Number: ${order.trackingNumber}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ],
    );
  }

  Widget _buildStatusChip(BuildContext context, String status) {
    Color color;
    switch (status) {
      case domain.Order.statusDelivered:
        color = Colors.green;
        break;
      case domain.Order.statusShipped:
        color = Colors.blue;
        break;
      case domain.Order.statusProcessing:
        color = Colors.orange;
        break;
      case domain.Order.statusCancelled:
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        _formatStatus(status),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStatusTimeline(BuildContext context) {
    final statuses = [
      domain.Order.statusPending,
      domain.Order.statusProcessing,
      domain.Order.statusShipped,
      domain.Order.statusDelivered,
    ];

    final currentIndex = statuses.indexOf(order.status);
    final isCompleted = order.status == domain.Order.statusDelivered;
    final isCancelled = order.status == domain.Order.statusCancelled;

    if (isCancelled) {
      return Card(
        color: Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.cancel, color: Colors.red.shade700),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'This order was cancelled',
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Status',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: List.generate(
                statuses.length,
                (index) {
                  final isActive = index <= currentIndex;
                  final isLast = index == statuses.length - 1;

                  return Expanded(
                    child: Row(
                      children: [
                        _StatusDot(
                          isActive: isActive,
                          isCompleted: isCompleted && index == statuses.length - 1,
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              height: 2,
                              color: isActive
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey.shade300,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: statuses
                  .map((status) => Expanded(
                        child: Text(
                          _formatStatus(status),
                          style: TextStyle(
                            color: statuses.indexOf(status) <= currentIndex
                                ? Theme.of(context).primaryColor
                                : Colors.grey,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItems(BuildContext context) {
    return Column(
      children: order.items.map((item) => _OrderItemCard(item: item)).toList(),
    );
  }

  Widget _buildAddressCard(BuildContext context, dynamic address) {
    final name = address.recipientName ?? 'No recipient name';
    final line1 = address.addressLine1;
    final line2 = address.addressLine2 ?? '';
    final city = address.city;
    final state = address.state;
    final postalCode = address.postalCode;
    final country = address.country;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(line1),
            if (line2.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(line2),
            ],
            const SizedBox(height: 2),
            Text('$city, $state $postalCode'),
            Text(country),
            if (address.phoneNumber != null && address.phoneNumber!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Phone: ${address.phoneNumber}'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInfo(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              _getPaymentIcon(order.paymentMethod.type),
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.paymentMethod.type,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (order.paymentMethod.type == PaymentMethod.typeCard && 
                      order.paymentMethod.details.containsKey('last4'))
                    Text('**** ${order.paymentMethod.details['last4']}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSummaryRow(
              context,
              label: 'Subtotal (${order.itemCount} items)',
              value: currencyFormat.format(order.subtotal),
            ),
            const SizedBox(height: 8),
            if (order.discount != null && order.discount! > 0) ...[
              _buildSummaryRow(
                context,
                label: 'Discount',
                value: '- ${currencyFormat.format(order.discount!)}',
                valueColor: Colors.green,
              ),
              const SizedBox(height: 8),
            ],
            _buildSummaryRow(
              context,
              label: 'Shipping',
              value: currencyFormat.format(order.shipping),
            ),
            const SizedBox(height: 8),
            _buildSummaryRow(
              context,
              label: 'Tax',
              value: currencyFormat.format(order.tax),
            ),
            const Divider(height: 24),
            _buildSummaryRow(
              context,
              label: 'Total',
              value: currencyFormat.format(order.total),
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              valueStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context, {
    required String label,
    required String value,
    TextStyle? labelStyle,
    TextStyle? valueStyle,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: labelStyle),
        Text(
          value,
          style: valueStyle?.copyWith(color: valueColor) ??
              TextStyle(color: valueColor),
        ),
      ],
    );
  }

  Widget _buildCancelButton(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        // Check if we're currently loading
        final isLoading = ref.watch(ordersLoadingProvider);
        
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading 
              ? null 
              : () => _handleCancelOrder(context, ref),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Cancel Order'),
          ),
        );
      },
    );
  }

  void _handleCancelOrder(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text(
          'Are you sure you want to cancel this order? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No, Keep Order'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              
              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const AlertDialog(
                  content: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Cancelling order...'),
                    ],
                  ),
                ),
              );
              
              // Call cancel order with the OrdersNotifier
              ref.read(ordersNotifierProvider.notifier).cancelOrder(order.id).then((result) {
                // Close loading dialog
                Navigator.of(context).pop();
                
                // Show result notification
                result.fold(
                  (failure) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to cancel order: ${failure.message}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  },
                  (success) {
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Order cancelled successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      // Navigate back to refresh the list
                      Navigator.of(context).pop();
                    }
                  }
                );
              });
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel Order'),
          ),
        ],
      ),
    );
  }

  Widget _buildReorderButton(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              // Show a confirmation dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Reorder Items'),
                  content: const Text(
                    'Would you like to add all items from this order to your cart?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        
                        // Here you would add all order items to the cart
                        // This is a simplified implementation
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Items have been added to your cart'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        
                        // Navigate to cart
                        Navigator.pushNamed(context, '/clean/cart');
                      },
                      child: const Text('Add to Cart'),
                    ),
                  ],
                ),
              );
            },
            child: const Text('Reorder'),
          ),
        );
      },
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  IconData _getPaymentIcon(String paymentType) {
    switch (paymentType.toLowerCase()) {
      case 'credit card':
        return Icons.credit_card;
      case 'paypal':
        return Icons.paypal;
      case 'cash on delivery':
        return Icons.money;
      default:
        return Icons.payment;
    }
  }

  String _formatStatus(String status) {
    if (status.isEmpty) return '';
    return status[0].toUpperCase() + status.substring(1);
  }
}

class _StatusDot extends StatelessWidget {
  final bool isActive;
  final bool isCompleted;

  const _StatusDot({
    required this.isActive,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: isActive ? Theme.of(context).primaryColor : Colors.grey.shade300,
        shape: BoxShape.circle,
      ),
      child: isCompleted
          ? const Icon(
              Icons.check,
              color: Colors.white,
              size: 16,
            )
          : null,
    );
  }
}

class _OrderItemCard extends StatelessWidget {
  final OrderItem item;

  const _OrderItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image (or placeholder)
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: item.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.image),
                      ),
                    )
                  : const Icon(Icons.image, color: Colors.grey),
            ),
            const SizedBox(width: 12),
            
            // Product details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (item.options != null && 
                      item.options!.containsKey('variantName') && 
                      item.options!['variantName'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.options!['variantName'].toString(),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${currencyFormat.format(item.unitPrice)} × ${item.quantity}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        currencyFormat.format(item.totalPrice),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 