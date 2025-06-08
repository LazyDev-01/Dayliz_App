import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import 'animated_cloud_background.dart';
import 'back_button_widget.dart';

/// An enhanced app bar with animated cloud background
/// Provides a delightful visual experience while maintaining functionality
class AnimatedAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// The title of the app bar
  final String title;

  /// Whether to show a back button
  final bool showBackButton;

  /// Whether to show a drawer toggle
  final bool showDrawerToggle;

  /// The fallback route to navigate to if there's nothing in the navigation stack
  final String fallbackRoute;

  /// Custom callback to override default back navigation behavior
  final VoidCallback? onBackPressed;

  /// The tooltip text for the back button
  final String? backButtonTooltip;

  /// The actions to display at the end of the app bar
  final List<Widget>? actions;

  /// The bottom widget of the app bar (e.g., TabBar)
  final PreferredSizeWidget? bottom;

  /// Whether to center the title
  final bool centerTitle;

  /// The background color of the app bar
  final Color? backgroundColor;

  /// The foreground color of the app bar (affects text and icon colors)
  final Color? foregroundColor;

  /// The elevation of the app bar
  final double? elevation;

  /// Whether to show a shadow under the app bar
  final bool showShadow;

  /// Custom leading widget to replace the back button
  final Widget? leading;

  /// Whether to enable cloud animation
  final bool enableCloudAnimation;

  /// The type of cloud animation to use
  final CloudAnimationType cloudType;

  /// Custom cloud color (defaults to white with opacity)
  final Color? cloudColor;

  /// Cloud opacity (0.0 to 1.0)
  final double cloudOpacity;

  /// Creates an animated app bar with cloud background
  const AnimatedAppBar({
    Key? key,
    required this.title,
    this.showBackButton = false,
    this.showDrawerToggle = false,
    this.fallbackRoute = '/home',
    this.onBackPressed,
    this.backButtonTooltip,
    this.actions,
    this.bottom,
    this.centerTitle = true,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.showShadow = true,
    this.leading,
    this.enableCloudAnimation = true,
    this.cloudType = CloudAnimationType.subtle,
    this.cloudColor,
    this.cloudOpacity = 0.2,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor = backgroundColor ?? AppColors.primary;
    final effectiveCloudColor = cloudColor ?? Colors.white;

    return Stack(
      children: [
        // Base app bar
        AppBar(
          title: Text(title),
          centerTitle: centerTitle,
          backgroundColor: effectiveBackgroundColor,
          foregroundColor: foregroundColor,
          elevation: showShadow ? (elevation ?? 4) : 0,
          shadowColor: showShadow ? Colors.black.withAlpha(76) : Colors.transparent,
          actions: actions,
          bottom: bottom,
          leading: _buildLeading(context),
        ),
        
        // Animated cloud background overlay
        if (enableCloudAnimation)
          Positioned.fill(
            child: _buildCloudBackground(effectiveCloudColor),
          ),
      ],
    );
  }

  /// Builds the cloud background based on the selected type
  Widget _buildCloudBackground(Color cloudColor) {
    switch (cloudType) {
      case CloudAnimationType.subtle:
        return CloudBackgrounds.subtle(
          cloudColor: cloudColor,
          opacity: cloudOpacity,
        );
      case CloudAnimationType.prominent:
        return CloudBackgrounds.prominent(
          cloudColor: cloudColor,
          opacity: cloudOpacity,
        );
      case CloudAnimationType.dense:
        return CloudBackgrounds.dense(
          cloudColor: cloudColor,
          opacity: cloudOpacity,
        );
      case CloudAnimationType.peaceful:
        return CloudBackgrounds.peaceful(
          cloudColor: cloudColor,
          opacity: cloudOpacity,
        );
    }
  }

  /// Builds the leading widget based on the configuration
  Widget? _buildLeading(BuildContext context) {
    if (leading != null) {
      return leading;
    }

    if (showBackButton) {
      return BackButtonWidget(
        tooltip: backButtonTooltip,
        fallbackRoute: fallbackRoute,
        onPressed: onBackPressed,
      );
    }

    if (showDrawerToggle) {
      return IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () {
          Scaffold.of(context).openDrawer();
        },
        tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
      );
    }

    return null;
  }

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + (bottom?.preferredSize.height ?? 0)
  );
}

/// Enum for different cloud animation types
enum CloudAnimationType {
  subtle,
  prominent,
  dense,
  peaceful,
}

/// Factory methods for creating animated app bar configurations
class AnimatedAppBars {
  /// Creates a simple animated app bar with subtle clouds
  static AnimatedAppBar simple({
    required String title,
    List<Widget>? actions,
    Color? backgroundColor,
    Color? foregroundColor,
    double? elevation,
    bool centerTitle = true,
    bool showShadow = true,
    bool enableCloudAnimation = true,
    CloudAnimationType cloudType = CloudAnimationType.subtle,
    Color? cloudColor,
    double cloudOpacity = 0.2,
  }) {
    return AnimatedAppBar(
      title: title,
      showBackButton: false,
      actions: actions,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: elevation,
      centerTitle: centerTitle,
      showShadow: showShadow,
      enableCloudAnimation: enableCloudAnimation,
      cloudType: cloudType,
      cloudColor: cloudColor,
      cloudOpacity: cloudOpacity,
    );
  }

  /// Creates an animated app bar with a back button
  static AnimatedAppBar withBackButton({
    required String title,
    String fallbackRoute = '/home',
    VoidCallback? onBackPressed,
    String? backButtonTooltip,
    List<Widget>? actions,
    Color? backgroundColor,
    Color? foregroundColor,
    double? elevation,
    bool centerTitle = true,
    bool showShadow = true,
    bool enableCloudAnimation = true,
    CloudAnimationType cloudType = CloudAnimationType.subtle,
    Color? cloudColor,
    double cloudOpacity = 0.2,
  }) {
    return AnimatedAppBar(
      title: title,
      showBackButton: true,
      fallbackRoute: fallbackRoute,
      onBackPressed: onBackPressed,
      backButtonTooltip: backButtonTooltip,
      actions: actions,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: elevation,
      centerTitle: centerTitle,
      showShadow: showShadow,
      enableCloudAnimation: enableCloudAnimation,
      cloudType: cloudType,
      cloudColor: cloudColor,
      cloudOpacity: cloudOpacity,
    );
  }

  /// Creates an animated app bar with search functionality
  static AnimatedAppBar withSearch({
    required String title,
    required VoidCallback onSearchPressed,
    bool showBackButton = false,
    String fallbackRoute = '/home',
    VoidCallback? onBackPressed,
    List<Widget>? additionalActions,
    Color? backgroundColor,
    Color? foregroundColor,
    double? elevation,
    bool centerTitle = true,
    bool showShadow = true,
    bool enableCloudAnimation = true,
    CloudAnimationType cloudType = CloudAnimationType.subtle,
    Color? cloudColor,
    double cloudOpacity = 0.2,
  }) {
    final actions = <Widget>[
      IconButton(
        icon: const Icon(Icons.search),
        onPressed: onSearchPressed,
      ),
      if (additionalActions != null) ...additionalActions,
    ];

    return AnimatedAppBar(
      title: title,
      showBackButton: showBackButton,
      fallbackRoute: fallbackRoute,
      onBackPressed: onBackPressed,
      actions: actions,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: elevation,
      centerTitle: centerTitle,
      showShadow: showShadow,
      enableCloudAnimation: enableCloudAnimation,
      cloudType: cloudType,
      cloudColor: cloudColor,
      cloudOpacity: cloudOpacity,
    );
  }

  /// Creates an animated app bar with cart and search actions
  static AnimatedAppBar withCartAndSearch({
    required String title,
    required VoidCallback onSearchPressed,
    required VoidCallback onCartPressed,
    required int cartItemCount,
    bool showBackButton = false,
    String fallbackRoute = '/home',
    VoidCallback? onBackPressed,
    List<Widget>? additionalActions,
    Color? backgroundColor,
    Color? foregroundColor,
    double? elevation,
    bool centerTitle = true,
    bool showShadow = true,
    bool enableCloudAnimation = true,
    CloudAnimationType cloudType = CloudAnimationType.subtle,
    Color? cloudColor,
    double cloudOpacity = 0.2,
  }) {
    final actions = <Widget>[
      IconButton(
        icon: const Icon(Icons.search),
        onPressed: onSearchPressed,
        tooltip: 'Search',
      ),
      IconButton(
        icon: Badge(
          isLabelVisible: cartItemCount > 0,
          label: Text(
            cartItemCount.toString(),
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
          child: const Icon(Icons.shopping_cart_outlined),
        ),
        onPressed: onCartPressed,
        tooltip: 'Cart',
      ),
      if (additionalActions != null) ...additionalActions,
    ];

    return AnimatedAppBar(
      title: title,
      showBackButton: showBackButton,
      fallbackRoute: fallbackRoute,
      onBackPressed: onBackPressed,
      actions: actions,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: elevation,
      centerTitle: centerTitle,
      showShadow: showShadow,
      enableCloudAnimation: enableCloudAnimation,
      cloudType: cloudType,
      cloudColor: cloudColor,
      cloudOpacity: cloudOpacity,
    );
  }

  /// Creates an animated app bar with integrated search bar
  static PreferredSizeWidget withSearchBar({
    required String title,
    required VoidCallback onSearchTap,
    required String searchHint,
    bool showBackButton = false,
    String fallbackRoute = '/home',
    VoidCallback? onBackPressed,
    List<Widget>? actions,
    Color? backgroundColor,
    Color? foregroundColor,
    double? elevation,
    bool centerTitle = true,
    bool showShadow = true,
    bool enableCloudAnimation = true,
    CloudAnimationType cloudType = CloudAnimationType.subtle,
    Color? cloudColor,
    double cloudOpacity = 0.2,
  }) {
    final effectiveBackgroundColor = backgroundColor ?? AppColors.primary;
    final effectiveCloudColor = cloudColor ?? Colors.white;

    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 56),
      child: Stack(
        children: [
          // Base app bar with search
          AppBar(
            title: Text(title),
            centerTitle: centerTitle,
            backgroundColor: effectiveBackgroundColor,
            foregroundColor: foregroundColor,
            elevation: showShadow ? (elevation ?? 4) : 0,
            shadowColor: showShadow ? Colors.black.withAlpha(76) : Colors.transparent,
            actions: actions,
            leading: showBackButton
              ? BackButtonWidget(
                  tooltip: 'Back',
                  fallbackRoute: fallbackRoute,
                  onPressed: onBackPressed,
                )
              : null,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: GestureDetector(
                  onTap: onSearchTap,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey[300]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(13),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        Icon(Icons.search, color: Colors.grey[600]),
                        const SizedBox(width: 12),
                        Text(
                          searchHint,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Animated cloud background overlay
          if (enableCloudAnimation)
            Positioned.fill(
              child: _buildCloudBackground(effectiveCloudColor, cloudType, cloudOpacity),
            ),
        ],
      ),
    );
  }

  /// Creates a dedicated animated app bar for the home screen
  static PreferredSizeWidget homeScreen({
    required VoidCallback onSearchTap,
    required VoidCallback onProfileTap,
    String? userPhotoUrl,
    String searchHint = 'Search for products...',
    Color? backgroundColor,
    Color? foregroundColor,
    double? elevation,
    List<Widget>? additionalActions,
    bool showShadow = true,
    bool enableCloudAnimation = true,
    CloudAnimationType cloudType = CloudAnimationType.peaceful,
    Color? cloudColor,
    double cloudOpacity = 0.15,
  }) {
    final effectiveBackgroundColor = backgroundColor ?? AppColors.primary;
    final effectiveCloudColor = cloudColor ?? Colors.white;

    // Create the profile icon
    final profileIcon = CircleAvatar(
      radius: 20,
      backgroundColor: Colors.grey[200],
      backgroundImage: userPhotoUrl != null ? NetworkImage(userPhotoUrl) : null,
      child: userPhotoUrl == null
          ? const Icon(
              Icons.person,
              size: 24,
              color: Colors.grey,
            )
          : null,
    );

    // Create the actions list
    final actions = <Widget>[
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: IconButton(
          icon: profileIcon,
          onPressed: onProfileTap,
          tooltip: 'Profile',
          padding: EdgeInsets.zero,
          iconSize: 40,
        ),
      ),
      if (additionalActions != null) ...additionalActions,
    ];

    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 56),
      child: Stack(
        children: [
          // Base app bar
          AppBar(
            title: const Text(
              'Dayliz',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            centerTitle: false,
            backgroundColor: effectiveBackgroundColor,
            foregroundColor: foregroundColor,
            elevation: showShadow ? (elevation ?? 4) : 0,
            shadowColor: showShadow ? Colors.black.withAlpha(76) : Colors.transparent,
            actions: actions,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: GestureDetector(
                  onTap: onSearchTap,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey[300]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(13),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        Icon(Icons.search, color: Colors.grey[600]),
                        const SizedBox(width: 12),
                        Text(
                          searchHint,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Animated cloud background overlay
          if (enableCloudAnimation)
            Positioned.fill(
              child: _buildCloudBackground(effectiveCloudColor, cloudType, cloudOpacity),
            ),
        ],
      ),
    );
  }

  /// Helper method to build cloud background
  static Widget _buildCloudBackground(Color cloudColor, CloudAnimationType cloudType, double opacity) {
    switch (cloudType) {
      case CloudAnimationType.subtle:
        return CloudBackgrounds.subtle(
          cloudColor: cloudColor,
          opacity: opacity,
        );
      case CloudAnimationType.prominent:
        return CloudBackgrounds.prominent(
          cloudColor: cloudColor,
          opacity: opacity,
        );
      case CloudAnimationType.dense:
        return CloudBackgrounds.dense(
          cloudColor: cloudColor,
          opacity: opacity,
        );
      case CloudAnimationType.peaceful:
        return CloudBackgrounds.peaceful(
          cloudColor: cloudColor,
          opacity: opacity,
        );
    }
  }
}