import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/order_service.dart';
import '../../../core/utils/address_formatter.dart';
import '../../../domain/entities/address.dart';
import '../../../domain/entities/order.dart' as domain;
import '../../widgets/common/unified_app_bar.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/delivery_calculation_service.dart';

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
      'orderNumber': order.orderNumber, // Add order number for display
      'status': order.status,
      'items': order.items.map((item) => {
        'productName': item.productName,
        'quantity': item.quantity,
        'unitPrice': item.unitPrice, // Original price (MRP)
        'totalPrice': item.totalPrice, // Total for this item
        'image': item.imageUrl ?? 'https://via.placeholder.com/50',
        'weight': item.options?['weight'] ?? '', // Get weight from options
        'productId': item.productId, // Include product ID for potential lookups
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

  /// Builds the app bar with unified design
  PreferredSizeWidget _buildAppBar(BuildContext context, ThemeData theme) {
    return UnifiedAppBars.withBackButton(
      title: 'Order Summary',
      fallbackRoute: '/orders',
      // Removed share icon as requested
    );
  }

  // Share functionality removed as requested

  /// Builds a dotted line for section separation
  Widget _buildDottedLine() {
    return Container(
      height: 1,
      child: Row(
        children: List.generate(
          50, // Number of dashes
          (index) => Expanded(
            child: Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              color: Colors.grey[400],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds quantity with weight display
  String _buildQuantityWithWeight(int quantity, String weight) {
    if (weight.isNotEmpty) {
      return 'Qty: $quantity x $weight';
    } else {
      return 'Qty: $quantity';
    }
  }

  /// Builds a price row to match cart screen format
  Widget _buildPriceRow(String label, String amount, {bool isTotal = false, Color? textColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.w400,
            color: textColor ?? AppColors.textPrimary,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
            color: textColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  /// Builds delivery fee row with weather impact message and discount display
  Widget _buildDeliveryFeeRow(DeliveryFeeResult deliveryFeeResult) {
    // Show crossed-out ₹25 when delivery fee is lower (₹20, ₹15, or FREE)
    final bool showDeliveryDiscount = !deliveryFeeResult.weatherImpact &&
                                     (deliveryFeeResult.fee < 25.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Delivery Fee',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.textPrimary,
              ),
            ),
            // Show delivery fee with discount styling
            if (showDeliveryDiscount)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Crossed-out original price (₹25)
                  const Text(
                    '₹25',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Discounted price
                  Text(
                    deliveryFeeResult.displayText,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: deliveryFeeResult.isFree ? Colors.green[600] : AppColors.textPrimary,
                    ),
                  ),
                ],
              )
            else
              // Normal delivery fee display (for ₹25 or weather surcharge)
              Text(
                deliveryFeeResult.displayText,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: deliveryFeeResult.weatherImpact ? Colors.orange[700] : AppColors.textPrimary,
                ),
              ),
          ],
        ),
        // Show weather impact message only for bad weather
        if (deliveryFeeResult.weatherImpact && deliveryFeeResult.weatherMessage != null) ...[
          const SizedBox(height: 4),
          Text(
            deliveryFeeResult.weatherMessage!,
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange[700],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        // Show delivery discount message for lower fees
        if (showDeliveryDiscount && !deliveryFeeResult.isFree) ...[
          const SizedBox(height: 4),
          Text(
            'You saved ₹${(25.0 - deliveryFeeResult.fee).toStringAsFixed(0)} on delivery!',
            style: TextStyle(
              fontSize: 12,
              color: Colors.green[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  /// Builds a dotted divider to match cart screen format
  Widget _buildDottedDivider() {
    return Row(
      children: List.generate(
        50, // Number of dashes
        (index) => Expanded(
          child: Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            color: Colors.grey[400],
          ),
        ),
      ),
    );
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
          _buildItemsSection(theme),
          const SizedBox(height: 16),
          _buildBillDetailsSection(theme),
          const SizedBox(height: 16),
          _buildOrderInvoiceSection(theme), // Moved to last as requested
          const SizedBox(height: 24), // Bottom spacing
        ],
      ),
    );
  }

  /// Builds the order status section
  Widget _buildOrderStatusSection(ThemeData theme) {
    final status = orderData['status'] ?? 'pending';

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
    final orderNumber = orderData['orderNumber'] ?? orderId; // Use order number if available, fallback to ID
    final paymentMethod = orderData['paymentMethod'] ?? 'cod';
    final shippingAddress = orderData['shippingAddress'] as Map<String, dynamic>? ?? {};
    final createdAt = realOrder?.createdAt ?? DateTime.now(); // Use realOrder createdAt for proper timezone

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

    // Format delivery address using standardized formatter
    String getDeliveryAddress() {
      if (shippingAddress.isEmpty) return 'Address not available';

      // Create a temporary Address object for formatting
      final tempAddress = Address(
        id: '',
        userId: '',
        addressLine1: shippingAddress['addressLine1'] ?? '',
        addressLine2: shippingAddress['addressLine2'] ?? '',
        city: shippingAddress['city'] ?? '',
        state: shippingAddress['state'] ?? '',
        postalCode: shippingAddress['postalCode'] ?? '',
        country: shippingAddress['country'] ?? 'India',
      );

      // Use full address format instead of compact format
      return AddressFormatter.formatAddress(tempAddress, includeCountry: true);
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order Invoice',
                style: TextStyle(
                  fontSize: 16, // Updated to 16px as requested
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700], // Dark grey as requested
                ),
              ),
              const SizedBox(height: 8),
              _buildDottedLine(), // Added dotted line
            ],
          ),
          const SizedBox(height: 16),
          _buildInvoiceRow('Order ID', orderNumber.startsWith('DLZ-') ? orderNumber : '#$orderNumber'),
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
            fontSize: 14, // 14px as requested
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14, // 14px as requested
            fontWeight: FontWeight.w500,
            color: Colors.black87,
            height: isAddress ? 1.4 : 1.0,
          ),
          maxLines: isAddress ? null : 1, // Allow unlimited lines for address
          overflow: isAddress ? TextOverflow.visible : TextOverflow.ellipsis,
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order Details',
                style: TextStyle(
                  fontSize: 16, // 16px as requested
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700], // Dark grey as requested
                ),
              ),
              const SizedBox(height: 8),
              _buildDottedLine(), // Added dotted line
            ],
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
                  weight: _buildQuantityWithWeight(item['quantity'] ?? 1, item['weight'] ?? ''),
                  originalPrice: '₹${(item['unitPrice'] ?? 0.0).toStringAsFixed(0)}', // Price per unit (discounted)
                  discountedPrice: '₹${(item['totalPrice'] ?? 0.0).toStringAsFixed(0)}', // Total for this item
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
            // Show unit price
            Text(
              originalPrice, // This is the unit price
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 2),
            // Show total price for this item
            Text(
              discountedPrice, // This is the total price
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

  /// Builds the bill details section to match cart screen format with weather-adaptive delivery fees
  Widget _buildBillDetailsSection(ThemeData theme) {
    // Calculate values to match cart screen format
    final subtotal = orderData['subtotal'] ?? 0.0;
    final tax = orderData['tax'] ?? 0.0;

    return FutureBuilder<bool>(
      future: DeliveryCalculationService.getCurrentWeatherStatus(),
      builder: (context, weatherSnapshot) {
        final isBadWeather = weatherSnapshot.data ?? false;

        // Calculate delivery fee using the same logic as cart screen
        final deliveryFeeResult = DeliveryCalculationService.calculateDeliveryFee(
          cartTotal: subtotal, // Use subtotal for delivery fee calculation
          isBadWeather: isBadWeather,
        );

        // Use calculated delivery fee or original if it was stored differently
        final deliveryFee = deliveryFeeResult.fee;

        // Recalculate total with proper delivery fee
        final recalculatedTotal = subtotal + tax + deliveryFee;
        final roundedTotal = recalculatedTotal.round().toDouble();

        return Container(
          padding: const EdgeInsets.all(16), // Match cart screen padding
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
              // Bill Details Title
              const Text(
                'Bill Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary, // Match cart screen color
                ),
              ),
              const SizedBox(height: 16),
              _buildPriceRow('Sub total', '₹${subtotal.toStringAsFixed(0)}'), // Match cart format
              const SizedBox(height: 8),
              _buildPriceRow('Taxes and Charges', '₹${tax.toStringAsFixed(1)}'), // Match cart format
              const SizedBox(height: 8),
              _buildDeliveryFeeRow(deliveryFeeResult), // Use weather-adaptive delivery fee
              const SizedBox(height: 16),
              _buildDottedDivider(), // Match cart screen divider
              const SizedBox(height: 16),
              _buildPriceRow(
                'Grand Total', // Changed from 'Total' to 'Grand Total'
                '₹${roundedTotal.toStringAsFixed(0)}', // Round to whole number
                isTotal: true,
              ),
            ],
          ),
        );
      },
    );
  }

}
