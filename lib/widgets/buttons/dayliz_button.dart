import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dayliz_app/theme/app_theme.dart';

enum DaylizButtonType {
  primary,
  secondary,
  tertiary,
  danger,
  text,
}

enum DaylizButtonSize {
  small,
  medium,
  large,
}

class DaylizButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final DaylizButtonType type;
  final DaylizButtonSize size;
  final bool isFullWidth;
  final bool isLoading;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool enableHapticFeedback;

  const DaylizButton({
    Key? key,
    required this.label,
    this.onPressed,
    this.type = DaylizButtonType.primary,
    this.size = DaylizButtonSize.medium,
    this.isFullWidth = false,
    this.isLoading = false,
    this.leadingIcon,
    this.trailingIcon,
    this.enableHapticFeedback = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daylizTheme = theme.extension<DaylizThemeExtension>();
    
    // Determine padding based on size
    EdgeInsetsGeometry buttonPadding;
    double fontSize;
    double iconSize;
    
    switch (size) {
      case DaylizButtonSize.small:
        buttonPadding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
        fontSize = 12;
        iconSize = 16;
        break;
      case DaylizButtonSize.large:
        buttonPadding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
        fontSize = 16;
        iconSize = 24;
        break;
      case DaylizButtonSize.medium:
      default:
        buttonPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
        fontSize = 14;
        iconSize = 20;
    }

    // Handle button tap with haptic feedback
    void handleTap() {
      if (onPressed != null) {
        if (enableHapticFeedback) {
          HapticFeedback.lightImpact();
        }
        onPressed!();
      }
    }

    // Create button content
    Widget buttonContent = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leadingIcon != null && !isLoading) ...[
          Icon(leadingIcon, size: iconSize),
          const SizedBox(width: 8),
        ],
        if (isLoading)
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                type == DaylizButtonType.primary
                    ? Colors.white
                    : theme.primaryColor,
              ),
            ),
          ),
        if (isLoading) const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (trailingIcon != null && !isLoading) ...[
          const SizedBox(width: 8),
          Icon(trailingIcon, size: iconSize),
        ],
      ],
    );

    // Apply button style based on type
    switch (type) {
      case DaylizButtonType.primary:
        return ElevatedButton(
          onPressed: isLoading ? null : handleTap,
          style: ElevatedButton.styleFrom(
            padding: buttonPadding,
            backgroundColor: theme.primaryColor,
            foregroundColor: Colors.white,
            disabledBackgroundColor: theme.primaryColor.withOpacity(0.5),
            disabledForegroundColor: Colors.white.withOpacity(0.7),
            shape: RoundedRectangleBorder(
              borderRadius: daylizTheme?.buttonBorderRadius ?? BorderRadius.circular(8),
            ),
            minimumSize: isFullWidth ? const Size.fromHeight(0) : null,
          ),
          child: buttonContent,
        );
        
      case DaylizButtonType.secondary:
        return OutlinedButton(
          onPressed: isLoading ? null : handleTap,
          style: OutlinedButton.styleFrom(
            padding: buttonPadding,
            foregroundColor: theme.primaryColor,
            side: BorderSide(
              color: isLoading ? theme.primaryColor.withOpacity(0.5) : theme.primaryColor,
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: daylizTheme?.buttonBorderRadius ?? BorderRadius.circular(8),
            ),
            minimumSize: isFullWidth ? const Size.fromHeight(0) : null,
          ),
          child: buttonContent,
        );
        
      case DaylizButtonType.tertiary:
        return OutlinedButton(
          onPressed: isLoading ? null : handleTap,
          style: OutlinedButton.styleFrom(
            padding: buttonPadding,
            foregroundColor: theme.colorScheme.secondary,
            backgroundColor: theme.colorScheme.secondaryContainer.withOpacity(0.3),
            side: BorderSide(
              color: isLoading ? theme.colorScheme.secondary.withOpacity(0.5) : theme.colorScheme.secondary,
              width: 1.0,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: daylizTheme?.buttonBorderRadius ?? BorderRadius.circular(8),
            ),
            minimumSize: isFullWidth ? const Size.fromHeight(0) : null,
          ),
          child: buttonContent,
        );
        
      case DaylizButtonType.danger:
        return ElevatedButton(
          onPressed: isLoading ? null : handleTap,
          style: ElevatedButton.styleFrom(
            padding: buttonPadding,
            backgroundColor: theme.colorScheme.error,
            foregroundColor: Colors.white,
            disabledBackgroundColor: theme.colorScheme.error.withOpacity(0.5),
            disabledForegroundColor: Colors.white.withOpacity(0.7),
            shape: RoundedRectangleBorder(
              borderRadius: daylizTheme?.buttonBorderRadius ?? BorderRadius.circular(8),
            ),
            minimumSize: isFullWidth ? const Size.fromHeight(0) : null,
          ),
          child: buttonContent,
        );
        
      case DaylizButtonType.text:
        return TextButton(
          onPressed: isLoading ? null : handleTap,
          style: TextButton.styleFrom(
            padding: buttonPadding,
            foregroundColor: theme.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: daylizTheme?.buttonBorderRadius ?? BorderRadius.circular(8),
            ),
            minimumSize: isFullWidth ? const Size.fromHeight(0) : null,
          ),
          child: buttonContent,
        );
    }
  }
} 