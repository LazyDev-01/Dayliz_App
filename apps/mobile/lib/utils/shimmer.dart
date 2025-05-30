import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// A shimmer loading effect widget for placeholder UI elements
/// 
/// Use this widget while content is loading to provide a visual indication
/// to the user that content is being loaded
class ShimmerLoading extends StatelessWidget {
  final double height;
  final double width;
  final double borderRadius;
  final Color baseColor;
  final Color highlightColor;

  const ShimmerLoading({
    super.key,
    required this.height,
    required this.width,
    this.borderRadius = 8.0,
    this.baseColor = const Color(0xFFEEEEEE),
    this.highlightColor = const Color(0xFFFAFAFA),
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
} 