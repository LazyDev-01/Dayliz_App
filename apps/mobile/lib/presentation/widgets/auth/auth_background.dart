import 'package:flutter/material.dart';
import 'animated_background.dart';

/// Reusable authentication background widget
/// Provides consistent animated background across all auth screens
/// with proper lifecycle management and performance optimization
class AuthBackground extends StatefulWidget {
  /// Child widget to display over the background
  final Widget child;
  
  /// Optional custom primary color (defaults to theme primary)
  final Color? primaryColor;
  
  /// Optional custom secondary color (defaults to theme primary with opacity)
  final Color? secondaryColor;
  
  /// Whether to show back button (for navigation between auth screens)
  final bool showBackButton;
  
  /// Custom back button callback
  final VoidCallback? onBackPressed;
  
  /// Back button icon (defaults to arrow_back_ios)
  final IconData? backButtonIcon;

  const AuthBackground({
    Key? key,
    required this.child,
    this.primaryColor,
    this.secondaryColor,
    this.showBackButton = false,
    this.onBackPressed,
    this.backButtonIcon,
  }) : super(key: key);

  @override
  State<AuthBackground> createState() => _AuthBackgroundState();
}

class _AuthBackgroundState extends State<AuthBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated Background
          AnimatedBackground(
            controller: _animationController,
            primaryColor: widget.primaryColor,
            secondaryColor: widget.secondaryColor,
          ),
          
          // Safe Area Content
          SafeArea(
            child: Stack(
              children: [
                // Main Content
                widget.child,
                
                // Back Button (if needed)
                if (widget.showBackButton)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: _buildBackButton(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onBackPressed ?? () => Navigator.of(context).pop(),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(
            widget.backButtonIcon ?? Icons.arrow_back_ios,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}

/// Simplified auth background for better performance on lower-end devices
class SimpleAuthBackground extends StatefulWidget {
  final Widget child;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final IconData? backButtonIcon;

  const SimpleAuthBackground({
    Key? key,
    required this.child,
    this.showBackButton = false,
    this.onBackPressed,
    this.backButtonIcon,
  }) : super(key: key);

  @override
  State<SimpleAuthBackground> createState() => _SimpleAuthBackgroundState();
}

class _SimpleAuthBackgroundState extends State<SimpleAuthBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Stack(
        children: [
          // Simple Animated Background
          SimpleAnimatedBackground(
            controller: _animationController,
            gradientColors: [
              theme.primaryColor,
              theme.primaryColor.withValues(alpha: 0.7),
              theme.primaryColor.withValues(alpha: 0.8),
            ],
          ),
          
          // Overlay for content readability
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
          
          // Safe Area Content
          SafeArea(
            child: Stack(
              children: [
                // Main Content
                widget.child,
                
                // Back Button (if needed)
                if (widget.showBackButton)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: _buildBackButton(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onBackPressed ?? () => Navigator.of(context).pop(),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(
            widget.backButtonIcon ?? Icons.arrow_back_ios,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}
