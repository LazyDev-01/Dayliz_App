import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'back_button_widget.dart';

/// A common app bar widget that can be used throughout the app for consistent UI.
///
/// This widget provides a standardized app bar with various customization options
/// while maintaining a consistent look and feel across the app.
class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
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

  /// Creates a common app bar with consistent styling.
  ///
  /// If [showBackButton] is true, a [BackButtonWidget] will be used as the leading widget
  /// unless a custom [leading] widget is provided.
  const CommonAppBar({
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
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      centerTitle: centerTitle,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: showShadow ? (elevation ?? 4) : 0,
      shadowColor: showShadow ? Colors.black.withAlpha(76) : Colors.transparent,
      actions: actions,
      bottom: bottom,
      leading: _buildLeading(context),
    );
  }

  /// Builds the leading widget based on the configuration.
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

/// Factory methods for creating common app bar configurations
class CommonAppBars {
  /// Creates a simple app bar with a title and no back button
  static CommonAppBar simple({
    required String title,
    List<Widget>? actions,
    Color? backgroundColor,
    Color? foregroundColor,
    double? elevation,
    bool centerTitle = true,
    bool showShadow = true,
  }) {
    return CommonAppBar(
      title: title,
      showBackButton: false,
      actions: actions,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: elevation,
      centerTitle: centerTitle,
      showShadow: showShadow,
    );
  }

  /// Creates an app bar with a back button
  static CommonAppBar withBackButton({
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
  }) {
    return CommonAppBar(
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
    );
  }

  /// Creates an app bar with a search action
  static CommonAppBar withSearch({
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
  }) {
    final actions = <Widget>[
      IconButton(
        icon: const Icon(Icons.search),
        onPressed: onSearchPressed,
      ),
      if (additionalActions != null) ...additionalActions,
    ];

    return CommonAppBar(
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
    );
  }

  /// Creates an app bar with cart and search actions
  static CommonAppBar withCartAndSearch({
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

    return CommonAppBar(
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
    );
  }

  /// Creates an app bar with an integrated search bar
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
  }) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 56), // Extra height for search bar
      child: AppBar(
        title: Text(title),
        centerTitle: centerTitle,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        elevation: showShadow ? (elevation ?? 4) : 0,
        shadowColor: showShadow ? Colors.black.withAlpha(76) : Colors.transparent, // Using withAlpha instead of withOpacity
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
                      color: Colors.black.withAlpha(13), // Using withAlpha instead of withOpacity
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
    );
  }

  /// Creates an app bar with a drawer toggle
  static CommonAppBar withDrawer({
    required String title,
    List<Widget>? actions,
    Color? backgroundColor,
    Color? foregroundColor,
    double? elevation,
    bool centerTitle = true,
    bool showShadow = true,
  }) {
    return CommonAppBar(
      title: title,
      showBackButton: false,
      showDrawerToggle: true,
      actions: actions,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: elevation,
      centerTitle: centerTitle,
      showShadow: showShadow,
    );
  }

  /// Creates a dedicated app bar for the home screen with integrated search bar
  ///
  /// This provides a specialized version of the app bar specifically for the home screen
  /// while still leveraging the common components framework.
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
  }) {
    // Create the profile icon - either a user photo or a default icon
    final profileIcon = CircleAvatar(
      radius: 20, // Increased size from 16 to 20
      backgroundColor: Colors.grey[200],
      backgroundImage: userPhotoUrl != null ? NetworkImage(userPhotoUrl) : null,
      child: userPhotoUrl == null
          ? const Icon(
              Icons.person,
              size: 24, // Increased size from 20 to 24
              color: Colors.grey,
            )
          : null,
    );

    // Create the actions list with the profile icon
    final actions = <Widget>[
      // Profile icon button
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: IconButton(
          icon: profileIcon,
          onPressed: onProfileTap,
          tooltip: 'Profile',
          padding: EdgeInsets.zero,
          iconSize: 40, // Increased touch target
        ),
      ),
      // Add any additional actions
      if (additionalActions != null) ...additionalActions,
    ];

    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 56), // Extra height for search bar
      child: Builder(
        builder: (context) => AppBar(
          title: const Text(
            'Dayliz',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          centerTitle: false, // Changed from true to false to align title to the left
          backgroundColor: backgroundColor,
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
      ),
    );
  }
}
