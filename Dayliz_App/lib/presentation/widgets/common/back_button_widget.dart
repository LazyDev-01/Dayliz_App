import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A reusable back button widget that provides consistent navigation behavior
/// throughout the app.
///
/// Features:
/// - Standard back navigation with fallback routes
/// - Customizable icon and color
/// - Optional tooltip
/// - Haptic feedback
class BackButtonWidget extends StatelessWidget {
  /// The icon to use for the back button
  final IconData icon;

  /// The color of the back button icon
  final Color? color;

  /// The tooltip text for the back button
  final String? tooltip;

  /// The fallback route to navigate to if there's nothing in the navigation stack
  final String fallbackRoute;

  /// Whether to enable haptic feedback when pressed
  final bool enableHapticFeedback;

  /// Custom callback to override default navigation behavior
  final VoidCallback? onPressed;

  /// Creates a back button widget with consistent navigation behavior.
  ///
  /// The [fallbackRoute] is used when there's nothing in the navigation stack to pop.
  /// By default, it navigates to '/home'.
  const BackButtonWidget({
    Key? key,
    this.icon = Icons.arrow_back,
    this.color,
    this.tooltip = 'Back',
    this.fallbackRoute = '/home',
    this.enableHapticFeedback = true,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      color: color,
      tooltip: tooltip,
      onPressed: onPressed ?? () => _handleNavigation(context),
    );
  }

  /// Handles the navigation logic when the back button is pressed.
  ///
  /// First tries to pop the current route. If that's not possible
  /// (e.g., we're at the root), it navigates to the fallback route.
  void _handleNavigation(BuildContext context) {
    if (enableHapticFeedback) {
      // Provide subtle haptic feedback
      Feedback.forTap(context);
    }

    try {
      // First try to check if we can go back via Navigator
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        // If we can't pop, navigate to the fallback route
        context.go(fallbackRoute);
      }
    } catch (e) {
      // If anything fails, use go_router as fallback
      context.go(fallbackRoute);
    }
  }
}

/// Extension to easily add a back button to an AppBar
extension AppBarBackButton on AppBar {
  /// Creates a new AppBar with a BackButtonWidget as the leading widget
  static AppBar withBackButton({
    required String title,
    List<Widget>? actions,
    Color? backgroundColor,
    Color? foregroundColor,
    double? elevation,
    bool centerTitle = true,
    PreferredSizeWidget? bottom,
    String? tooltip,
    String fallbackRoute = '/home',
    VoidCallback? onBackPressed,
  }) {
    return AppBar(
      title: Text(title),
      centerTitle: centerTitle,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: elevation,
      actions: actions,
      bottom: bottom,
      leading: BackButtonWidget(
        tooltip: tooltip,
        fallbackRoute: fallbackRoute,
        onPressed: onBackPressed,
      ),
    );
  }
}
