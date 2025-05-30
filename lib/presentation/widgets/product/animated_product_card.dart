import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dayliz_app/domain/entities/product.dart';
import 'package:dayliz_app/presentation/widgets/product/clean_product_card.dart';

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
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: CleanProductCard(
            product: widget.product,
            onTap: widget.onTap,
          ),
        );
      },
    );
  }
}