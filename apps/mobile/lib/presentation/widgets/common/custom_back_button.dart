import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Custom back button widget that uses the app's custom back icon
/// and provides consistent navigation behavior
class CustomBackButton extends StatelessWidget {
  /// The route to navigate to when pressed. If null, navigates to home.
  final String? targetRoute;
  
  /// Custom onPressed callback. If provided, overrides default navigation.
  final VoidCallback? onPressed;
  
  /// Size of the back button icon
  final double? iconSize;
  
  /// Color of the back button icon
  final Color? iconColor;
  
  /// Tooltip text for the back button
  final String? tooltip;
  
  /// Whether to always navigate to home regardless of navigation stack
  final bool alwaysGoHome;

  const CustomBackButton({
    super.key,
    this.targetRoute,
    this.onPressed,
    this.iconSize = 24.0,
    this.iconColor,
    this.tooltip,
    this.alwaysGoHome = false,
  });

  /// Factory constructor for back button that always goes to home
  const CustomBackButton.toHome({
    super.key,
    this.iconSize = 24.0,
    this.iconColor,
    this.tooltip = 'Back to Home',
  }) : targetRoute = '/clean/home',
       onPressed = null,
       alwaysGoHome = true;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed ?? () => _handleBackPress(context),
      tooltip: tooltip ?? 'Back',
      icon: Image.asset(
        'assets/icons/arrow left.png',
        width: iconSize,
        height: iconSize,
        color: iconColor ?? Theme.of(context).iconTheme.color,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to default back icon if custom icon fails to load
          return Icon(
            Icons.arrow_back,
            size: iconSize,
            color: iconColor ?? Theme.of(context).iconTheme.color,
          );
        },
      ),
    );
  }

  void _handleBackPress(BuildContext context) {
    if (alwaysGoHome || targetRoute != null) {
      // Navigate to specific route or home
      final route = targetRoute ?? '/clean/home';
      context.go(route);
    } else {
      // Check if we can pop the current route
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        // If we can't pop, go to home
        context.go('/clean/home');
      }
    }
  }
}

/// Custom app bar with the custom back button
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool automaticallyImplyLeading;
  final Widget? leading;
  final bool centerTitle;
  final double elevation;
  final String? backRoute;
  final bool alwaysGoHome;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.backgroundColor,
    this.foregroundColor,
    this.automaticallyImplyLeading = true,
    this.leading,
    this.centerTitle = false,
    this.elevation = 4.0,
    this.backRoute,
    this.alwaysGoHome = false,
  });

  /// Factory constructor for app bar that always goes to home
  const CustomAppBar.toHome({
    super.key,
    required this.title,
    this.actions,
    this.backgroundColor,
    this.foregroundColor,
    this.automaticallyImplyLeading = true,
    this.leading,
    this.centerTitle = false,
    this.elevation = 4.0,
  }) : backRoute = '/clean/home',
       alwaysGoHome = true;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          color: foregroundColor ?? Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: backgroundColor ?? Colors.white,
      elevation: elevation,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      surfaceTintColor: Colors.transparent,
      centerTitle: centerTitle,
      automaticallyImplyLeading: false,
      leading: automaticallyImplyLeading
          ? (leading ?? CustomBackButton(
              targetRoute: backRoute,
              alwaysGoHome: alwaysGoHome,
              iconColor: foregroundColor ?? Colors.black,
              tooltip: alwaysGoHome ? 'Back to Home' : 'Back',
            ))
          : leading,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
