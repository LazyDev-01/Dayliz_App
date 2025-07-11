import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  final String? label;
  final String? text; // Alternative to label for backward compatibility
  final VoidCallback? onPressed;
  final DaylizButtonType type;
  final DaylizButtonSize size;
  final bool isFullWidth;
  final bool isLoading;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final IconData? icon; // Alternative to leadingIcon
  final bool enableHapticFeedback;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;

  const DaylizButton({
    Key? key,
    this.label,
    this.text,
    this.onPressed,
    this.type = DaylizButtonType.primary,
    this.size = DaylizButtonSize.medium,
    this.isFullWidth = true, // Default to full width for better UX
    this.isLoading = false,
    this.leadingIcon,
    this.trailingIcon,
    this.icon,
    this.enableHapticFeedback = true,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Handle tap with haptic feedback
    void handleTap() {
      if (enableHapticFeedback) {
        HapticFeedback.lightImpact();
      }
      onPressed?.call();
    }

    // Size configurations
    EdgeInsetsGeometry buttonPadding;
    double fontSize;
    double iconSize;

    switch (size) {
      case DaylizButtonSize.small:
        buttonPadding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
        fontSize = 14;
        iconSize = 16;
        break;
      case DaylizButtonSize.medium:
        buttonPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
        fontSize = 16;
        iconSize = 18;
        break;
      case DaylizButtonSize.large:
        buttonPadding = const EdgeInsets.symmetric(horizontal: 20, vertical: 16);
        fontSize = 18;
        iconSize = 20;
        break;
    }

    // Get the display text
    final displayText = text ?? label ?? '';

    // Get the display icon
    final displayIcon = icon ?? leadingIcon;

    // Button content
    Widget buttonContent = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (displayIcon != null && !isLoading) ...[
          Icon(displayIcon, size: iconSize),
          const SizedBox(width: 8),
        ],
        if (isLoading)
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                textColor ?? (type == DaylizButtonType.primary
                    ? Colors.white
                    : theme.primaryColor),
              ),
            ),
          ),
        if (isLoading) const SizedBox(width: 8),
        Text(
          displayText,
          style: theme.textTheme.labelLarge?.copyWith(
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
        if (trailingIcon != null && !isLoading) ...[
          const SizedBox(width: 8),
          Icon(trailingIcon, size: iconSize),
        ],
      ],
    );

    // Determine colors based on custom colors or type
    final effectiveBackgroundColor = backgroundColor ??
        (type == DaylizButtonType.primary ? theme.primaryColor : null);
    final effectiveForegroundColor = textColor ??
        (type == DaylizButtonType.primary ? Colors.white : theme.primaryColor);
    final effectiveBorderColor = borderColor ?? effectiveForegroundColor;

    // Apply button style based on type
    switch (type) {
      case DaylizButtonType.primary:
        return ElevatedButton(
          onPressed: isLoading ? null : handleTap,
          style: ElevatedButton.styleFrom(
            padding: buttonPadding,
            backgroundColor: effectiveBackgroundColor,
            foregroundColor: effectiveForegroundColor,
            disabledBackgroundColor: effectiveBackgroundColor?.withValues(alpha: 0.5),
            disabledForegroundColor: effectiveForegroundColor.withValues(alpha: 0.7),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: isFullWidth ? const Size.fromHeight(48) : null,
          ),
          child: buttonContent,
        );

      case DaylizButtonType.secondary:
        return OutlinedButton(
          onPressed: isLoading ? null : handleTap,
          style: OutlinedButton.styleFrom(
            padding: buttonPadding,
            backgroundColor: backgroundColor,
            foregroundColor: effectiveForegroundColor,
            side: BorderSide(
              color: isLoading ? effectiveBorderColor.withValues(alpha: 0.5) : effectiveBorderColor,
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: isFullWidth ? const Size.fromHeight(48) : null,
          ),
          child: buttonContent,
        );

      case DaylizButtonType.tertiary:
        return OutlinedButton(
          onPressed: isLoading ? null : handleTap,
          style: OutlinedButton.styleFrom(
            padding: buttonPadding,
            foregroundColor: theme.colorScheme.secondary,
            backgroundColor: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
            side: BorderSide(
              color: isLoading ? theme.colorScheme.secondary.withValues(alpha: 0.5) : theme.colorScheme.secondary,
              width: 1.0,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
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
            disabledBackgroundColor: theme.colorScheme.error.withValues(alpha: 0.5),
            disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
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
              borderRadius: BorderRadius.circular(8),
            ),
            minimumSize: isFullWidth ? const Size.fromHeight(0) : null,
          ),
          child: buttonContent,
        );
    }
  }
}