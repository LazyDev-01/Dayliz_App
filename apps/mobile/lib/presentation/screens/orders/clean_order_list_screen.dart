import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/order.dart' as domain;
import '../../providers/order_providers.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/common_app_bar.dart';

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

  @override
  Widget build(BuildContext context) {
    final ordersAsyncValue = ref.watch(userOrdersProvider);

    return Scaffold(
      appBar: CommonAppBars.withBackButton(
        title: 'My Orders',
        fallbackRoute: '/home',
        backButtonTooltip: 'Back to Home',
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey[800],
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
                return const Center(
                  child: LoadingIndicator(message: 'Loading orders...'),
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
          loading: () => const Center(
            child: LoadingIndicator(message: 'Loading orders...'),
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
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => context.push('/orders/${order.id}'),
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
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildStatusChip(context, order.status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${order.items.length} ${order.items.length == 1 ? 'item' : 'items'}'),
                  Text(
                    currencyFormat.format(order.total),
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Placed on ${_formatDate(order.createdAt)}',
                style: theme.textTheme.bodySmall,
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
      case domain.Order.statusPending:
        chipColor = Colors.blue;
        break;
      case domain.Order.statusProcessing:
        chipColor = Colors.orange;
        break;
      case domain.Order.statusShipped:
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

    return Chip(
      label: Text(
        _formatStatus(status),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
      backgroundColor: chipColor,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  String _formatStatus(String status) {
    if (status.isEmpty) return '';
    return status[0].toUpperCase() + status.substring(1);
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }
}