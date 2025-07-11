import 'package:flutter/material.dart';
import '../../../core/services/haptic_service.dart';

/// Collection of wrapper widgets that automatically include haptic feedback
/// 
/// These widgets provide the same API as their Flutter counterparts
/// but automatically trigger appropriate haptic feedback on interaction.

// MARK: - HapticListTile

/// ListTile with automatic haptic feedback
/// 
/// Provides the same functionality as Flutter's ListTile but automatically
/// triggers haptic feedback when tapped. Perfect for settings screens,
/// navigation lists, and option menus.
class HapticListTile extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final bool isThreeLine;
  final bool? dense;
  final VisualDensity? visualDensity;
  final ShapeBorder? shape;
  final Color? selectedColor;
  final Color? iconColor;
  final Color? textColor;
  final EdgeInsetsGeometry? contentPadding;
  final bool enabled;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool selected;
  final Color? focusColor;
  final Color? hoverColor;
  final FocusNode? focusNode;
  final bool autofocus;
  final Color? tileColor;
  final Color? selectedTileColor;
  final bool? enableFeedback;
  final double? horizontalTitleGap;
  final double? minVerticalPadding;
  final double? minLeadingWidth;
  
  /// Type of haptic feedback to trigger
  final HapticType hapticType;

  const HapticListTile({
    Key? key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.isThreeLine = false,
    this.dense,
    this.visualDensity,
    this.shape,
    this.selectedColor,
    this.iconColor,
    this.textColor,
    this.contentPadding,
    this.enabled = true,
    this.onTap,
    this.onLongPress,
    this.selected = false,
    this.focusColor,
    this.hoverColor,
    this.focusNode,
    this.autofocus = false,
    this.tileColor,
    this.selectedTileColor,
    this.enableFeedback,
    this.horizontalTitleGap,
    this.minVerticalPadding,
    this.minLeadingWidth,
    this.hapticType = HapticType.light,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      isThreeLine: isThreeLine,
      dense: dense,
      visualDensity: visualDensity,
      shape: shape,
      selectedColor: selectedColor,
      iconColor: iconColor,
      textColor: textColor,
      contentPadding: contentPadding,
      enabled: enabled,
      onTap: onTap == null ? null : () {
        HapticService.smart(hapticType);
        onTap!();
      },
      onLongPress: onLongPress == null ? null : () {
        HapticService.medium(); // Long press gets medium feedback
        onLongPress!();
      },
      selected: selected,
      focusColor: focusColor,
      hoverColor: hoverColor,
      focusNode: focusNode,
      autofocus: autofocus,
      tileColor: tileColor,
      selectedTileColor: selectedTileColor,
      enableFeedback: enableFeedback,
      horizontalTitleGap: horizontalTitleGap,
      minVerticalPadding: minVerticalPadding,
      minLeadingWidth: minLeadingWidth,
    );
  }
}

// MARK: - HapticElevatedButton

/// ElevatedButton with automatic haptic feedback
class HapticElevatedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final Widget child;
  final ButtonStyle? style;
  final FocusNode? focusNode;
  final bool autofocus;
  final Clip clipBehavior;
  final HapticType hapticType;

  const HapticElevatedButton({
    Key? key,
    required this.onPressed,
    this.onLongPress,
    required this.child,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.clipBehavior = Clip.none,
    this.hapticType = HapticType.light,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed == null ? null : () {
        HapticService.smart(hapticType);
        onPressed!();
      },
      onLongPress: onLongPress == null ? null : () {
        HapticService.medium();
        onLongPress!();
      },
      style: style,
      focusNode: focusNode,
      autofocus: autofocus,
      clipBehavior: clipBehavior,
      child: child,
    );
  }
}

// MARK: - HapticIconButton

/// IconButton with automatic haptic feedback
class HapticIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget icon;
  final double? iconSize;
  final VisualDensity? visualDensity;
  final EdgeInsetsGeometry padding;
  final AlignmentGeometry alignment;
  final double? splashRadius;
  final Color? color;
  final Color? focusColor;
  final Color? hoverColor;
  final Color? highlightColor;
  final Color? splashColor;
  final Color? disabledColor;
  final MouseCursor? mouseCursor;
  final FocusNode? focusNode;
  final bool autofocus;
  final String? tooltip;
  final bool enableFeedback;
  final BoxConstraints? constraints;
  final HapticType hapticType;

  const HapticIconButton({
    Key? key,
    required this.onPressed,
    required this.icon,
    this.iconSize,
    this.visualDensity,
    this.padding = const EdgeInsets.all(8.0),
    this.alignment = Alignment.center,
    this.splashRadius,
    this.color,
    this.focusColor,
    this.hoverColor,
    this.highlightColor,
    this.splashColor,
    this.disabledColor,
    this.mouseCursor,
    this.focusNode,
    this.autofocus = false,
    this.tooltip,
    this.enableFeedback = true,
    this.constraints,
    this.hapticType = HapticType.light,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed == null ? null : () {
        HapticService.smart(hapticType);
        onPressed!();
      },
      icon: icon,
      iconSize: iconSize,
      visualDensity: visualDensity,
      padding: padding,
      alignment: alignment,
      splashRadius: splashRadius,
      color: color,
      focusColor: focusColor,
      hoverColor: hoverColor,
      highlightColor: highlightColor,
      splashColor: splashColor,
      disabledColor: disabledColor,
      mouseCursor: mouseCursor,
      focusNode: focusNode,
      autofocus: autofocus,
      tooltip: tooltip,
      enableFeedback: enableFeedback,
      constraints: constraints,
    );
  }
}

// MARK: - HapticInkWell

/// InkWell with automatic haptic feedback
class HapticInkWell extends StatelessWidget {
  final Widget? child;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onLongPress;
  final BorderRadius? borderRadius;
  final Color? splashColor;
  final Color? highlightColor;
  final HapticType hapticType;

  const HapticInkWell({
    Key? key,
    this.child,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.borderRadius,
    this.splashColor,
    this.highlightColor,
    this.hapticType = HapticType.light,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap == null ? null : () {
        HapticService.smart(hapticType);
        onTap!();
      },
      onDoubleTap: onDoubleTap == null ? null : () {
        HapticService.medium();
        onDoubleTap!();
      },
      onLongPress: onLongPress == null ? null : () {
        HapticService.medium();
        onLongPress!();
      },
      borderRadius: borderRadius,
      splashColor: splashColor,
      highlightColor: highlightColor,
      child: child,
    );
  }
}
