import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'lottie_animation_widget.dart';
import '../../../core/constants/animation_constants.dart';

/// An animated empty state widget that displays Lottie animations
/// for various empty scenarios in the app
class AnimatedEmptyState extends StatelessWidget {
  /// Type of empty state to display
  final EmptyStateType type;
  
  /// Custom title text
  final String? title;
  
  /// Custom subtitle text
  final String? subtitle;
  
  /// Custom action button
  final Widget? actionButton;
  
  /// Custom animation path (overrides the default for the type)
  final String? customAnimationPath;
  
  /// Animation size
  final double? animationSize;
  
  /// Whether to show the default action button
  final bool showDefaultAction;
  
  /// Callback for the default action button
  final VoidCallback? onActionPressed;

  const AnimatedEmptyState({
    Key? key,
    required this.type,
    this.title,
    this.subtitle,
    this.actionButton,
    this.customAnimationPath,
    this.animationSize,
    this.showDefaultAction = true,
    this.onActionPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final config = _getEmptyStateConfig(type);
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Lottie Animation
            LottieAnimationWidget(
              animationPath: customAnimationPath ?? config.animationPath,
              width: animationSize ?? config.defaultSize,
              height: animationSize ?? config.defaultSize,
              repeat: true,
              autoStart: true,
              speed: 0.8,
              fallback: Icon(
                config.fallbackIcon,
                size: animationSize ?? config.defaultSize,
                color: Colors.grey.shade400,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Title
            Text(
              title ?? config.defaultTitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            // Subtitle
            Text(
              subtitle ?? config.defaultSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            // Action Button
            if (showDefaultAction && (actionButton != null || onActionPressed != null))
              actionButton ?? _buildDefaultActionButton(context, config),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultActionButton(BuildContext context, EmptyStateConfig config) {
    return ElevatedButton.icon(
      onPressed: () {
        // Add haptic feedback when button is pressed
        HapticFeedback.lightImpact();
        onActionPressed?.call();
      },
      icon: Icon(config.actionIcon),
      label: Text(config.actionText),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  EmptyStateConfig _getEmptyStateConfig(EmptyStateType type) {
    switch (type) {
      case EmptyStateType.emptyCart:
        return EmptyStateConfig(
          animationPath: AnimationConstants.emptyCart,
          defaultTitle: 'Your cart is empty',
          defaultSubtitle: 'Add some delicious items to get started!',
          actionText: 'Start Shopping',
          actionIcon: Icons.shopping_bag,
          fallbackIcon: Icons.shopping_cart_outlined,
          defaultSize: 234, // Increased by 17% (200 * 1.17 = 234)
        );
        
      case EmptyStateType.noOrders:
        return EmptyStateConfig(
          animationPath: AnimationConstants.noOrders,
          defaultTitle: 'No orders yet',
          defaultSubtitle: 'Your order history will appear here once you place your first order.',
          actionText: 'Browse Products',
          actionIcon: Icons.explore,
          fallbackIcon: Icons.receipt_long_outlined,
          defaultSize: 150,
        );
        
      case EmptyStateType.noSearchResults:
        return EmptyStateConfig(
          animationPath: AnimationConstants.noSearchResults,
          defaultTitle: 'No results found',
          defaultSubtitle: 'Try adjusting your search terms or browse our categories.',
          actionText: 'Browse Categories',
          actionIcon: Icons.category,
          fallbackIcon: Icons.search_off,
          defaultSize: 120,
        );
        
      case EmptyStateType.noInternet:
        return EmptyStateConfig(
          animationPath: AnimationConstants.noInternet,
          defaultTitle: 'No internet connection',
          defaultSubtitle: 'Please check your connection and try again.',
          actionText: 'Retry',
          actionIcon: Icons.refresh,
          fallbackIcon: Icons.wifi_off,
          defaultSize: 120,
        );
        
      case EmptyStateType.emptyWishlist:
        return EmptyStateConfig(
          animationPath: AnimationConstants.emptyWishlist,
          defaultTitle: 'Your wishlist is empty',
          defaultSubtitle: 'Save your favorite items to find them easily later.',
          actionText: 'Discover Products',
          actionIcon: Icons.favorite,
          fallbackIcon: Icons.favorite_border,
          defaultSize: 120,
        );
        
      case EmptyStateType.noNotifications:
        return EmptyStateConfig(
          animationPath: AnimationConstants.searchLoading, // Reuse loading animation
          defaultTitle: 'No notifications',
          defaultSubtitle: 'You\'re all caught up! New notifications will appear here.',
          actionText: 'Go to Home',
          actionIcon: Icons.home,
          fallbackIcon: Icons.notifications_none,
          defaultSize: 100,
        );
    }
  }
}

/// Types of empty states supported by the widget
enum EmptyStateType {
  emptyCart,
  noOrders,
  noSearchResults,
  noInternet,
  emptyWishlist,
  noNotifications,
}

/// Configuration for each empty state type
class EmptyStateConfig {
  final String animationPath;
  final String defaultTitle;
  final String defaultSubtitle;
  final String actionText;
  final IconData actionIcon;
  final IconData fallbackIcon;
  final double defaultSize;

  const EmptyStateConfig({
    required this.animationPath,
    required this.defaultTitle,
    required this.defaultSubtitle,
    required this.actionText,
    required this.actionIcon,
    required this.fallbackIcon,
    required this.defaultSize,
  });
}

/// Quick factory methods for common empty states
class DaylizEmptyStates {
  static Widget emptyCart({
    VoidCallback? onStartShopping,
    String? customTitle,
    String? customSubtitle,
  }) {
    return AnimatedEmptyState(
      type: EmptyStateType.emptyCart,
      title: customTitle,
      subtitle: customSubtitle,
      onActionPressed: onStartShopping,
    );
  }

  static Widget noOrders({
    VoidCallback? onBrowseProducts,
    String? customTitle,
    String? customSubtitle,
  }) {
    return AnimatedEmptyState(
      type: EmptyStateType.noOrders,
      title: customTitle,
      subtitle: customSubtitle,
      onActionPressed: onBrowseProducts,
    );
  }

  static Widget noSearchResults({
    VoidCallback? onBrowseCategories,
    String? searchTerm,
  }) {
    return AnimatedEmptyState(
      type: EmptyStateType.noSearchResults,
      subtitle: searchTerm != null 
        ? 'No results found for "$searchTerm". Try different keywords or browse our categories.'
        : null,
      onActionPressed: onBrowseCategories,
    );
  }

  static Widget noInternet({
    VoidCallback? onRetry,
  }) {
    return AnimatedEmptyState(
      type: EmptyStateType.noInternet,
      onActionPressed: onRetry,
    );
  }

  static Widget emptyWishlist({
    VoidCallback? onDiscoverProducts,
  }) {
    return AnimatedEmptyState(
      type: EmptyStateType.emptyWishlist,
      onActionPressed: onDiscoverProducts,
    );
  }

  static Widget noNotifications({
    VoidCallback? onGoHome,
  }) {
    return AnimatedEmptyState(
      type: EmptyStateType.noNotifications,
      onActionPressed: onGoHome,
    );
  }
}
