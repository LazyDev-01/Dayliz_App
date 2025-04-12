import 'package:flutter/material.dart';
import 'package:dayliz_app/theme/dayliz_theme.dart';

enum DaylizButtonType {
  primary,
  secondary,
  outlined,
  text
}

enum DaylizButtonSize {
  small,
  medium,
  large
}

class DaylizButton extends StatelessWidget {
  final String? text;
  final String? label;
  final VoidCallback? onPressed;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final DaylizButtonType type;
  final DaylizButtonSize size;
  final bool loading;
  final bool fullWidth;
  final double? borderRadius;
  
  const DaylizButton({
    Key? key,
    this.text,
    this.label,
    required this.onPressed,
    this.leadingIcon,
    this.trailingIcon,
    this.type = DaylizButtonType.primary,
    this.size = DaylizButtonSize.medium,
    this.loading = false,
    this.fullWidth = false,
    this.borderRadius,
  }) : assert(text != null || label != null, 'Either text or label must be provided'),
       super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonText = text ?? label ?? '';
    
    // Determine button style based on type
    ButtonStyle getButtonStyle() {
      switch (type) {
        case DaylizButtonType.primary:
          return ElevatedButton.styleFrom(
            foregroundColor: theme.colorScheme.onPrimary,
            backgroundColor: theme.colorScheme.primary,
            disabledForegroundColor: Colors.grey.withOpacity(0.38),
            disabledBackgroundColor: Colors.grey.withOpacity(0.12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? 8),
            ),
            padding: _getPadding(),
          );
        case DaylizButtonType.secondary:
          return ElevatedButton.styleFrom(
            foregroundColor: theme.colorScheme.primary,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            disabledForegroundColor: Colors.grey.withOpacity(0.38),
            disabledBackgroundColor: Colors.grey.withOpacity(0.12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? 8),
            ),
            padding: _getPadding(),
          );
        case DaylizButtonType.outlined:
          return OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.primary,
            side: BorderSide(color: theme.colorScheme.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? 8),
            ),
            padding: _getPadding(),
          );
        case DaylizButtonType.text:
          return TextButton.styleFrom(
            foregroundColor: theme.colorScheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? 8),
            ),
            padding: _getPadding(),
          );
      }
    }
    
    // Button content based on loading state and icons
    Widget buttonChild = loading 
      ? SizedBox(
          height: _getIconSize(),
          width: _getIconSize(),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              type == DaylizButtonType.primary 
                ? theme.colorScheme.onPrimary 
                : theme.colorScheme.primary
            ),
          ),
        )
      : Row(
          mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leadingIcon != null) ...[
              Icon(leadingIcon, size: _getIconSize()),
              SizedBox(width: 8),
            ],
            Text(
              buttonText,
              style: _getTextStyle(theme),
            ),
            if (trailingIcon != null) ...[
              SizedBox(width: 8),
              Icon(trailingIcon, size: _getIconSize()),
            ],
          ],
        );
        
    // Determine the button widget based on type
    Widget buttonWidget;
    switch (type) {
      case DaylizButtonType.primary:
      case DaylizButtonType.secondary:
        buttonWidget = ElevatedButton(
          onPressed: loading ? null : onPressed,
          style: getButtonStyle(),
          child: buttonChild,
        );
        break;
      case DaylizButtonType.outlined:
        buttonWidget = OutlinedButton(
          onPressed: loading ? null : onPressed,
          style: getButtonStyle(),
          child: buttonChild,
        );
        break;
      case DaylizButtonType.text:
        buttonWidget = TextButton(
          onPressed: loading ? null : onPressed,
          style: getButtonStyle(),
          child: buttonChild,
        );
        break;
    }
    
    return fullWidth 
      ? SizedBox(width: double.infinity, child: buttonWidget) 
      : buttonWidget;
  }
  
  // Helper methods for sizing
  EdgeInsetsGeometry _getPadding() {
    switch (size) {
      case DaylizButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      case DaylizButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
      case DaylizButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    }
  }
  
  double _getIconSize() {
    switch (size) {
      case DaylizButtonSize.small:
        return 16;
      case DaylizButtonSize.medium:
        return 20;
      case DaylizButtonSize.large:
        return 24;
    }
  }
  
  TextStyle? _getTextStyle(ThemeData theme) {
    switch (size) {
      case DaylizButtonSize.small:
        return theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w500,
        );
      case DaylizButtonSize.medium:
        return theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w500,
        );
      case DaylizButtonSize.large:
        return theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
        );
    }
  }
} 