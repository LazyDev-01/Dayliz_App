import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/cart_item.dart';
import '../../providers/cart_providers.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/primary_button.dart';

import '../../widgets/cart/cart_item_card.dart';
import '../../widgets/common/navigation_handler.dart';

/// LEGACY: A clean architecture implementation of the cart screen that uses Riverpod providers
/// This screen has been replaced by ModernCartScreen in Phase 3
/// Kept as backup for reference - DO NOT USE IN PRODUCTION
class CleanCartScreen extends ConsumerWidget {
  const CleanCartScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch cart state
    final cartState = ref.watch(cartNotifierProvider);



    // Note: Navigation state is handled by NavigationHandler

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.cart),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _handleBackNavigation(context, ref),
          tooltip: 'Back to Home',
        ),
        actions: [
          if (cartState.items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _showClearCartDialog(context, ref),
              tooltip: AppStrings.clearCart,
            ),
        ],
      ),
      body: _buildBody(context, ref, cartState),
      bottomNavigationBar: cartState.items.isNotEmpty
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildBottomBar(context, ref, cartState),
                NavigationHandler.createBottomNavBar(
                  context: context,
                  ref: ref,
                  currentIndex: 2, // Cart tab
                ),
              ],
            )
          : NavigationHandler.createBottomNavBar(
              context: context,
              ref: ref,
              currentIndex: 2, // Cart tab
            ),
    );
  }



  Widget _buildBody(BuildContext context, WidgetRef ref, CartState state) {
    // Show loading state
    if (state.isLoading) {
      return const Center(
        child: LoadingIndicator(),
      );
    }

    // Show error state
    if (state.errorMessage != null) {
      return ErrorState(
        message: state.errorMessage!,
        onRetry: () => ref.read(cartNotifierProvider.notifier).getCartItems(),
      );
    }

    // Show empty state
    if (state.items.isEmpty) {
      return EmptyState(
        icon: Icons.shopping_cart_outlined,
        title: AppStrings.emptyCartTitle,
        message: AppStrings.emptyCartMessage,
        buttonText: AppStrings.continueShopping,
        onButtonPressed: () {
          // Navigate to main home screen
          context.goToMainHomeWithProvider(ref);
        },
      );
    }

    // Show cart items
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.items.length,
      itemBuilder: (context, index) {
        final cartItem = state.items[index];
        return _buildCartItemCard(context, ref, cartItem);
      },
    );
  }

  Widget _buildCartItemCard(BuildContext context, WidgetRef ref, CartItem cartItem) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: CartItemCard(
        cartItem: cartItem,
        onRemove: () => _removeFromCart(context, ref, cartItem),
        onQuantityChanged: (quantity) => _updateCartItemQuantity(ref, cartItem, quantity),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, WidgetRef ref, CartState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        // Remove shadow since we'll have the bottom nav bar below
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.grey.withAlpha(26),
        //     blurRadius: 10,
        //     offset: Offset(0, -2),
        //   ),
        // ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cart summary
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.totalItems,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${state.totalQuantity}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.total,
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                '\$${state.totalPrice.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Checkout button
          PrimaryButton(
            text: AppStrings.proceedToCheckout,
            onPressed: () => _proceedToCheckout(context),
            isFullWidth: true,
            iconData: Icons.shopping_cart_checkout,
          ),

          // Add a small divider between the checkout button and bottom nav bar
          const SizedBox(height: 8),
          const Divider(height: 1),
        ],
      ),
    );
  }

  void _removeFromCart(BuildContext context, WidgetRef ref, CartItem cartItem) async {
    final success = await ref.read(cartNotifierProvider.notifier).removeFromCart(cartItemId: cartItem.id);

    if (!success) {
      final errorMessage = ref.read(cartErrorProvider);
      if (context.mounted) {
        debugPrint('Error removing from cart: ${errorMessage ?? AppStrings.errorRemovingFromCart}');
        // Error notifications disabled for early launch
      }
    }
  }

  void _updateCartItemQuantity(WidgetRef ref, CartItem cartItem, int quantity) async {
    if (quantity < 1) {
      return;
    }

    final success = await ref.read(cartNotifierProvider.notifier).updateQuantity(
      cartItemId: cartItem.id,
      quantity: quantity,
    );

    if (!success) {
      ref.read(cartNotifierProvider.notifier).getCartItems();
    }
  }

  void _showClearCartDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.clearCartTitle),
        content: const Text(AppStrings.clearCartConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _clearCart(context, ref);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text(AppStrings.clear),
          ),
        ],
      ),
    );
  }

  void _clearCart(BuildContext context, WidgetRef ref) async {
    final success = await ref.read(cartNotifierProvider.notifier).clearCart();

    if (!success && context.mounted) {
      final errorMessage = ref.read(cartErrorProvider);
      debugPrint('Error clearing cart: ${errorMessage ?? AppStrings.errorClearingCart}');
      // Error notifications disabled for early launch
    }
  }

  void _proceedToCheckout(BuildContext context) {
    // Navigate to checkout
    context.push('/checkout');
  }

  /// Handles back navigation properly for standalone cart screens
  void _handleBackNavigation(BuildContext context, WidgetRef ref) {
    debugPrint('🔙 Back button pressed in clean cart screen');

    // Navigate to main home screen with proper provider update
    debugPrint('🔙 Navigating to main home screen');
    context.goToMainHomeWithProvider(ref);

    debugPrint('🔙 Back navigation completed');
  }
}