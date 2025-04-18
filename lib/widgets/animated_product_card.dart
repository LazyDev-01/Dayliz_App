import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dayliz_app/models/product.dart';
import 'package:dayliz_app/widgets/product_card.dart';
import 'package:dayliz_app/providers/cart_provider.dart';
import 'package:flutter/services.dart';

class AnimatedProductCard extends ConsumerStatefulWidget {
  final Product product;
  final VoidCallback? onTap;
  final bool useAccessibility;
  final bool useHeroAnimation;

  const AnimatedProductCard({
    Key? key,
    required this.product,
    this.onTap,
    this.useAccessibility = true,
    this.useHeroAnimation = true,
  }) : super(key: key);

  @override
  ConsumerState<AnimatedProductCard> createState() => _AnimatedProductCardState();
}

class _AnimatedProductCardState extends ConsumerState<AnimatedProductCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isInCart = false;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check if the product is in the cart
    final cartItems = ref.watch(cartProvider);
    final cartItem = cartItems.where((item) => item.productId == widget.product.id).toList();
    
    // Update isInCart and quantity based on cart state
    if (cartItem.isNotEmpty) {
      _isInCart = true;
      _quantity = cartItem.first.quantity;
    } else {
      _isInCart = false;
      _quantity = 1;
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: ProductCard(
            product: widget.product,
            onTap: widget.onTap,
            useAccessibility: widget.useAccessibility,
            useHeroAnimation: widget.useHeroAnimation,
            isInCart: _isInCart,
            quantity: _quantity,
            onAddToCart: _handleAddToCart,
            onIncreaseQuantity: _handleIncreaseQuantity,
            onDecreaseQuantity: _handleDecreaseQuantity,
          ),
        );
      },
    );
  }

  void _handleAddToCart() {
    // Add haptic feedback
    HapticFeedback.mediumImpact();
    
    // Add the product to the cart
    ref.read(cartProvider.notifier).addToCart(widget.product);
    
    // Show animation
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
    
    // Update state
    setState(() {
      _isInCart = true;
      _quantity = 1;
    });
  }

  void _handleIncreaseQuantity() {
    // Add haptic feedback
    HapticFeedback.selectionClick();
    
    // Increase quantity
    ref.read(cartProvider.notifier).updateQuantity(widget.product.id, _quantity + 1);
    
    // Update state 
    setState(() {
      _quantity += 1;
    });
  }

  void _handleDecreaseQuantity() {
    if (_quantity <= 1) {
      // Remove from cart if quantity is 1
      ref.read(cartProvider.notifier).removeFromCart(widget.product.id);
      
      // Update state
      setState(() {
        _isInCart = false;
      });
    } else {
      // Decrease quantity
      ref.read(cartProvider.notifier).updateQuantity(widget.product.id, _quantity - 1);
      
      // Update state
      setState(() {
        _quantity -= 1;
      });
    }
    
    // Add haptic feedback
    HapticFeedback.selectionClick();
  }
} 