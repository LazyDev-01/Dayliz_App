import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dayliz_app/theme/app_theme.dart';

enum DaylizCardElevation {
  none,
  low,
  medium,
  high,
}

class DaylizCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;
  final DaylizCardElevation elevation;
  final bool enableHapticFeedback;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final bool hasBorder;
  final Color? borderColor;
  final Clip clipBehavior;

  const DaylizCard({
    Key? key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.width,
    this.height,
    this.elevation = DaylizCardElevation.low,
    this.enableHapticFeedback = true,
    this.backgroundColor,
    this.borderRadius,
    this.hasBorder = false,
    this.borderColor,
    this.clipBehavior = Clip.none,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daylizTheme = theme.extension<DaylizThemeExtension>();
    
    final cardBorderRadius = borderRadius ?? 
        daylizTheme?.cardBorderRadius ?? 
        BorderRadius.circular(12);
    
    // Convert elevation enum to actual elevation value
    double elevationValue;
    switch (elevation) {
      case DaylizCardElevation.none:
        elevationValue = 0;
        break;
      case DaylizCardElevation.low:
        elevationValue = 1;
        break;
      case DaylizCardElevation.high:
        elevationValue = 8;
        break;
      case DaylizCardElevation.medium:
      default:
        elevationValue = 4;
    }
    
    // Determine background color
    final Color cardBackgroundColor = backgroundColor ?? 
        daylizTheme?.cardBackground ?? 
        theme.cardTheme.color ?? 
        theme.colorScheme.surface;
    
    // Build card widget
    Widget cardWidget = Material(
      color: cardBackgroundColor,
      elevation: elevationValue,
      borderRadius: cardBorderRadius,
      clipBehavior: clipBehavior,
      child: Container(
        width: width,
        height: height,
        padding: padding,
        decoration: hasBorder ? BoxDecoration(
          border: Border.all(
            color: borderColor ?? theme.dividerColor,
            width: 1,
          ),
          borderRadius: cardBorderRadius,
        ) : null,
        child: child,
      ),
    );
    
    // Add tap behavior if needed
    if (onTap != null) {
      return InkWell(
        onTap: () {
          if (enableHapticFeedback) {
            HapticFeedback.lightImpact();
          }
          onTap!();
        },
        borderRadius: cardBorderRadius,
        child: cardWidget,
      );
    }
    
    return cardWidget;
  }
} 