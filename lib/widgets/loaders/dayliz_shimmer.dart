import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:dayliz_app/theme/app_theme.dart';

/// A customizable shimmer effect for loading states.
class DaylizShimmer extends StatelessWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration duration;
  final ShimmerDirection direction;
  final bool enabled;

  const DaylizShimmer({
    Key? key,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1500),
    this.direction = ShimmerDirection.ltr,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final defaultBaseColor = isDark 
        ? const Color(0xFF2A2A2A) 
        : const Color(0xFFE0E0E0);
    
    final defaultHighlightColor = isDark 
        ? const Color(0xFF3A3A3A) 
        : const Color(0xFFF5F5F5);
    
    return Shimmer.fromColors(
      baseColor: baseColor ?? defaultBaseColor,
      highlightColor: highlightColor ?? defaultHighlightColor,
      period: duration,
      direction: direction,
      enabled: enabled,
      child: child,
    );
  }

  /// Creates a shimmer effect for a product card.
  static Widget productCard(BuildContext context, {double? height, double? width}) {
    final theme = Theme.of(context);
    final daylizTheme = theme.extension<DaylizThemeExtension>();
    
    return DaylizShimmer(
      child: Container(
        width: width ?? double.infinity,
        height: height ?? 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: daylizTheme?.cardBorderRadius ?? BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// Creates a shimmer effect for text.
  static Widget text(
    BuildContext context, {
    double width = 100,
    double height = 14,
    BorderRadius? borderRadius,
  }) {
    return DaylizShimmer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? BorderRadius.circular(4),
        ),
      ),
    );
  }

  /// Creates a shimmer effect for a circular avatar.
  static Widget circle(
    BuildContext context, {
    double size = 48,
  }) {
    return DaylizShimmer(
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  /// Creates a shimmer effect for a product list.
  static Widget productList(
    BuildContext context, {
    int itemCount = 3,
    double height = 120,
  }) {
    return Column(
      children: List.generate(
        itemCount,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: DaylizShimmer.productCard(context, height: height),
        ),
      ),
    );
  }

  /// Creates a shimmer effect for a grid of items.
  static Widget grid(
    BuildContext context, {
    int crossAxisCount = 2,
    int itemCount = 4,
    double height = 200,
    double spacing = 16,
  }) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: 0.75,
      ),
      itemCount: itemCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return DaylizShimmer(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
    );
  }
} 