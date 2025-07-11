import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/order.dart' as domain;
import '../../providers/order_providers.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/unified_app_bar.dart';
import '../order/order_summary_screen.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/skeleton_loaders.dart';

class CleanOrderListScreen extends ConsumerStatefulWidget {
  const CleanOrderListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CleanOrderListScreen> createState() => _CleanOrderListScreenState();
}

class _CleanOrderListScreenState extends ConsumerState<CleanOrderListScreen> {
  @override
  void initState() {
    super.initState();
    // Schedule the fetch for after the build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchOrders(ref);
    });
  }

  /// Handle back navigation from order list screen
  void _handleBackNavigation(BuildContext context) {
    debugPrint('🔙 Handling back navigation from order list');

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
    final ordersAsyncValue = ref.watch(userOrdersProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50], // Light grey background
      appBar: UnifiedAppBars.withBackButton(
        title: 'My Orders',
        onBackPressed: () => _handleBackNavigation(context),
        fallbackRoute: '/home',
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          fetchOrders(ref);
        },
        child: ordersAsyncValue.when(
          data: (orders) {
            if (orders.isEmpty) {
              // If we have a state with no orders, check if we're still loading
              final isLoading = ref.watch(ordersLoadingProvider);
              if (isLoading) {
                return const ListSkeleton(
                  itemSkeleton: OrderSkeleton(),
                  itemCount: 3,
                );
              }

              return const EmptyState(
                icon: Icons.receipt_long,
                title: 'No Orders Yet',
                message: 'Your order history will appear here.',
              );
            }
            return _buildOrderList(context, orders, ref);
          },
          loading: () => const ListSkeleton(
            itemSkeleton: OrderSkeleton(),
            itemCount: 5,
          ),
          error: (error, stackTrace) => ErrorState(
            error: error.toString(),
            onRetry: () {
              fetchOrders(ref);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildOrderList(BuildContext context, List<domain.Order> orders, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _OrderCard(order: order);
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  final domain.Order order;

  const _OrderCard({
    Key? key,
    required this.order,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: '₹', locale: 'en_IN');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0, // Remove shadow effect
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: InkWell(
        onTap: () => _navigateToOrderSummary(context, order),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order ID and Status in separate rows for better visibility
              Text(
                'Order #${order.orderNumber ?? order.id}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatusChip(context, order.status),
                  Text(
                    currencyFormat.format(order.total),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${order.items.length} ${order.items.length == 1 ? 'item' : 'items'}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    'Placed on ${_formatDate(order.createdAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, String status) {
    Color chipColor;

    switch (status) {
      case domain.Order.statusProcessing:
        chipColor = Colors.orange;
        break;
      case domain.Order.statusOutForDelivery:
        chipColor = Colors.purple;
        break;
      case domain.Order.statusDelivered:
        chipColor = Colors.green;
        break;
      case domain.Order.statusCancelled:
        chipColor = Colors.red;
        break;
      default:
        chipColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        _formatStatus(status),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatStatus(String status) {
    if (status.isEmpty) return '';

    // Handle special case for out_for_delivery
    if (status == 'out_for_delivery') {
      return 'Out for Delivery';
    }

    return status[0].toUpperCase() + status.substring(1);
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  void _navigateToOrderSummary(BuildContext context, domain.Order order) {
    // Navigate to order summary screen with the order ID
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OrderSummaryScreen(orderId: order.id),
      ),
    );
  }
}