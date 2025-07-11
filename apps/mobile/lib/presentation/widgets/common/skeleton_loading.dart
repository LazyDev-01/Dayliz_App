import 'package:flutter/material.dart';

/// Skeleton loading widget for better loading experience
class SkeletonLoading extends StatefulWidget {
  final Widget child;
  final bool isLoading;
  final Color? baseColor;
  final Color? highlightColor;

  const SkeletonLoading({
    Key? key,
    required this.child,
    required this.isLoading,
    this.baseColor,
    this.highlightColor,
  }) : super(key: key);

  @override
  State<SkeletonLoading> createState() => _SkeletonLoadingState();
}

class _SkeletonLoadingState extends State<SkeletonLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    if (widget.isLoading) {
      _animationController.repeat();
    }
  }

  @override
  void didUpdateWidget(SkeletonLoading oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _animationController.repeat();
      } else {
        _animationController.stop();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return widget.child;
    }

    final baseColor = widget.baseColor ?? Colors.grey[300]!;
    final highlightColor = widget.highlightColor ?? Colors.grey[100]!;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [baseColor, highlightColor, baseColor],
              stops: [
                (_animation.value - 1).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 1).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// Skeleton container for creating skeleton shapes
class SkeletonContainer extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? color;

  const SkeletonContainer({
    Key? key,
    this.width,
    this.height,
    this.borderRadius,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? Colors.grey[300],
        borderRadius: borderRadius ?? BorderRadius.circular(4),
      ),
    );
  }
}

/// Product card skeleton for search results
class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image skeleton
            SkeletonContainer(
              width: double.infinity,
              height: 120,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 12),
            
            // Product name skeleton
            const SkeletonContainer(
              width: double.infinity,
              height: 16,
            ),
            const SizedBox(height: 8),
            
            // Product description skeleton
            SkeletonContainer(
              width: MediaQuery.of(context).size.width * 0.6,
              height: 14,
            ),
            const SizedBox(height: 12),
            
            // Price skeleton
            const SkeletonContainer(
              width: 80,
              height: 18,
            ),
            const SizedBox(height: 8),
            
            // Add to cart button skeleton
            SkeletonContainer(
              width: double.infinity,
              height: 36,
              borderRadius: BorderRadius.circular(8),
            ),
          ],
        ),
      ),
    );
  }
}

/// Search results skeleton grid
class SearchResultsSkeleton extends StatelessWidget {
  final int itemCount;

  const SearchResultsSkeleton({
    Key? key,
    this.itemCount = 6,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.56, // Fixed to match card's 1:1.8 aspect ratio
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return SkeletonLoading(
          isLoading: true,
          child: const ProductCardSkeleton(),
        );
      },
    );
  }
}

/// Search suggestions skeleton
class SearchSuggestionsSkeleton extends StatelessWidget {
  final int itemCount;

  const SearchSuggestionsSkeleton({
    Key? key,
    this.itemCount = 5,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return SkeletonLoading(
          isLoading: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const SkeletonContainer(
                  width: 20,
                  height: 20,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                const SizedBox(width: 12),
                SkeletonContainer(
                  width: 120 + (index * 20.0), // Varying widths
                  height: 16,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
