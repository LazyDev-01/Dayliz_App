import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'auth_button_types.dart';

/// Premium authentication button with modern design and animations
/// Optimized for Q-Commerce authentication flow
class PremiumAuthButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final IconData? icon;
  final Widget? iconWidget;
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  final bool isLoading;
  final AuthButtonPriority priority;
  final double? width;
  final double height;

  const PremiumAuthButton({
    Key? key,
    required this.onPressed,
    this.icon,
    this.iconWidget,
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    this.borderColor,
    this.isLoading = false,
    this.priority = AuthButtonPriority.secondary,
    this.width,
    this.height = 48, // Reduced from 56 to 48
  }) : super(key: key);

  @override
  State<PremiumAuthButton> createState() => _PremiumAuthButtonState();
}

class _PremiumAuthButtonState extends State<PremiumAuthButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _elevationAnimation = Tween<double>(
      begin: _getElevationForPriority(),
      end: _getElevationForPriority() * 0.5,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  double _getElevationForPriority() {
    switch (widget.priority) {
      case AuthButtonPriority.primary:
        return 4.0;
      case AuthButtonPriority.secondary:
        return 2.0;
      case AuthButtonPriority.tertiary:
        return 1.0;
    }
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _isPressed = true);
      _animationController.forward();
      
      // Haptic feedback
      HapticFeedback.lightImpact();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    _handleTapEnd();
  }

  void _handleTapCancel() {
    _handleTapEnd();
  }

  void _handleTapEnd() {
    if (_isPressed) {
      setState(() => _isPressed = false);
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.width ?? double.infinity,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: isDisabled
                  ? null
                  : [
                      BoxShadow(
                        color: widget.backgroundColor.withValues(alpha: 0.3),
                        blurRadius: _elevationAnimation.value * 2,
                        offset: Offset(0, _elevationAnimation.value),
                      ),
                    ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isDisabled ? null : widget.onPressed,
                onTapDown: _handleTapDown,
                onTapUp: _handleTapUp,
                onTapCancel: _handleTapCancel,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDisabled
                        ? widget.backgroundColor.withValues(alpha: 0.5)
                        : widget.backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    border: widget.borderColor != null
                        ? Border.all(
                            color: isDisabled
                                ? widget.borderColor!.withValues(alpha: 0.3)
                                : widget.borderColor!,
                            width: 1.5,
                          )
                        : null,
                    gradient: widget.priority == AuthButtonPriority.primary && !isDisabled
                        ? LinearGradient(
                            colors: [
                              widget.backgroundColor,
                              widget.backgroundColor.withValues(alpha: 0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                  ),
                  child: _buildButtonContent(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildButtonContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon or Loading Indicator
          if (widget.isLoading)
            _buildLoadingIndicator()
          else if (widget.iconWidget != null)
            widget.iconWidget!
          else if (widget.icon != null)
            Icon(
              widget.icon,
              color: widget.textColor,
              size: 24,
            ),
          
          if (!widget.isLoading && (widget.icon != null || widget.iconWidget != null))
            const SizedBox(width: 12),
          
          // Text
          Flexible(
            child: Text(
              widget.isLoading ? 'Please wait...' : widget.text,
              style: TextStyle(
                color: widget.textColor,
                fontSize: 16,
                fontWeight: _getFontWeightForPriority(),
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(widget.textColor),
      ),
    );
  }

  FontWeight _getFontWeightForPriority() {
    switch (widget.priority) {
      case AuthButtonPriority.primary:
        return FontWeight.w600;
      case AuthButtonPriority.secondary:
        return FontWeight.w500;
      case AuthButtonPriority.tertiary:
        return FontWeight.w400;
    }
  }
}

/// Compact version of premium auth button for smaller spaces
class CompactAuthButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String tooltip;
  final Color backgroundColor;
  final Color iconColor;
  final bool isLoading;

  const CompactAuthButton({
    Key? key,
    required this.onPressed,
    required this.icon,
    required this.tooltip,
    required this.backgroundColor,
    required this.iconColor,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                      ),
                    )
                  : Icon(
                      icon,
                      color: iconColor,
                      size: 24,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Social auth button with brand-specific styling
class SocialAuthButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String provider;
  final Widget icon;
  final String text;
  final bool isLoading;

  const SocialAuthButton({
    Key? key,
    required this.onPressed,
    required this.provider,
    required this.icon,
    required this.text,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final config = _getSocialConfig(provider);
    
    return PremiumAuthButton(
      onPressed: onPressed,
      iconWidget: icon,
      text: text,
      backgroundColor: config['backgroundColor'] as Color,
      textColor: config['textColor'] as Color,
      borderColor: config['borderColor'] as Color?,
      isLoading: isLoading,
      priority: AuthButtonPriority.secondary,
    );
  }

  Map<String, dynamic> _getSocialConfig(String provider) {
    switch (provider.toLowerCase()) {
      case 'google':
        return {
          'backgroundColor': Colors.white,
          'textColor': Colors.black87,
          'borderColor': Colors.grey.shade300,
        };
      case 'facebook':
        return {
          'backgroundColor': const Color(0xFF1877F2),
          'textColor': Colors.white,
          'borderColor': null,
        };
      case 'apple':
        return {
          'backgroundColor': Colors.black,
          'textColor': Colors.white,
          'borderColor': null,
        };
      case 'phone':
        return {
          'backgroundColor': const Color(0xFF25D366), // WhatsApp green
          'textColor': Colors.white,
          'borderColor': null,
        };
      default:
        return {
          'backgroundColor': Colors.grey.shade100,
          'textColor': Colors.black87,
          'borderColor': Colors.grey.shade300,
        };
    }
  }
}

/// Auth button with gradient background
class GradientAuthButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData? icon;
  final Widget? iconWidget;
  final String text;
  final List<Color> gradientColors;
  final Color textColor;
  final bool isLoading;

  const GradientAuthButton({
    Key? key,
    required this.onPressed,
    this.icon,
    this.iconWidget,
    required this.text,
    required this.gradientColors,
    required this.textColor,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(textColor),
                    ),
                  )
                else if (iconWidget != null)
                  iconWidget!
                else if (icon != null)
                  Icon(icon, color: textColor, size: 24),
                
                if (!isLoading && (icon != null || iconWidget != null))
                  const SizedBox(width: 12),
                
                Text(
                  isLoading ? 'Please wait...' : text,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
