import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/order_service.dart';
import '../../../domain/entities/order.dart' as domain;

/// Order Summary Screen - Shows detailed order information
/// Displays order items, billing details, delivery info, and tracking
class OrderSummaryScreen extends ConsumerStatefulWidget {
  final String orderId;
  final Map<String, dynamic>? orderData;

  const OrderSummaryScreen({
    super.key,
    required this.orderId,
    this.orderData,
  });

  @override
  ConsumerState<OrderSummaryScreen> createState() => _OrderSummaryScreenState();
}

class _OrderSummaryScreenState extends ConsumerState<OrderSummaryScreen> {
  late Map<String, dynamic> orderData;
  final DateFormat dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');
  bool isLoading = true;
  String? errorMessage;
  domain.Order? realOrder;

  @override
  void initState() {
    super.initState();
    // Use provided order data initially, then fetch real data
    orderData = widget.orderData ?? _createSampleOrderData();
    _fetchOrderData();
  }

  Future<void> _fetchOrderData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final orderService = OrderService(supabaseClient: Supabase.instance.client);
      final order = await orderService.getOrderById(widget.orderId);

      setState(() {
        realOrder = order;
        orderData = _convertOrderToMap(order);
        isLoading = false;
      });

      debugPrint('OrderSummaryScreen: Order data fetched successfully');

    } catch (e) {
      debugPrint('OrderSummaryScreen: Error fetching order: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load order details. Please try again.';
      });
    }
  }

  Map<String, dynamic> _convertOrderToMap(domain.Order order) {
    return {
      'orderId': order.id,
      'status': order.status,
      'items': order.items.map((item) => {
        'productName': item.productName,
        'quantity': item.quantity,
        'price': item.unitPrice,
        'total': item.totalPrice,
        'image': item.imageUrl ?? 'https://via.placeholder.com/50',
      }).toList(),
      'subtotal': order.subtotal,
      'tax': order.tax,
      'shipping': order.shipping,
      'total': order.total,
      'paymentMethod': order.paymentMethod.type,
      'shippingAddress': {
        'addressLine1': order.shippingAddress.addressLine1,
        'addressLine2': order.shippingAddress.addressLine2,
        'city': order.shippingAddress.city,
        'state': order.shippingAddress.state,
        'postalCode': order.shippingAddress.postalCode,
        'country': order.shippingAddress.country,
      },
      'estimatedDelivery': DateTime.now().add(const Duration(hours: 2)),
      'createdAt': order.createdAt,
    };
  }

  Map<String, dynamic> _createSampleOrderData() {
    return {
      'orderId': widget.orderId,
      'status': 'confirmed',
      'items': [
        {
          'productName': 'Fresh Bananas',
          'quantity': 2,
          'price': 3.99,
          'total': 7.98,
          'image': 'assets/images/banana.png',
        },
        {
          'productName': 'Organic Apples',
          'quantity': 1,
          'price': 5.99,
          'total': 5.99,
          'image': 'assets/images/apple.png',
        },
      ],
      'subtotal': 13.97,
      'tax': 2.51,
      'shipping': 0.0,
      'total': 16.48,
      'paymentMethod': 'cod',
      'shippingAddress': {
        'addressLine1': '123 Main Street',
        'city': 'New York',
        'state': 'NY',
        'postalCode': '10001',
      },
      'estimatedDelivery': DateTime.now().add(const Duration(hours: 2)),
      'createdAt': DateTime.now(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(context, theme),
      body: isLoading
          ? _buildLoadingState()
          : errorMessage != null
              ? _buildErrorState(theme)
              : _buildBody(context, theme),
      bottomNavigationBar: isLoading || errorMessage != null
          ? null
          : _buildBottomButton(context, theme),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Loading order details...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Order',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'Something went wrong',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchOrderData,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
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
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        'Order Summary',
        style: TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.share, color: Colors.black),
          onPressed: () => _shareOrder(),
        ),
      ],
    );
  }

  void _shareOrder() {
    // TODO: Implement share functionality
    debugPrint('Share order: ${orderData['orderId']}');
  }

  
  /// Builds the main body content
  Widget _buildBody(BuildContext context, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOrderStatusSection(theme),
          const SizedBox(height: 16),
          _buildOrderInvoiceSection(theme),
          const SizedBox(height: 16),
          _buildItemsSection(theme),
          const SizedBox(height: 16),
          _buildBillDetailsSection(theme),
          const SizedBox(height: 100), // Space for bottom button
        ],
      ),
    );
  }

  /// Builds the order status section
  Widget _buildOrderStatusSection(ThemeData theme) {
    final status = orderData['status'] ?? 'pending';
    final orderId = orderData['orderId'] ?? 'N/A';

    // Note: estimatedDelivery parsing removed as we no longer display the date/time

    final items = orderData['items'] as List? ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.check_circle, color: Colors.green, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getStatusText(status),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      'Your order has been confirmed',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.access_time, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Our delivery agent will reach to you shortly',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order ID: #$orderId',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${items.length} ${items.length == 1 ? 'item' : 'items'}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'Order Confirmed';
      case 'processing':
        return 'Order Processing';
      case 'shipped':
        return 'Order Shipped';
      case 'delivered':
        return 'Order Delivered';
      case 'cancelled':
        return 'Order Cancelled';
      default:
        return 'Order Placed';
    }
  }

  /// Builds the order invoice section
  Widget _buildOrderInvoiceSection(ThemeData theme) {
    final orderId = orderData['orderId'] ?? 'N/A';
    final paymentMethod = orderData['paymentMethod'] ?? 'cod';
    final shippingAddress = orderData['shippingAddress'] as Map<String, dynamic>? ?? {};
    final createdAt = orderData['createdAt'] as DateTime? ?? DateTime.now();

    // Format payment method
    String getPaymentMethodText(String method) {
      switch (method.toLowerCase()) {
        case 'cod':
          return 'Cash on Delivery';
        case 'card':
          return 'Credit/Debit Card';
        case 'upi':
          return 'UPI Payment';
        case 'wallet':
          return 'Digital Wallet';
        default:
          return 'Cash on Delivery';
      }
    }

    // Format delivery address
    String getDeliveryAddress() {
      if (shippingAddress.isEmpty) return 'Address not available';
      
      final addressLine1 = shippingAddress['addressLine1'] ?? '';
      final city = shippingAddress['city'] ?? '';
      final state = shippingAddress['state'] ?? '';
      final postalCode = shippingAddress['postalCode'] ?? '';
      
      return '$addressLine1, $city, $state $postalCode'.trim();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          const Text(
            'Order Invoice',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildInvoiceRow('Order ID', '#$orderId'),
          const SizedBox(height: 12),
          _buildInvoiceRow('Mode of Payment', getPaymentMethodText(paymentMethod)),
          const SizedBox(height: 12),
          _buildInvoiceRow('Delivery Address', getDeliveryAddress(), isAddress: true),
          const SizedBox(height: 12),
          _buildInvoiceRow('Order Placed On', dateFormat.format(createdAt)),
        ],
      ),
    );
  }

  /// Builds individual invoice row
  Widget _buildInvoiceRow(String label, String value, {bool isAddress = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
            height: isAddress ? 1.4 : 1.0,
          ),
          maxLines: isAddress ? 3 : 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// Builds the items section
  Widget _buildItemsSection(ThemeData theme) {
    final items = orderData['items'] as List? ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          const Text(
            'Order Items',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Column(
              children: [
                _buildOrderItem(
                  imageUrl: item['image'] ?? 'https://via.placeholder.com/50',
                  title: item['productName'] ?? 'Product',
                  weight: 'Qty: ${item['quantity'] ?? 1}',
                  originalPrice: '₹${(item['price'] ?? 0.0).toStringAsFixed(2)}',
                  discountedPrice: '₹${(item['total'] ?? 0.0).toStringAsFixed(2)}',
                ),
                if (index < items.length - 1) const SizedBox(height: 16),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  /// Builds individual order item
  Widget _buildOrderItem({
    required String imageUrl,
    required String title,
    required String weight,
    required String originalPrice,
    required String discountedPrice,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product Image
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[100],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.image, color: Colors.grey, size: 20),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Product Details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                weight,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),

        // Price Section
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (originalPrice != discountedPrice) ...[
              Text(
                originalPrice,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(height: 2),
            ],
            Text(
              discountedPrice,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds the bill details section
  Widget _buildBillDetailsSection(ThemeData theme) {
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
          const Text(
            'Bill details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          _buildBillRow('Subtotal', '₹${(orderData['subtotal'] ?? 0.0).toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          _buildBillRow('Tax', '₹${(orderData['tax'] ?? 0.0).toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          _buildBillRow('Delivery Fee', orderData['shipping'] == 0.0 ? 'FREE' : '₹${(orderData['shipping'] ?? 0.0).toStringAsFixed(2)}'),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          _buildBillRow(
            'Total',
            '₹${(orderData['total'] ?? 0.0).toStringAsFixed(2)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  /// Builds individual bill row
  Widget _buildBillRow(String label, String amount, {bool isTotal = false, bool isPositive = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.w400,
            color: Colors.black,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
            color: isPositive ? Colors.green : Colors.black,
          ),
        ),
      ],
    );
  }

  
  /// Builds the bottom track order button
  Widget _buildBottomButton(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: () {
            // TODO: Implement track order functionality
            _showTrackOrderDialog(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Track your order',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  /// Shows track order dialog (placeholder)
  void _showTrackOrderDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Track Order'),
          content: const Text('This is a UI-only implementation. Order tracking functionality will be added later.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
