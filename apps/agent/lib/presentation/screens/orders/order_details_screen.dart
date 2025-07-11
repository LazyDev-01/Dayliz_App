import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_components/ui_components.dart';
import '../../../core/providers/orders_provider.dart';
import '../../../core/models/agent_order_model.dart';

/// Order Details Screen
/// Shows detailed information about a specific order with action buttons
class OrderDetailsScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderDetailsScreen({
    super.key,
    required this.orderId,
  });

  @override
  ConsumerState<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends ConsumerState<OrderDetailsScreen> {
  AgentOrderModel? orderData;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadOrderData();
  }

  Future<void> _loadOrderData() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final order = await ref.read(agentOrdersProvider.notifier).fetchOrderById(widget.orderId);

      if (mounted) {
        setState(() {
          orderData = order;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = 'Failed to load order details';
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: const Text('Order Details'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (error != null || orderData == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: const Text('Order Details'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                error ?? 'Order not found',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadOrderData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final order = orderData!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          'Order ${widget.orderId}',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: _callCustomer,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            _buildStatusCard(order.status),

            const SizedBox(height: 20),

            // Customer Information
            _buildCustomerInfoCard(),

            const SizedBox(height: 20),

            // Delivery Address
            _buildDeliveryAddressCard(),

            const SizedBox(height: 20),

            // Order Items
            _buildOrderItemsCard(),

            const SizedBox(height: 20),

            // Order Summary
            _buildOrderSummaryCard(),

            if (order.notes != null && order.notes!.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildNotesCard(),
            ],

            const SizedBox(height: 100), // Space for floating action button
          ],
        ),
      ),
      floatingActionButton: _buildActionButton(order.status),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildStatusCard(String status) {
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    switch (status) {
      case 'assigned':
        statusColor = const Color(0xFF1976D2);
        statusText = 'New Order - Please Accept';
        statusIcon = Icons.new_releases;
        break;
      case 'accepted':
        statusColor = const Color(0xFFF57C00);
        statusText = 'Order Accepted - Ready for Pickup';
        statusIcon = Icons.check;
        break;
      case 'picked_up':
        statusColor = const Color(0xFF7B1FA2);
        statusText = 'Order Picked Up - In Transit';
        statusIcon = Icons.shopping_bag;
        break;
      case 'in_transit':
        statusColor = const Color(0xFF1976D2);
        statusText = 'Out for Delivery';
        statusIcon = Icons.local_shipping;
        break;
      case 'delivered':
        statusColor = const Color(0xFF388E3C);
        statusText = 'Order Delivered Successfully';
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Unknown Status';
        statusIcon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            statusIcon,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Created at ${_formatDateTime(orderData!.createdAt)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfoCard() {
    return _buildInfoCard(
      title: 'Customer Information',
      icon: Icons.person,
      child: Column(
        children: [
          _buildInfoRow(
            Icons.person,
            'Name',
            orderData!.customer.name,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.phone,
            'Phone',
            orderData!.customer.phone,
            onTap: _callCustomer,
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryAddressCard() {
    final address = orderData!.deliveryAddress;

    return _buildInfoCard(
      title: 'Delivery Address',
      icon: Icons.location_on,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            address.fullAddress,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          if (address.landmark != null && address.landmark!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.place, size: 16, color: Colors.black54),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Landmark: ${address.landmark}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          DaylizButton(
            text: 'Open in Maps',
            onPressed: _openInMaps,
            backgroundColor: const Color(0xFF1976D2),
            textColor: Colors.white,
            icon: Icons.map,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItemsCard() {
    final items = orderData!.orderItems;

    return _buildInfoCard(
      title: 'Order Items (${items.length} items)',
      icon: Icons.shopping_cart,
      child: Column(
        children: items.map((item) => _buildOrderItem(item)).toList(),
      ),
    );
  }

  Widget _buildOrderItem(OrderItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF2E7D32),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Quantity: ${item.quantity}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₹${item.totalPrice.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard() {
    final totalAmount = orderData!.totalAmount;
    final deliveryFee = orderData!.deliveryFee;
    final grandTotal = totalAmount + deliveryFee;
    
    return _buildInfoCard(
      title: 'Order Summary',
      icon: Icons.receipt,
      child: Column(
        children: [
          _buildSummaryRow('Subtotal', '₹${totalAmount.toStringAsFixed(0)}'),
          const SizedBox(height: 8),
          _buildSummaryRow('Delivery Fee', '₹${deliveryFee.toStringAsFixed(0)}'),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          _buildSummaryRow(
            'Total Amount',
            '₹${grandTotal.toStringAsFixed(0)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    return _buildInfoCard(
      title: 'Special Instructions',
      icon: Icons.note,
      child: Text(
        orderData!.notes ?? '',
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFF2E7D32),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.black54),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: onTap != null ? const Color(0xFF1976D2) : Colors.black87,
                decoration: onTap != null ? TextDecoration.underline : null,
              ),
            ),
          ),
          if (onTap != null)
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: FontWeight.bold,
            color: isTotal ? const Color(0xFF2E7D32) : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String status) {
    String buttonText;
    String nextStatus;
    Color buttonColor;
    
    switch (status) {
      case 'assigned':
        buttonText = 'Accept Order';
        nextStatus = 'accepted';
        buttonColor = const Color(0xFF2E7D32);
        break;
      case 'accepted':
        buttonText = 'Mark as Picked Up';
        nextStatus = 'picked_up';
        buttonColor = const Color(0xFFF57C00);
        break;
      case 'picked_up':
        buttonText = 'Start Delivery';
        nextStatus = 'in_transit';
        buttonColor = const Color(0xFF1976D2);
        break;
      case 'in_transit':
        buttonText = 'Mark as Delivered';
        nextStatus = 'delivered';
        buttonColor = const Color(0xFF388E3C);
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: DaylizButton(
        text: buttonText,
        onPressed: () => _updateOrderStatus(nextStatus),
        backgroundColor: buttonColor,
        textColor: Colors.white,
      ),
    );
  }

  void _callCustomer() {
    HapticFeedback.lightImpact();
    // TODO: Implement actual phone call
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling ${orderData!.customer.phone} (Demo)'),
        backgroundColor: const Color(0xFF2E7D32),
      ),
    );
  }

  void _openInMaps() {
    HapticFeedback.lightImpact();
    // TODO: Implement actual maps integration
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening in Maps (Demo)'),
        backgroundColor: Color(0xFF1976D2),
      ),
    );
  }

  void _updateOrderStatus(String newStatus) {
    HapticFeedback.lightImpact();
    // TODO: Implement actual status update to Supabase
    if (orderData != null) {
      setState(() {
        orderData = AgentOrderModel(
          id: orderData!.id,
          orderNumber: orderData!.orderNumber,
          status: newStatus,
          totalAmount: orderData!.totalAmount,
          deliveryFee: orderData!.deliveryFee,
          paymentMethod: orderData!.paymentMethod,
          paymentStatus: orderData!.paymentStatus,
          notes: orderData!.notes,
          createdAt: orderData!.createdAt,
          updatedAt: DateTime.now(),
          customer: orderData!.customer,
          deliveryAddress: orderData!.deliveryAddress,
          orderItems: orderData!.orderItems,
        );
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order status updated to $newStatus'),
        backgroundColor: const Color(0xFF2E7D32),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
