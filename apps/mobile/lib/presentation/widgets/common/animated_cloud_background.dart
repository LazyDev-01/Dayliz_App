import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A widget that displays animated floating clouds in the background
/// Perfect for app bars to add a subtle, delightful animation
class AnimatedCloudBackground extends StatefulWidget {
  /// The number of clouds to display
  final int cloudCount;
  
  /// The color of the clouds
  final Color cloudColor;
  
  /// The opacity of the clouds
  final double cloudOpacity;
  
  /// The speed of cloud movement (lower = slower)
  final double animationSpeed;
  
  /// The size range of clouds (min, max)
  final double minCloudSize;
  final double maxCloudSize;
  
  /// Whether to enable the animation
  final bool enableAnimation;

  const AnimatedCloudBackground({
    Key? key,
    this.cloudCount = 5,
    this.cloudColor = Colors.white,
    this.cloudOpacity = 0.4,
    this.animationSpeed = 1.0,
    this.minCloudSize = 40.0,
    this.maxCloudSize = 80.0,
    this.enableAnimation = true,
  }) : super(key: key);

  @override
  State<AnimatedCloudBackground> createState() => _AnimatedCloudBackgroundState();
}

class _AnimatedCloudBackgroundState extends State<AnimatedCloudBackground>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  late List<CloudData> _clouds;

  @override
  void initState() {
    super.initState();
    _initializeClouds();
  }

  void _initializeClouds() {
    _controllers = [];
    _animations = [];
    _clouds = [];

    final random = math.Random();

    // Calculate timing for continuous flow
    const baseDuration = 25000; // Base duration in milliseconds
    final totalDuration = baseDuration ~/ widget.animationSpeed;
    
    // Distribute clouds evenly across time to ensure continuous flow
    final delayInterval = totalDuration / widget.cloudCount;

    for (int i = 0; i < widget.cloudCount; i++) {
      // Create animation controller for each cloud - Continuous movement
      final controller = AnimationController(
        duration: Duration(milliseconds: totalDuration),
        vsync: this,
      );

      // Create animation for horizontal movement - Start from left, end at right
      final animation = Tween<double>(
        begin: -0.3, // Start well before left edge
        end: 1.3, // End well after right edge
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.linear,
      ));

      // Create cloud data with evenly distributed delays for continuous flow
      final cloud = CloudData(
        size: widget.minCloudSize + 
              random.nextDouble() * (widget.maxCloudSize - widget.minCloudSize),
        yPosition: random.nextDouble() * 1.0, // Spread clouds throughout entire app bar height
        opacity: widget.cloudOpacity * (0.8 + random.nextDouble() * 0.4),
        speed: 0.9 + random.nextDouble() * 0.2, // Less speed variation for smoother flow
        delay: (i * delayInterval).round() + random.nextInt(2000), // Evenly distributed with small random offset
      );

      _controllers.add(controller);
      _animations.add(animation);
      _clouds.add(cloud);

      // Start animation with calculated delay for continuous flow
      if (widget.enableAnimation) {
        Future.delayed(Duration(milliseconds: cloud.delay), () {
          if (mounted) {
            controller.repeat();
          }
        });
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        children: [
          for (int i = 0; i < widget.cloudCount; i++)
            AnimatedBuilder(
              animation: _animations[i],
              builder: (context, child) {
                return Positioned(
                  left: _animations[i].value * MediaQuery.of(context).size.width,
                  top: _clouds[i].yPosition * kToolbarHeight,
                  child: Opacity(
                    opacity: _clouds[i].opacity,
                    child: CloudShape(
                      size: _clouds[i].size,
                      color: widget.cloudColor,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// Data class to hold cloud properties
class CloudData {
  final double size;
  final double yPosition;
  final double opacity;
  final double speed;
  final int delay;

  CloudData({
    required this.size,
    required this.yPosition,
    required this.opacity,
    required this.speed,
    required this.delay,
  });
}

/// Custom widget to draw a cloud shape
class CloudShape extends StatelessWidget {
  final double size;
  final Color color;

  const CloudShape({
    Key? key,
    required this.size,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 0.6),
      painter: CloudPainter(color: color),
    );
  }
}

/// Custom painter to draw cloud shapes
class CloudPainter extends CustomPainter {
  final Color color;

  CloudPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    
    // Create a cloud shape using multiple circles
    final width = size.width;
    final height = size.height;
    
    // Main cloud body (larger circle in the center)
    final mainCircle = Rect.fromCircle(
      center: Offset(width * 0.5, height * 0.7),
      radius: width * 0.25,
    );
    
    // Left puff
    final leftCircle = Rect.fromCircle(
      center: Offset(width * 0.25, height * 0.6),
      radius: width * 0.18,
    );
    
    // Right puff
    final rightCircle = Rect.fromCircle(
      center: Offset(width * 0.75, height * 0.6),
      radius: width * 0.2,
    );
    
    // Top puff
    final topCircle = Rect.fromCircle(
      center: Offset(width * 0.5, height * 0.4),
      radius: width * 0.15,
    );
    
    // Small left puff
    final smallLeftCircle = Rect.fromCircle(
      center: Offset(width * 0.15, height * 0.75),
      radius: width * 0.12,
    );
    
    // Small right puff
    final smallRightCircle = Rect.fromCircle(
      center: Offset(width * 0.85, height * 0.75),
      radius: width * 0.14,
    );

    // Draw all circles to form a cloud
    canvas.drawOval(mainCircle, paint);
    canvas.drawOval(leftCircle, paint);
    canvas.drawOval(rightCircle, paint);
    canvas.drawOval(topCircle, paint);
    canvas.drawOval(smallLeftCircle, paint);
    canvas.drawOval(smallRightCircle, paint);
  }

  @override
  bool shouldRepaint(CloudPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

/// A simplified cloud widget for better performance
class SimpleCloudShape extends StatelessWidget {
  final double size;
  final Color color;

  const SimpleCloudShape({
    Key? key,
    required this.size,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size * 0.6,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Stack(
        children: [
          // Left puff
          Positioned(
            left: 0,
            top: size * 0.1,
            child: Container(
              width: size * 0.4,
              height: size * 0.4,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Right puff
          Positioned(
            right: 0,
            top: size * 0.1,
            child: Container(
              width: size * 0.4,
              height: size * 0.4,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Top puff
          Positioned(
            left: size * 0.3,
            top: 0,
            child: Container(
              width: size * 0.4,
              height: size * 0.4,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Factory methods for different cloud configurations
class CloudBackgrounds {
  /// Subtle clouds for app bars - Fewer clouds, pure white, spread throughout
  static AnimatedCloudBackground subtle({
    Color cloudColor = Colors.white, // Pure white for better contrast
    double opacity = 0.5,
  }) {
    return AnimatedCloudBackground(
      cloudCount: 4, // Reduced from 6 to 4
      cloudColor: cloudColor,
      cloudOpacity: opacity,
      animationSpeed: 0.4, // Balanced speed
      minCloudSize: 30.0,
      maxCloudSize: 60.0,
    );
  }

  /// More prominent clouds for backgrounds - Fewer clouds, pure white
  static AnimatedCloudBackground prominent({
    Color cloudColor = Colors.white, // Pure white for better contrast
    double opacity = 0.6,
  }) {
    return AnimatedCloudBackground(
      cloudCount: 5, // Reduced from 8 to 5
      cloudColor: cloudColor,
      cloudOpacity: opacity,
      animationSpeed: 0.5, // Balanced speed
      minCloudSize: 50.0,
      maxCloudSize: 100.0,
    );
  }

  /// Dense clouds for special effects - Fewer clouds, pure white
  static AnimatedCloudBackground dense({
    Color cloudColor = Colors.white, // Pure white for better contrast
    double opacity = 0.55,
  }) {
    return AnimatedCloudBackground(
      cloudCount: 8, // Reduced from 12 to 8
      cloudColor: cloudColor,
      cloudOpacity: opacity,
      animationSpeed: 0.6, // Slightly faster for dense effect
      minCloudSize: 25.0,
      maxCloudSize: 70.0,
    );
  }

  /// Slow-moving peaceful clouds - Fewer clouds, pure white, spread throughout
  static AnimatedCloudBackground peaceful({
    Color cloudColor = Colors.white, // Pure white for better contrast
    double opacity = 0.45,
  }) {
    return AnimatedCloudBackground(
      cloudCount: 5, // Reduced from 8 to 5
      cloudColor: cloudColor,
      cloudOpacity: opacity,
      animationSpeed: 0.3, // Slow but not too slow
      minCloudSize: 40.0,
      maxCloudSize: 80.0,
    );
  }
}