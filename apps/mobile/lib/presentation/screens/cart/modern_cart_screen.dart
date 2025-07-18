import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/coupon.dart';
import '../../../core/services/delivery_calculation_service.dart';
import '../../../core/utils/address_formatter.dart';
import '../../../theme/app_theme.dart';
import '../../providers/cart_providers.dart';
import '../../providers/auth_providers.dart';
import '../../providers/user_profile_providers.dart';
import '../../providers/coupon_providers.dart';
import '../../widgets/animations/animated_empty_state.dart';

import '../../widgets/common/common_bottom_nav_bar.dart';
import '../../widgets/common/navigation_handler.dart';
import '../../widgets/common/unified_app_bar.dart';
import '../../widgets/common/inline_error_widget.dart';
import '../../widgets/common/skeleton_loaders.dart';
import '../../widgets/common/skeleton_loading.dart';
import '../../../domain/entities/address.dart';
import '../../../domain/entities/cart_item.dart';
import '../../../domain/entities/product.dart';
import '../profile/location_picker_screen_v2.dart';

/// Modern Cart Screen - UI-only implementation matching the provided screenshot design
/// This screen follows the clean architecture pattern and Dayliz design system
///
/// Features:
/// - Delivery time display
/// - Product cards with quantity controls
/// - Coupon section with applied discounts
/// - Detailed price breakdown
/// - Address selection
/// - Modern, clean UI design
class ModernCartScreen extends ConsumerStatefulWidget {
  const ModernCartScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ModernCartScreen> createState() => _ModernCartScreenState();
}

class _ModernCartScreenState extends ConsumerState<ModernCartScreen> {
  final TextEditingController _couponController = TextEditingController();

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }
  bool _addressesLoadInitiated = false;
  bool _cartLoadInitiated = false;

  // Track which items are being updated to show individual loading states
  final Set<String> _updatingItems = {};

  @override
  void initState() {
    super.initState();
    // Reset the flags when screen is created
    _addressesLoadInitiated = false;
    _cartLoadInitiated = false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daylizTheme = theme.extension<DaylizThemeExtension>();

    // Watch cart state and user data
    final cartState = ref.watch(cartNotifierProvider);
    final currentUser = ref.watch(currentUserProvider);
    final userProfileState = ref.watch(userProfileNotifierProvider);

    // Load cart data if not already loaded - only once per screen instance
    // Don't reload if we already have items (to preserve optimistic updates)
    if (cartState.items.isEmpty && !cartState.isLoading && !_cartLoadInitiated && cartState.itemCount == 0) {
      _cartLoadInitiated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        debugPrint('🛒 Initial cart load triggered (empty cart)');
        ref.read(cartNotifierProvider.notifier).getCartItems();
      });
    }

    // Load user addresses - only once per screen instance
    if (currentUser != null && !userProfileState.isAddressesLoading && !_addressesLoadInitiated) {
      _addressesLoadInitiated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(userProfileNotifierProvider.notifier).loadAddresses(currentUser.id);
      });
    }

    return Scaffold(
      backgroundColor: Colors.grey[100], // Use light grey background
      appBar: UnifiedAppBars.withBackButton(
        title: AppStrings.cart,
        onBackPressed: () => _handleBackNavigation(context),
        fallbackRoute: '/home',
      ),
      body: _buildBody(context, theme, daylizTheme, cartState, userProfileState),
      bottomNavigationBar: cartState.items.isNotEmpty && !cartState.isLoading && cartState.errorMessage == null
          ? _buildBottomSection(context, theme, daylizTheme, cartState)
          : null, // Don't show bottom section when cart is empty, loading, or has error
    );
  }



  /// Builds the main body content
  Widget _buildBody(BuildContext context, ThemeData theme, DaylizThemeExtension? daylizTheme, CartState cartState, UserProfileState userProfileState) {
    // Debug logging for cart state
    debugPrint('🛒 Cart State - Loading: ${cartState.isLoading}, Items: ${cartState.items.length}, Error: ${cartState.errorMessage}');

    // Show loading state if cart is loading
    if (cartState.isLoading) {
      debugPrint('🛒 Showing loading state');
      return _buildCartSkeleton();
    }

    // Show error state if there's an error
    if (cartState.errorMessage != null) {
      return NetworkErrorWidgets.connectionProblem(
        onRetry: () => ref.read(cartNotifierProvider.notifier).getCartItems(),
      );
    }

    // Show empty cart state with Lottie animation
    if (cartState.items.isEmpty) {
      return DaylizEmptyStates.emptyCart(
        onStartShopping: () {
          // Navigate to main home screen when cart is empty
          context.goToMainHomeWithProvider(ref);
        },
        customTitle: 'Your cart is empty',
        customSubtitle: 'Add some delicious products to get started',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDeliveryTimeSection(theme, daylizTheme, cartState),
          const SizedBox(height: 2),
          _buildCartItems(theme, daylizTheme, cartState),
          const SizedBox(height: 35),
          _buildCouponSection(theme, daylizTheme),
          const SizedBox(height: 35),
          _buildPriceBreakdown(theme, daylizTheme, cartState),
          const SizedBox(height: 35),
          _buildCancellationPolicy(theme, daylizTheme),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Builds the delivery time section with weather adaptation
  Widget _buildDeliveryTimeSection(ThemeData theme, DaylizThemeExtension? daylizTheme, CartState cartState) {
    final itemCount = cartState.totalQuantity;

    return FutureBuilder<bool>(
      future: DeliveryCalculationService.getCurrentWeatherStatus(),
      builder: (context, weatherSnapshot) {
        final isBadWeather = weatherSnapshot.data ?? false;
        final deliveryTime = DeliveryCalculationService.calculateDeliveryTime(
          isBadWeather: isBadWeather,
        );

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
              bottomLeft: Radius.circular(0),
              bottomRight: Radius.circular(0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.access_time,
                  color: AppColors.success,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deliveryTime.estimateText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Shipment of $itemCount item${itemCount != 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Builds the cart items section
  Widget _buildCartItems(ThemeData theme, DaylizThemeExtension? daylizTheme, CartState cartState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(0),
          topRight: Radius.circular(0),
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
        children: cartState.items.asMap().entries.map((entry) {
          final index = entry.key;
          final cartItem = entry.value;

          return Column(
            children: [
              if (index > 0) const SizedBox(height: 16),
              _buildCartItem(
                cartItem: cartItem,
                theme: theme,
                daylizTheme: daylizTheme,
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  /// Builds individual cart item
  Widget _buildCartItem({
    required CartItem cartItem,
    required ThemeData theme,
    required DaylizThemeExtension? daylizTheme,
  }) {
    final product = cartItem.product;

    // Get prices - retail price and original price
    final currentPrice = product.discountedPrice; // This is the retail sale price
    final hasDiscount = product.discountPercentage != null && product.discountPercentage! > 0;
    final originalPrice = product.originalPrice; // Calculated original price before discount

    // Get product image URL
    final imageUrl = product.mainImageUrl;

    // Format weight display from attributes
    final weightDisplay = _getWeightDisplay(product);

    // Format prices
    final originalPriceText = '₹${originalPrice.toStringAsFixed(0)}';
    final discountedPriceText = '₹${currentPrice.toStringAsFixed(0)}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product Image
        Container(
          width: 60,
          height: 60,
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
                  child: const Icon(Icons.image, color: Colors.grey),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Product Details and Controls
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Name and Quantity/Price Controls Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name (takes remaining space)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          weightDisplay,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Quantity Controls and Price Column
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Quantity Controls (compact size)
                      _buildQuantityControls(cartItem, theme),
                      const SizedBox(height: 4),

                      // Price Section (directly below add button)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (hasDiscount) ...[
                            Text(
                              originalPriceText,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            discountedPriceText,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds quantity control buttons with individual loading states
  Widget _buildQuantityControls(CartItem cartItem, ThemeData theme) {
    final isUpdating = _updatingItems.contains(cartItem.id);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.success),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildQuantityButton(
            icon: Icons.remove,
            onTap: isUpdating ? null : () => _decreaseQuantity(cartItem),
            isLoading: isUpdating,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            child: isUpdating
                ? const SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.success),
                    ),
                  )
                : Text(
                    cartItem.quantity.toString(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
          ),
          _buildQuantityButton(
            icon: Icons.add,
            onTap: isUpdating ? null : () => _increaseQuantity(cartItem),
            isLoading: isUpdating,
          ),
        ],
      ),
    );
  }

  /// Builds individual quantity button with loading support
  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback? onTap,
    bool isLoading = false,
  }) {
    final isAdd = icon == Icons.add;
    final isDisabled = onTap == null || isLoading;

    return Semantics(
      label: isAdd ? 'Increase quantity' : 'Decrease quantity',
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : onTap,
          borderRadius: BorderRadius.circular(4),
          splashColor: AppColors.success.withValues(alpha: 0.2),
          highlightColor: AppColors.success.withValues(alpha: 0.1),
          child: Container(
            width: 26, // Fixed width for consistency
            height: 26, // Fixed height for consistency
            alignment: Alignment.center,
            child: isLoading
                ? const SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.success),
                    ),
                  )
                : Icon(
                    icon,
                    size: 13,
                    color: isDisabled
                        ? AppColors.success.withValues(alpha: 0.5)
                        : AppColors.success,
                  ),
          ),
        ),
      ),
    );
  }

  /// Builds the modern coupon section
  Widget _buildCouponSection(ThemeData theme, DaylizThemeExtension? daylizTheme) {
    return Container(
      padding: const EdgeInsets.all(12), // Reduced from 16
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Coupon Input Section
          _buildModernCouponInputSection(),

          const SizedBox(height: 10), // Further reduced

          // See All Coupons Button - Smaller
          Center(
            child: TextButton(
              onPressed: () => context.push('/coupons'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), // Reduced padding
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'See all coupons',
                    style: TextStyle(
                      fontSize: 12, // Reduced from 14
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 3), // Reduced spacing
                  Container(
                    padding: const EdgeInsets.all(1.5), // Smaller padding
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 8, // Smaller icon
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds modern coupon input section matching the screenshot design
  Widget _buildModernCouponInputSection() {
    final cartState = ref.watch(cartNotifierProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Apply Coupon',
          style: TextStyle(
            fontSize: 16, // Reduced from 18 to match other section titles
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10), // Reduced from 12

        // Show applied coupon or input field
        if (cartState.appliedCoupon != null) ...[
          _buildAppliedCouponDisplay(cartState.appliedCoupon!),
        ] else ...[
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 44, // Fixed height to reduce size
                  decoration: BoxDecoration(
                    color: Colors.grey[100], // Light grey background
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: TextField(
                    controller: _couponController,
                    decoration: const InputDecoration(
                      hintText: 'Enter Coupon Code',
                      hintStyle: TextStyle(
                        color: Colors.grey,
                        fontSize: 13, // Smaller text to fit without ellipsis
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    style: const TextStyle(
                      fontSize: 13, // Smaller text size
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                ),
              ),
              const SizedBox(width: 10), // Reduced from 12
              SizedBox(
                height: 44, // Match input field height
                child: ElevatedButton(
                  onPressed: () => _applyCoupon(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0), // Reduced horizontal padding
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Apply',
                    style: TextStyle(
                      fontSize: 14, // Reduced from 16
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],

        // Show error message if any
        if (cartState.couponErrorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            cartState.couponErrorMessage!,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  /// Builds the price breakdown section with weather-adaptive delivery fees
  Widget _buildPriceBreakdown(ThemeData theme, DaylizThemeExtension? daylizTheme, CartState cartState) {
    // Calculate totals from cart data
    final itemTotal = cartState.items.fold<double>(0, (sum, item) => sum + (item.quantity * item.product.discountedPrice));
    final taxesAndCharges = itemTotal * 0.02; // 2% taxes

    return FutureBuilder<bool>(
      future: DeliveryCalculationService.getCurrentWeatherStatus(),
      builder: (context, weatherSnapshot) {
        final isBadWeather = weatherSnapshot.data ?? false;
        final deliveryFeeResult = DeliveryCalculationService.calculateDeliveryFee(
          cartTotal: itemTotal,
          isBadWeather: isBadWeather,
        );

        // Calculate coupon discount
        final appliedCoupon = cartState.appliedCoupon;
        double couponDiscount = 0.0;
        double finalDeliveryFee = deliveryFeeResult.fee;

        if (appliedCoupon != null) {
          couponDiscount = appliedCoupon.discountAmount;
          // Apply free delivery if coupon provides it
          if (appliedCoupon.givesFreeDelivery) {
            finalDeliveryFee = 0.0;
          }
        }

        final grandTotal = itemTotal + finalDeliveryFee + taxesAndCharges - couponDiscount;
        final roundedGrandTotal = grandTotal.round().toDouble(); // Round to whole number

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
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
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildPriceRow('Sub total', '₹${itemTotal.toStringAsFixed(0)}'),
              const SizedBox(height: 8),
              _buildPriceRow('Taxes and Charges', '₹${taxesAndCharges.toStringAsFixed(1)}'),
              const SizedBox(height: 8),
              _buildDeliveryFeeRow(deliveryFeeResult),

              // Show coupon discount if applied
              if (appliedCoupon != null) ...[
                const SizedBox(height: 8),
                _buildPriceRow(
                  'Coupon Discount (${appliedCoupon.coupon.code})',
                  '-₹${couponDiscount.toStringAsFixed(1)}',
                  textColor: Colors.green[600],
                ),
              ],

              const SizedBox(height: 16),
              _buildDottedDivider(),
              const SizedBox(height: 16),
              _buildPriceRow(
                'Grand Total',
                '₹${roundedGrandTotal.toStringAsFixed(0)}',
                isTotal: true,
              ),

              // Show weather surcharge message if bad weather fee is applied
              if (deliveryFeeResult.weatherImpact) ...[
                const SizedBox(height: 8),
                Text(
                  '* Weather surcharge of ₹${deliveryFeeResult.fee.toStringAsFixed(0)} applied due to adverse weather conditions',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[700],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// Builds individual price row
  Widget _buildPriceRow(String label, String amount, {bool isTotal = false, Color? textColor}) {
    final color = textColor ?? AppColors.textPrimary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.w400,
            color: color,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
            color: color,
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

  /// Builds dotted divider for invoice feel
  Widget _buildDottedDivider() {
    return CustomPaint(
      size: const Size(double.infinity, 1),
      painter: DottedLinePainter(),
    );
  }

  /// Apply coupon logic
  Future<void> _applyCoupon() async {
    final couponCode = _couponController.text.trim();
    if (couponCode.isEmpty) {
      return;
    }

    final success = await ref.read(cartNotifierProvider.notifier).applyCoupon(couponCode);
    if (success) {
      _couponController.clear();
      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Coupon "$couponCode" applied successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Build applied coupon display
  Widget _buildAppliedCouponDisplay(AppliedCoupon appliedCoupon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green[600],
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appliedCoupon.coupon.code,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.green[700],
                  ),
                ),
                Text(
                  appliedCoupon.coupon.getDiscountDescription(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[600],
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(cartNotifierProvider.notifier).removeCoupon();
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Remove',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }



  /// Builds the cancellation policy section
  Widget _buildCancellationPolicy(ThemeData theme, DaylizThemeExtension? daylizTheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cancellation Policy',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Orders cannot be cancelled once packed for delivery.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the bottom section with address and place order button
  Widget _buildBottomSection(BuildContext context, ThemeData theme, DaylizThemeExtension? daylizTheme, CartState cartState) {
    // Calculate totals from cart data
    final itemTotal = cartState.items.fold<double>(0, (sum, item) => sum + (item.quantity * item.product.discountedPrice));
    final taxesAndCharges = itemTotal * 0.02;

    // Get default address from user profile
    final userProfileState = ref.watch(userProfileNotifierProvider);
    final addresses = userProfileState.addresses ?? [];

    final defaultAddress = addresses.isNotEmpty
        ? addresses.firstWhere(
            (address) => address.isDefault,
            orElse: () => addresses.first,
          )
        : null;

    return FutureBuilder<bool>(
      future: DeliveryCalculationService.getCurrentWeatherStatus(),
      builder: (context, weatherSnapshot) {
        final isBadWeather = weatherSnapshot.data ?? false;
        final deliveryFeeResult = DeliveryCalculationService.calculateDeliveryFee(
          cartTotal: itemTotal,
          isBadWeather: isBadWeather,
        );

        // Calculate coupon discount for bottom section
        final appliedCoupon = cartState.appliedCoupon;
        double couponDiscount = 0.0;
        double finalDeliveryFee = deliveryFeeResult.fee;

        if (appliedCoupon != null) {
          couponDiscount = appliedCoupon.discountAmount;
          // Apply free delivery if coupon provides it
          if (appliedCoupon.givesFreeDelivery) {
            finalDeliveryFee = 0.0;
          }
        }

        final grandTotal = itemTotal + finalDeliveryFee + taxesAndCharges - couponDiscount;
        final roundedGrandTotal = grandTotal.round().toDouble(); // Round to whole number

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Address Section
          if (defaultAddress != null) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    defaultAddress.addressType == 'home' ? Icons.home : Icons.work,
                    color: AppColors.success,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delivering to ${defaultAddress.addressType?.toUpperCase() ?? 'ADDRESS'}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        AddressFormatter.formatAddress(defaultAddress, includeCountry: false),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 24),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  ),
                  onPressed: () => _handleAddressSelection(context),
                  child: const Text(
                    'Change',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            // No address available - show add address button
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: AppColors.info,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delivery Address Required',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Add now for faster checkout next time',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 24),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  ),
                  onPressed: () => _handleAddressSelection(context),
                  child: const Text(
                    'ADD',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),

          // Thin divider
          Container(
            height: 1,
            color: Colors.grey[200],
          ),
          const SizedBox(height: 8), // Reduced from 16 to 8

          // To Pay and Proceed Button Section
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // To Pay Section (Left Side)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'To Pay',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${roundedGrandTotal.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Proceed to Pay Button (Right Side - Longer Width)
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 32), // Increased padding for longer button
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      // Navigate to payment selection after proceed
                      _handlePlaceOrder(context);
                    },
                    child: const Center(
                      child: Text(
                        'Proceed to pay',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
      },
    );
  }

  /// Handles place order action - navigates to payment selection
  void _handlePlaceOrder(BuildContext context) {
    // Check if user has saved addresses
    final userProfileState = ref.read(userProfileNotifierProvider);
    final addresses = userProfileState.addresses ?? [];

    if (addresses.isEmpty) {
      // Show message and navigate to add address
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a delivery address first'),
          backgroundColor: AppColors.warning,
        ),
      );
      _navigateToAddAddress(context);
      return;
    }

    // Navigate to payment selection screen
    // This implements the new flow: Cart -> Place Order -> Payment Selection -> Pay and Order
    context.push('/payment-selection');
  }

  /// Increase quantity of cart item with individual loading state
  Future<void> _increaseQuantity(CartItem cartItem) async {
    // Add to updating items set
    setState(() {
      _updatingItems.add(cartItem.id);
    });

    final success = await ref.read(cartNotifierProvider.notifier).updateQuantity(
      cartItemId: cartItem.id,
      quantity: cartItem.quantity + 1,
    );

    // Remove from updating items set
    if (mounted) {
      setState(() {
        _updatingItems.remove(cartItem.id);
      });

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update quantity'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Decrease quantity of cart item with individual loading state
  Future<void> _decreaseQuantity(CartItem cartItem) async {
    // Add to updating items set
    setState(() {
      _updatingItems.add(cartItem.id);
    });

    if (cartItem.quantity <= 1) {
      // Remove item from cart if quantity would be 0
      final success = await ref.read(cartNotifierProvider.notifier).removeFromCart(
        cartItemId: cartItem.id,
      );

      if (mounted) {
        setState(() {
          _updatingItems.remove(cartItem.id);
        });

        if (!success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to remove item'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } else {
      // Decrease quantity
      final success = await ref.read(cartNotifierProvider.notifier).updateQuantity(
        cartItemId: cartItem.id,
        quantity: cartItem.quantity - 1,
      );

      if (mounted) {
        setState(() {
          _updatingItems.remove(cartItem.id);
        });

        if (!success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update quantity'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  /// Handles address selection with hybrid approach
  void _handleAddressSelection(BuildContext context) {
    // Use watch instead of read to get the latest state
    final userProfileState = ref.watch(userProfileNotifierProvider);
    final addresses = userProfileState.addresses ?? [];

    // Address selection logic

    if (addresses.isEmpty) {
      // Navigate to add new address
      _navigateToAddAddress(context);
    } else if (addresses.length <= 10) {
      // Show scrollable bottom sheet for addresses (increased threshold since it's now scrollable)
      _showInlineAddressSelection(context, addresses);
    } else {
      // Navigate to full address selection page for many addresses (10+ addresses)
      _navigateToAddressSelection(context);
    }
  }



  /// Shows inline address selection bottom sheet with improved UX
  void _showInlineAddressSelection(BuildContext context, List<Address> addresses) {
    final defaultAddress = addresses.firstWhere(
      (address) => address.isDefault,
      orElse: () => addresses.first,
    );

    String? selectedAddressId = defaultAddress.id;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) => DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) => Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  const Text(
                    'Select Delivery Address',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Scrollable address list
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: addresses.length + 1, // +1 for add button
                      itemBuilder: (context, index) {
                        if (index < addresses.length) {
                          // Address item
                          return _buildAddressOptionWithFeedback(
                            context,
                            addresses[index],
                            selectedAddressId,
                            (String addressId) {
                              setState(() {
                                selectedAddressId = addressId;
                              });
                            },
                          );
                        } else {
                          // Add new address button at the end
                          return Column(
                            children: [
                              const SizedBox(height: 8),
                              _buildAddNewAddressButton(context),
                              const SizedBox(height: 16),
                            ],
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Builds individual address option with improved feedback
  Widget _buildAddressOptionWithFeedback(
    BuildContext context,
    Address address,
    String? selectedAddressId,
    Function(String) onAddressSelected,
  ) {
    final isSelected = selectedAddressId == address.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () async {
          // First, update the visual selection immediately
          onAddressSelected(address.id);

          // Capture context-dependent objects before async gap
          final navigator = Navigator.of(context);
          final messenger = ScaffoldMessenger.of(context);

          // Show immediate visual feedback with a slight delay
          await Future.delayed(const Duration(milliseconds: 300));

          // Then close the bottom sheet (check if still mounted)
          if (mounted) {
            navigator.pop();
          }

          // Set as default address with production-safe optimistic update
          final currentUser = ref.read(currentUserProvider);
          if (currentUser != null) {
            // Store original state for potential rollback
            final originalState = ref.read(userProfileNotifierProvider);
            final originalAddresses = originalState.addresses != null
                ? List<Address>.from(originalState.addresses!)
                : <Address>[];

            // Optimistic update: immediately update the UI state
            ref.read(userProfileNotifierProvider.notifier).optimisticallySetDefaultAddress(address.id);

            // Show success message immediately (optimistic feedback)
            if (mounted) {
              messenger.showSnackBar(
                SnackBar(
                  content: Text('✓ Selected: ${address.addressType?.toUpperCase() ?? 'Address'}'),
                  duration: const Duration(seconds: 2),
                  backgroundColor: AppColors.success,
                ),
              );
            }

            // Perform the actual database update in the background
            ref.read(userProfileNotifierProvider.notifier).setDefaultAddress(
              currentUser.id,
              address.id,
            ).catchError((error) {
              // Production-safe error handling with rollback
              debugPrint('❌ Address update failed: $error');

              // Rollback optimistic update to original state
              if (originalAddresses.isNotEmpty) {
                ref.read(userProfileNotifierProvider.notifier).rollbackOptimisticAddressUpdate(originalAddresses);
              }

              // Show user-friendly error message
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content: const Text('Failed to update address. Please check your connection and try again.'),
                    duration: const Duration(seconds: 4),
                    backgroundColor: AppColors.error,
                    action: SnackBarAction(
                      label: 'Retry',
                      textColor: Colors.white,
                      onPressed: () {
                        // Retry the operation
                        ref.read(userProfileNotifierProvider.notifier).setDefaultAddress(
                          currentUser.id,
                          address.id,
                        );
                      },
                    ),
                  ),
                );
              }
            });
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? AppColors.success : AppColors.textSecondary.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: isSelected ? AppColors.success.withValues(alpha: 0.1) : Colors.transparent,
          ),
          child: Row(
            children: [
              // Address icon with animation
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isSelected
                    ? AppColors.success.withValues(alpha: 0.2)
                    : AppColors.textSecondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  address.addressType == 'home' ? Icons.home : Icons.work,
                  color: isSelected ? AppColors.success : AppColors.textSecondary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),

              // Address details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      address.addressType?.toUpperCase() ?? 'ADDRESS',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? AppColors.success : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AddressFormatter.formatAddress(address, includeCountry: false),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Selection indicator with animation
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: isSelected
                  ? const Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 20,
                      key: ValueKey('selected'),
                    )
                  : const SizedBox(
                      width: 20,
                      height: 20,
                      key: ValueKey('unselected'),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds add new address button
  Widget _buildAddNewAddressButton(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        _navigateToAddAddress(context);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.success,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.add,
              color: AppColors.success,
              size: 20,
            ),
            SizedBox(width: 12),
            Text(
              'Add New Address',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.success,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Navigate to add new address
  void _navigateToAddAddress(BuildContext context) {
    // Navigate to location picker screen to add new address
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LocationPickerScreen(),
      ),
    ).then((_) {
      // Refresh addresses when returning from address screen
      final currentUser = ref.read(currentUserProvider);
      if (currentUser != null) {
        // Reset the addresses load flag to allow refresh
        setState(() {
          _addressesLoadInitiated = false;
        });
        // Force reload addresses
        ref.read(userProfileNotifierProvider.notifier).loadAddresses(currentUser.id);
        // Force a rebuild to update the UI
        if (mounted) {
          setState(() {});
        }
      }
    });
  }

  /// Navigate to full address selection page
  void _navigateToAddressSelection(BuildContext context) {
    // Show a helpful message about full address selection
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Address Selection'),
          content: const Text(
            'Full address selection page will be implemented in the next development phase.\n\n'
            'For now, you can use the quick address selection or proceed with the order.',
          ),
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

  /// Handle back navigation from cart screen
  void _handleBackNavigation(BuildContext context) {
    debugPrint('🔙 Handling back navigation from cart');

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



  /// Get weight/unit display text from product attributes
  String _getWeightDisplay(Product product) {
    if (product.attributes == null) return '';

    // Try different possible keys for weight/unit information
    final weight = product.attributes!['weight']?.toString();
    final unit = product.attributes!['unit']?.toString();
    final quantity = product.attributes!['quantity']?.toString();
    final volume = product.attributes!['volume']?.toString();

    if (weight != null && weight.isNotEmpty) return weight;
    if (unit != null && unit.isNotEmpty) return unit;
    if (quantity != null && quantity.isNotEmpty) return quantity;
    if (volume != null && volume.isNotEmpty) return volume;

    return '';
  }

  /// Build skeleton loading for cart screen
  Widget _buildCartSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Delivery time skeleton
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                SkeletonContainer(
                  width: 24,
                  height: 24,
                  borderRadius: BorderRadius.circular(12),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonContainer(
                        width: 150,
                        height: 16,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 8),
                      SkeletonContainer(
                        width: 200,
                        height: 14,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Cart items skeleton
          const ListSkeleton(
            itemSkeleton: CartItemSkeleton(),
            itemCount: 3,
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

/// Custom painter for dotted line divider
class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashWidth = 4.0;
    const dashSpace = 3.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
