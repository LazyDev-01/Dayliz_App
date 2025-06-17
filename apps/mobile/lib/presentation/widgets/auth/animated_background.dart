import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Animated background for premium authentication screens
/// Features grocery-themed floating elements with smooth animations
class AnimatedBackground extends StatelessWidget {
  final AnimationController controller;
  final Color? primaryColor;
  final Color? secondaryColor;

  const AnimatedBackground({
    Key? key,
    required this.controller,
    this.primaryColor,
    this.secondaryColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    
    final primary = primaryColor ?? theme.primaryColor;
    final secondary = secondaryColor ?? theme.primaryColor.withValues(alpha: 0.7);

    return SizedBox.expand(
      child: Stack(
        children: [
          // Base Gradient Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primary,
                  secondary,
                  primary.withValues(alpha: 0.8),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          
          // Animated Overlay
          AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              return CustomPaint(
                painter: GroceryBackgroundPainter(
                  animation: controller.value,
                  primaryColor: primary,
                  secondaryColor: secondary,
                ),
                size: size,
              );
            },
          ),
          
          // Subtle Overlay for Content Readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.1),
                  Colors.black.withValues(alpha: 0.3),
                  Colors.black.withValues(alpha: 0.1),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for grocery-themed background elements
class GroceryBackgroundPainter extends CustomPainter {
  final double animation;
  final Color primaryColor;
  final Color secondaryColor;

  GroceryBackgroundPainter({
    required this.animation,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 2;

    // Draw floating geometric shapes representing fresh produce
    _drawFloatingShapes(canvas, size, paint);
    
    // Draw subtle grid pattern
    _drawGridPattern(canvas, size, paint);
    
    // Draw accent circles (disabled to show grocery shapes better)
    // _drawAccentCircles(canvas, size, paint);
  }

  void _drawFloatingShapes(Canvas canvas, Size size, Paint paint) {
    final shapes = [
      // Grocery-themed elements with larger sizes for better visibility
      {'x': 0.15, 'y': 0.25, 'size': 50.0, 'speed': 1.0, 'type': 'apple'},
      {'x': 0.75, 'y': 0.35, 'size': 45.0, 'speed': 0.8, 'type': 'orange'},
      {'x': 0.35, 'y': 0.65, 'size': 55.0, 'speed': 1.2, 'type': 'carrot'},
      {'x': 0.85, 'y': 0.75, 'size': 40.0, 'speed': 0.6, 'type': 'leaf'},
      {'x': 0.25, 'y': 0.55, 'size': 60.0, 'speed': 0.9, 'type': 'banana'},
      {'x': 0.65, 'y': 0.15, 'size': 48.0, 'speed': 1.1, 'type': 'tomato'},
      {'x': 0.45, 'y': 0.85, 'size': 52.0, 'speed': 0.7, 'type': 'broccoli'},
    ];

    for (final shape in shapes) {
      final x = (shape['x'] as double) * size.width;
      final y = (shape['y'] as double) * size.height;
      final shapeSize = shape['size'] as double;
      final speed = shape['speed'] as double;
      final shapeType = shape['type'] as String;

      // Calculate animated position
      final animatedY = y + math.sin(animation * 2 * math.pi * speed) * 20;
      final animatedX = x + math.cos(animation * 2 * math.pi * speed * 0.5) * 10;

      // Set color with much higher opacity for better visibility
      final opacity = 0.6 + (math.sin(animation * 2 * math.pi * speed) * 0.2).abs();
      final animatedSize = shapeSize * (0.8 + math.sin(animation * 2 * math.pi * speed) * 0.2);

      // Draw grocery-themed shapes with better colors
      _drawGroceryShape(canvas, Offset(animatedX, animatedY), animatedSize, shapeType, opacity, paint);
    }
  }

  void _drawGroceryShape(Canvas canvas, Offset center, double size, String type, double opacity, Paint paint) {
    // Use different colors for different grocery items to make them more visible
    Color shapeColor;

    switch (type) {
      case 'apple':
        // Red apple with green leaf - more distinct shape
        shapeColor = Colors.red.withValues(alpha: opacity);
        paint.color = shapeColor;
        // Draw apple body (slightly flattened circle)
        final appleRect = Rect.fromCenter(center: center, width: size * 2, height: size * 1.8);
        canvas.drawOval(appleRect, paint);
        // Green leaf on top
        paint.color = Colors.green.withValues(alpha: opacity);
        final leafRect = Rect.fromCenter(
          center: Offset(center.dx + size * 0.3, center.dy - size * 0.8),
          width: size * 0.6,
          height: size * 0.4
        );
        canvas.drawOval(leafRect, paint);
        break;

      case 'orange':
        // Orange with distinct segments
        shapeColor = Colors.orange.withValues(alpha: opacity);
        paint.color = shapeColor;
        canvas.drawCircle(center, size, paint);
        // Draw orange segments
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = 3;
        paint.color = Colors.deepOrange.withValues(alpha: opacity);
        for (int i = 0; i < 8; i++) {
          final angle = (i * math.pi * 2) / 8;
          canvas.drawLine(
            center,
            Offset(
              center.dx + math.cos(angle) * size,
              center.dy + math.sin(angle) * size,
            ),
            paint,
          );
        }
        paint.style = PaintingStyle.fill;
        break;

      case 'carrot':
        // Orange carrot - distinct triangular shape
        shapeColor = Colors.deepOrange.withValues(alpha: opacity);
        paint.color = shapeColor;
        final carrotPath = Path();
        carrotPath.moveTo(center.dx, center.dy - size * 1.2);
        carrotPath.lineTo(center.dx - size * 0.5, center.dy + size * 0.8);
        carrotPath.lineTo(center.dx + size * 0.5, center.dy + size * 0.8);
        carrotPath.close();
        canvas.drawPath(carrotPath, paint);
        // Green carrot leaves
        paint.color = Colors.green.withValues(alpha: opacity);
        for (int i = 0; i < 3; i++) {
          final leafPath = Path();
          final offsetX = (i - 1) * size * 0.2;
          leafPath.moveTo(center.dx + offsetX, center.dy - size * 1.2);
          leafPath.lineTo(center.dx + offsetX - size * 0.1, center.dy - size * 1.6);
          leafPath.lineTo(center.dx + offsetX + size * 0.1, center.dy - size * 1.5);
          leafPath.close();
          canvas.drawPath(leafPath, paint);
        }
        break;

      case 'leaf':
        // Green leaf shape
        shapeColor = Colors.green.withValues(alpha: opacity);
        paint.color = shapeColor;
        final rect = Rect.fromCenter(center: center, width: size * 0.6, height: size * 1.4);
        canvas.drawOval(rect, paint);
        // Leaf vein
        paint.color = const Color(0xFF2E7D32).withValues(alpha: opacity * 0.6);
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = 2;
        canvas.drawLine(
          Offset(center.dx, center.dy - size * 0.7),
          Offset(center.dx, center.dy + size * 0.7),
          paint,
        );
        paint.style = PaintingStyle.fill;
        break;

      case 'banana':
        // Yellow banana - curved crescent shape
        shapeColor = Colors.yellow.withValues(alpha: opacity);
        paint.color = shapeColor;
        final bananaPath = Path();
        bananaPath.moveTo(center.dx - size * 0.8, center.dy + size * 0.3);
        bananaPath.quadraticBezierTo(
          center.dx - size * 0.2, center.dy - size * 0.8,
          center.dx + size * 0.8, center.dy - size * 0.2,
        );
        bananaPath.quadraticBezierTo(
          center.dx + size * 0.6, center.dy + size * 0.1,
          center.dx - size * 0.6, center.dy + size * 0.6,
        );
        bananaPath.close();
        canvas.drawPath(bananaPath, paint);
        break;

      case 'tomato':
        // Red tomato with green crown
        shapeColor = Colors.red.withValues(alpha: opacity);
        paint.color = shapeColor;
        canvas.drawCircle(center, size, paint);
        // Green crown on top
        paint.color = Colors.green.withValues(alpha: opacity * 0.8);
        final crownPath = Path();
        for (int i = 0; i < 5; i++) {
          final angle = (i * math.pi * 2) / 5;
          final x = center.dx + math.cos(angle) * size * 0.8;
          final y = center.dy - size - math.sin(angle) * size * 0.3;
          if (i == 0) {
            crownPath.moveTo(x, y);
          } else {
            crownPath.lineTo(x, y);
          }
        }
        crownPath.close();
        canvas.drawPath(crownPath, paint);
        break;

      case 'broccoli':
        // Green broccoli (multiple small circles)
        shapeColor = Colors.green.withValues(alpha: opacity);
        paint.color = shapeColor;
        for (int i = 0; i < 7; i++) {
          final angle = (i * math.pi * 2) / 7;
          final offset = Offset(
            center.dx + math.cos(angle) * size * 0.3,
            center.dy + math.sin(angle) * size * 0.3,
          );
          canvas.drawCircle(offset, size * 0.3, paint);
        }
        canvas.drawCircle(center, size * 0.4, paint);
        break;

      default:
        // Fallback to light circle
        shapeColor = Colors.white.withValues(alpha: opacity * 0.6);
        paint.color = shapeColor;
        canvas.drawCircle(center, size, paint);
    }
  }

  void _drawGridPattern(Canvas canvas, Size size, Paint paint) {
    paint.color = Colors.white.withValues(alpha: 0.05);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1;

    final gridSize = 60.0;
    final offsetX = (animation * 30) % gridSize;
    final offsetY = (animation * 20) % gridSize;

    // Draw vertical lines
    for (double x = -gridSize + offsetX; x < size.width + gridSize; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Draw horizontal lines
    for (double y = -gridSize + offsetY; y < size.height + gridSize; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    paint.style = PaintingStyle.fill;
  }

  void _drawAccentCircles(Canvas canvas, Size size, Paint paint) {
    final circles = [
      {'x': 0.05, 'y': 0.1, 'radius': 80.0, 'speed': 0.3},
      {'x': 0.95, 'y': 0.9, 'radius': 120.0, 'speed': 0.2},
      {'x': 0.1, 'y': 0.8, 'radius': 60.0, 'speed': 0.4},
      {'x': 0.9, 'y': 0.2, 'radius': 100.0, 'speed': 0.25},
    ];

    for (final circle in circles) {
      final x = (circle['x'] as double) * size.width;
      final y = (circle['y'] as double) * size.height;
      final radius = circle['radius'] as double;
      final speed = circle['speed'] as double;
      
      // Animated radius
      final animatedRadius = radius * (0.8 + math.sin(animation * 2 * math.pi * speed) * 0.2);
      
      // Gradient effect
      final gradient = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.1),
          Colors.white.withValues(alpha: 0.02),
          Colors.transparent,
        ],
        stops: const [0.0, 0.7, 1.0],
      );

      final rect = Rect.fromCircle(
        center: Offset(x, y),
        radius: animatedRadius,
      );

      paint.shader = gradient.createShader(rect);
      
      canvas.drawCircle(
        Offset(x, y),
        animatedRadius,
        paint,
      );
    }

    // Reset shader
    paint.shader = null;
  }

  @override
  bool shouldRepaint(GroceryBackgroundPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}

/// Simplified animated background for better performance
class SimpleAnimatedBackground extends StatelessWidget {
  final AnimationController controller;
  final List<Color> gradientColors;

  const SimpleAnimatedBackground({
    Key? key,
    required this.controller,
    required this.gradientColors,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
              transform: GradientRotation(controller.value * 2 * math.pi * 0.1),
            ),
          ),
        );
      },
    );
  }
}

/// Background variant with floating particles
class ParticleBackground extends StatelessWidget {
  final AnimationController controller;
  final Color primaryColor;
  final int particleCount;

  const ParticleBackground({
    Key? key,
    required this.controller,
    required this.primaryColor,
    this.particleCount = 20,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return CustomPaint(
          painter: ParticlePainter(
            animation: controller.value,
            primaryColor: primaryColor,
            particleCount: particleCount,
          ),
          size: MediaQuery.of(context).size,
        );
      },
    );
  }
}

/// Painter for floating particles
class ParticlePainter extends CustomPainter {
  final double animation;
  final Color primaryColor;
  final int particleCount;

  ParticlePainter({
    required this.animation,
    required this.primaryColor,
    required this.particleCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    final random = math.Random(42); // Fixed seed for consistent animation

    for (int i = 0; i < particleCount; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = 2 + random.nextDouble() * 4;
      final speed = 0.5 + random.nextDouble() * 0.5;
      
      // Animated position
      final animatedY = (y + animation * speed * 100) % (size.height + 20);
      final animatedX = x + math.sin(animation * 2 * math.pi * speed) * 10;
      
      // Opacity based on position
      final opacity = 0.1 + (1 - (animatedY / size.height)) * 0.3;
      
      paint.color = Colors.white.withValues(alpha: opacity);
      
      canvas.drawCircle(
        Offset(animatedX, animatedY),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}
