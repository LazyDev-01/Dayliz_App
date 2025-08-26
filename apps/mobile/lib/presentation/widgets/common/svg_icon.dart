import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A comprehensive SVG icon system for the Dayliz App
/// This widget provides a consistent way to use SVG icons throughout the app
class SvgIcon extends StatelessWidget {
  final DaylizIcons icon;
  final double? size;
  final Color? color;
  final String? semanticLabel;
  final BoxFit fit;

  const SvgIcon(
    this.icon, {
    Key? key,
    this.size,
    this.color,
    this.semanticLabel,
    this.fit = BoxFit.contain,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      icon.path,
      width: size ?? 24,
      height: size ?? 24,
      colorFilter: color != null 
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null,
      semanticsLabel: semanticLabel ?? icon.semanticLabel,
      fit: fit,
    );
  }
}

/// Enum containing all available SVG icons in the app
enum DaylizIcons {
  // Navigation Icons
  cart('assets/icons/svg_icons/cart.svg', 'Shopping Cart'),
  profile('assets/icons/svg_icons/profile.svg', 'Profile'),
  menu('assets/icons/svg_icons/menu.svg', 'Menu'),
  search('assets/icons/svg_icons/search.svg', 'Search'),

  // Home Icons (Basil Design)
  homeOutline('assets/icons/svg_icons/Basil/Outline/Home.svg', 'Home'),
  homeFilled('assets/icons/svg_icons/Basil/solid/Home_filled.svg', 'Home Active'),

  // Categories Icons (Basil Design)
  categoriesOutline('assets/icons/svg_icons/Basil/Outline/Categories.svg', 'Categories'),
  categoriesFilled('assets/icons/svg_icons/Basil/solid/Categories_filled.svg', 'Categories Active'),
  
  // Arrow Icons
  arrowBackward('assets/icons/svg_icons/arrow_backward.svg', 'Back'),
  arrowForward('assets/icons/svg_icons/arrow_forward.svg', 'Forward'),
  right('assets/icons/svg_icons/right.svg', 'Right Arrow'),
  
  // Action Icons
  add('assets/icons/svg_icons/add.svg', 'Add'),
  addRounded('assets/icons/svg_icons/add_rounded.svg', 'Add'),
  addQuantity('assets/icons/svg_icons/add_quantity.svg', 'Add Quantity'),
  removeQuantity('assets/icons/svg_icons/remove_quantity.svg', 'Remove Quantity'),
  delete('assets/icons/svg_icons/delete.svg', 'Delete'),
  deleteOutline('assets/icons/svg_icons/delete_outline.svg', 'Delete'),
  edit('assets/icons/svg_icons/edit.svg', 'Edit'),
  save('assets/icons/svg_icons/save.svg', 'Save'),
  eye('assets/icons/svg_icons/eye.svg', 'View'),
  filter('assets/icons/svg_icons/filter.svg', 'Filter'),
  
  // Heart/Wishlist Icons
  heart('assets/icons/svg_icons/heart.svg', 'Heart'),
  heartActive('assets/icons/svg_icons/heart_active.svg', 'Favorite'),
  heartOutlined('assets/icons/svg_icons/heart_outlined.svg', 'Add to Favorites'),
  
  // Shopping Icons
  shoppingBag('assets/icons/svg_icons/shopping_bag.svg', 'Shopping Bag'),
  shoppingCart('assets/icons/svg_icons/shopping_cart.svg', 'Shopping Cart'),
  voucher('assets/icons/svg_icons/voucher.svg', 'Voucher'),
  
  // Location Icons
  location('assets/icons/svg_icons/location.svg', 'Location'),
  truckIcon('assets/icons/svg_icons/truck_icon.svg', 'Delivery'),
  
  // Profile Related Icons
  homeProfile('assets/icons/svg_icons/home_profile.svg', 'Home Profile'),
  profilePerson('assets/icons/svg_icons/profile_person.svg', 'Person'),
  profileLogout('assets/icons/svg_icons/profile_logout.svg', 'Logout'),
  profileNotification('assets/icons/svg_icons/profile_notification.svg', 'Notifications'),
  profilePayment('assets/icons/svg_icons/profile_payment.svg', 'Payment'),
  profileSetting('assets/icons/svg_icons/profile_setting.svg', 'Settings'),
  
  // Order Status Icons
  orderConfirm('assets/icons/svg_icons/order_confirm.svg', 'Order Confirmed'),
  orderProcessing('assets/icons/svg_icons/order_processing.svg', 'Order Processing'),
  orderShipped('assets/icons/svg_icons/order_shipped.svg', 'Order Shipped'),
  orderDelivered('assets/icons/svg_icons/order_delivered.svg', 'Order Delivered'),
  
  // Payment Icons
  cardAdd('assets/icons/svg_icons/card_add.svg', 'Add Card'),
  masterCard('assets/icons/svg_icons/master_card.svg', 'Master Card'),
  paypal('assets/icons/svg_icons/paypal.svg', 'PayPal'),
  cashOnDelivery('assets/icons/svg_icons/cash_on_delivery.svg', 'Cash on Delivery'),
  
  // Social Icons
  googleIcon('assets/icons/svg_icons/google_icon.svg', 'Google'),
  googleIconRounded('assets/icons/svg_icons/google_icon_rounded.svg', 'Google'),
  appleIcon('assets/icons/svg_icons/apple_icon.svg', 'Apple'),
  appleIconRounded('assets/icons/svg_icons/apple_icon_rounded.svg', 'Apple'),
  facebookIcon('assets/icons/svg_icons/facebook_icon.svg', 'Facebook'),
  twitterIcon('assets/icons/svg_icons/twitter_icon.svg', 'Twitter'),
  
  // Contact Icons
  contactEmail('assets/icons/svg_icons/contact_email.svg', 'Email'),
  contactPhone('assets/icons/svg_icons/contact_phone.svg', 'Phone'),
  contactMap('assets/icons/svg_icons/contact_map.svg', 'Map'),
  
  // Utility Icons
  dashboardIcon('assets/icons/svg_icons/dashboard_icon.svg', 'Dashboard'),
  sideBarIcon('assets/icons/svg_icons/side_bar_icon.svg', 'Sidebar'),
  searchTileArrow('assets/icons/svg_icons/search_tile_arrow.svg', 'Search Arrow'),
  reply('assets/icons/svg_icons/reply.svg', 'Reply');

  const DaylizIcons(this.path, this.semanticLabel);

  final String path;
  final String semanticLabel;
}

/// Extension methods for easier icon usage
extension DaylizIconsExtension on DaylizIcons {
  /// Create an SvgIcon widget with this icon
  Widget icon({
    double? size,
    Color? color,
    String? semanticLabel,
    BoxFit fit = BoxFit.contain,
  }) {
    return SvgIcon(
      this,
      size: size,
      color: color,
      semanticLabel: semanticLabel,
      fit: fit,
    );
  }

  /// Create a small icon (16px)
  Widget small({Color? color, String? semanticLabel}) {
    return icon(size: 16, color: color, semanticLabel: semanticLabel);
  }

  /// Create a medium icon (24px) - default size
  Widget medium({Color? color, String? semanticLabel}) {
    return icon(size: 24, color: color, semanticLabel: semanticLabel);
  }

  /// Create a large icon (32px)
  Widget large({Color? color, String? semanticLabel}) {
    return icon(size: 32, color: color, semanticLabel: semanticLabel);
  }

  /// Create an extra large icon (48px)
  Widget extraLarge({Color? color, String? semanticLabel}) {
    return icon(size: 48, color: color, semanticLabel: semanticLabel);
  }
}

/// Helper class for commonly used icon combinations
class DaylizIconHelpers {
  /// Navigation back button with proper theming
  static Widget backButton(BuildContext context, {VoidCallback? onPressed}) {
    return IconButton(
      onPressed: onPressed ?? () => Navigator.of(context).pop(),
      icon: DaylizIcons.arrowBackward.icon(
        color: const Color(0xFF374151), // Explicit dark grey color
      ),
      tooltip: 'Back',
    );
  }

  /// Cart icon with badge support
  static Widget cartWithBadge(
    BuildContext context, {
    int? badgeCount,
    VoidCallback? onPressed,
  }) {
    return Stack(
      children: [
        IconButton(
          onPressed: onPressed,
          icon: DaylizIcons.cart.icon(
            color: const Color(0xFF374151), // Explicit dark grey color
          ),
          tooltip: 'Shopping Cart',
        ),
        if (badgeCount != null && badgeCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                badgeCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  /// Wishlist heart icon with active state
  static Widget wishlistHeart({
    required bool isActive,
    required VoidCallback onPressed,
    double? size,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: (isActive ? DaylizIcons.heartActive : DaylizIcons.heartOutlined)
          .icon(size: size),
      tooltip: isActive ? 'Remove from Wishlist' : 'Add to Wishlist',
    );
  }

  /// Quantity selector with + and - buttons
  static Widget quantitySelector({
    required int quantity,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
    int minQuantity = 0,
    int maxQuantity = 99,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: quantity > minQuantity ? onDecrement : null,
          icon: DaylizIcons.removeQuantity.small(),
          tooltip: 'Decrease quantity',
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            quantity.toString(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        IconButton(
          onPressed: quantity < maxQuantity ? onIncrement : null,
          icon: DaylizIcons.addQuantity.small(),
          tooltip: 'Increase quantity',
        ),
      ],
    );
  }
}
