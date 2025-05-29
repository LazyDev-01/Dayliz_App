import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Provider for the current bottom navigation index
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

/// A common bottom navigation bar widget that can be used throughout the app
class CommonBottomNavBar extends ConsumerStatefulWidget {
  /// The current index of the selected tab
  final int currentIndex;

  /// Callback when a tab is tapped
  final Function(int)? onTap;

  /// The number of items in the cart (for badge)
  final int cartItemCount;

  /// Creates a common bottom navigation bar with consistent styling
  const CommonBottomNavBar({
    Key? key,
    required this.currentIndex,
    this.onTap,
    this.cartItemCount = 0,
  }) : super(key: key);

  @override
  ConsumerState<CommonBottomNavBar> createState() => _CommonBottomNavBarState();

}

class _CommonBottomNavBarState extends ConsumerState<CommonBottomNavBar> with SingleTickerProviderStateMixin {
  // Animation controller for icon animations
  late AnimationController _animationController;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.currentIndex;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animationController.forward(from: 1.0);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CommonBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _previousIndex = oldWidget.currentIndex;
      _animationController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Animation for scaling effect
    final Animation<double> scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: widget.currentIndex,
      onTap: (index) {
        // Update the state
        ref.read(bottomNavIndexProvider.notifier).state = index;

        // Call the onTap callback if provided
        if (widget.onTap != null) {
          widget.onTap!(index);
        } else {
          // Default navigation behavior
          _handleNavigation(context, index);
        }
      },
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white, // Ensure consistent background color
      selectedItemColor: theme.primaryColor,
      unselectedItemColor: theme.textTheme.bodyMedium?.color?.withAlpha(153), // Using withAlpha instead of withOpacity
      items: _buildAnimatedItems(scaleAnimation),
      elevation: 0, // Remove default elevation as we're using custom shadow
    ),
    );
  }

  // Build animated navigation items
  List<BottomNavigationBarItem> _buildAnimatedItems(Animation<double> animation) {
    return [
      _buildAnimatedItem(
        index: 0,
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        label: 'Home',
        animation: animation,
      ),
      _buildAnimatedItem(
        index: 1,
        icon: Icons.category_outlined,
        activeIcon: Icons.category,
        label: 'Categories',
        animation: animation,
      ),
      _buildCartItem(
        index: 2,
        animation: animation,
      ),
      _buildAnimatedItem(
        index: 3,
        icon: Icons.receipt_outlined,
        activeIcon: Icons.receipt,
        label: 'Orders',
        animation: animation,
      ),
    ];
  }

  // Build animated navigation item
  BottomNavigationBarItem _buildAnimatedItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required Animation<double> animation,
  }) {
    final isSelected = widget.currentIndex == index;
    final wasSelected = _previousIndex == index;

    // Only animate the item that is being selected or deselected
    final shouldAnimate = isSelected || wasSelected;

    return BottomNavigationBarItem(
      icon: shouldAnimate
          ? ScaleTransition(
              scale: isSelected
                  ? Tween<double>(begin: 0.8, end: 1.0).animate(animation)
                  : Tween<double>(begin: 1.0, end: 0.8).animate(animation),
              child: Icon(icon),
            )
          : Icon(icon),
      activeIcon: shouldAnimate
          ? ScaleTransition(
              scale: isSelected
                  ? Tween<double>(begin: 0.8, end: 1.0).animate(animation)
                  : Tween<double>(begin: 1.0, end: 0.8).animate(animation),
              child: Icon(activeIcon),
            )
          : Icon(activeIcon),
      label: label,
    );
  }

  // Build cart item with badge
  BottomNavigationBarItem _buildCartItem({
    required int index,
    required Animation<double> animation,
  }) {
    final isSelected = widget.currentIndex == index;
    final wasSelected = _previousIndex == index;
    final shouldAnimate = isSelected || wasSelected;

    return BottomNavigationBarItem(
      icon: shouldAnimate
          ? ScaleTransition(
              scale: isSelected
                  ? Tween<double>(begin: 0.8, end: 1.0).animate(animation)
                  : Tween<double>(begin: 1.0, end: 0.8).animate(animation),
              child: Badge(
                isLabelVisible: widget.cartItemCount > 0,
                label: Text(
                  widget.cartItemCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
                child: const Icon(Icons.shopping_cart_outlined),
              ),
            )
          : Badge(
              isLabelVisible: widget.cartItemCount > 0,
              label: Text(
                widget.cartItemCount.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
      activeIcon: shouldAnimate
          ? ScaleTransition(
              scale: isSelected
                  ? Tween<double>(begin: 0.8, end: 1.0).animate(animation)
                  : Tween<double>(begin: 1.0, end: 0.8).animate(animation),
              child: Badge(
                isLabelVisible: widget.cartItemCount > 0,
                label: Text(
                  widget.cartItemCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
                child: const Icon(Icons.shopping_cart),
              ),
            )
          : Badge(
              isLabelVisible: widget.cartItemCount > 0,
              label: Text(
                widget.cartItemCount.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
              child: const Icon(Icons.shopping_cart),
            ),
      label: 'Cart',
    );
  }

  /// Handles navigation based on the selected tab index
  void _handleNavigation(BuildContext context, int index) {
    switch (index) {
      case 0:
        // Use replace instead of go to avoid animation for home
        context.replace('/clean-home');
        break;
      case 1:
        // Use replace instead of go to avoid animation for categories
        context.replace('/clean/categories');
        break;
      case 2:
        // Use replace instead of go to avoid animation for cart
        context.replace('/clean/cart');
        break;
      case 3:
        // Use replace instead of go to avoid animation for orders
        context.replace('/clean/orders');
        break;
    }
  }
}

/// Factory methods for creating common bottom navigation bar configurations
class CommonBottomNavBars {
  /// Creates a standard bottom navigation bar
  static CommonBottomNavBar standard({
    required int currentIndex,
    Function(int)? onTap,
    required int cartItemCount,
  }) {
    return CommonBottomNavBar(
      currentIndex: currentIndex,
      onTap: onTap,
      cartItemCount: cartItemCount,
    );
  }
}
