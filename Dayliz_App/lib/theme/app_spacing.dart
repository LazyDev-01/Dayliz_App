import 'package:flutter/material.dart';
import 'package:dayliz_app/theme/app_theme.dart';

/// Spacing utility class that provides consistent spacing throughout the app.
class AppSpacing {
  // Vertical spacers
  static const SizedBox vXS = SizedBox(height: 4);
  static const SizedBox vSM = SizedBox(height: 8);
  static const SizedBox vMD = SizedBox(height: 16);
  static const SizedBox vLG = SizedBox(height: 24);
  static const SizedBox vXL = SizedBox(height: 32);
  static const SizedBox vXXL = SizedBox(height: 48);

  // Horizontal spacers
  static const SizedBox hXS = SizedBox(width: 4);
  static const SizedBox hSM = SizedBox(width: 8);
  static const SizedBox hMD = SizedBox(width: 16);
  static const SizedBox hLG = SizedBox(width: 24);
  static const SizedBox hXL = SizedBox(width: 32);
  static const SizedBox hXXL = SizedBox(width: 48);

  // Padding values
  static const EdgeInsets paddingXS = EdgeInsets.all(4);
  static const EdgeInsets paddingSM = EdgeInsets.all(8);
  static const EdgeInsets paddingMD = EdgeInsets.all(16);
  static const EdgeInsets paddingLG = EdgeInsets.all(24);
  static const EdgeInsets paddingXL = EdgeInsets.all(32);
  static const EdgeInsets paddingXXL = EdgeInsets.all(48);

  // Horizontal padding values
  static const EdgeInsets paddingHXS = EdgeInsets.symmetric(horizontal: 4);
  static const EdgeInsets paddingHSM = EdgeInsets.symmetric(horizontal: 8);
  static const EdgeInsets paddingHMD = EdgeInsets.symmetric(horizontal: 16);
  static const EdgeInsets paddingHLG = EdgeInsets.symmetric(horizontal: 24);
  static const EdgeInsets paddingHXL = EdgeInsets.symmetric(horizontal: 32);
  static const EdgeInsets paddingHXXL = EdgeInsets.symmetric(horizontal: 48);

  // Vertical padding values
  static const EdgeInsets paddingVXS = EdgeInsets.symmetric(vertical: 4);
  static const EdgeInsets paddingVSM = EdgeInsets.symmetric(vertical: 8);
  static const EdgeInsets paddingVMD = EdgeInsets.symmetric(vertical: 16);
  static const EdgeInsets paddingVLG = EdgeInsets.symmetric(vertical: 24);
  static const EdgeInsets paddingVXL = EdgeInsets.symmetric(vertical: 32);
  static const EdgeInsets paddingVXXL = EdgeInsets.symmetric(vertical: 48);

  // Get spacing from theme extension (dynamic approach)
  static double getSpacing(BuildContext context, String size) {
    final theme = Theme.of(context).extension<DaylizThemeExtension>();
    if (theme == null) {
      // Fallback values if theme extension is not available
      switch (size) {
        case 'xs':
          return 4.0;
        case 'sm':
          return 8.0;
        case 'md':
          return 16.0;
        case 'lg':
          return 24.0;
        case 'xl':
          return 32.0;
        case 'xxl':
          return 48.0;
        default:
          return 16.0;
      }
    }
    return theme.spacing[size] ?? 16.0;
  }

  // Create a SizedBox with dynamic height from theme
  static SizedBox vSpace(BuildContext context, String size) {
    return SizedBox(height: getSpacing(context, size));
  }

  // Create a SizedBox with dynamic width from theme
  static SizedBox hSpace(BuildContext context, String size) {
    return SizedBox(width: getSpacing(context, size));
  }

  // Create EdgeInsets with dynamic padding from theme
  static EdgeInsets padding(BuildContext context, String size) {
    final value = getSpacing(context, size);
    return EdgeInsets.all(value);
  }

  // Create EdgeInsets with dynamic horizontal padding from theme
  static EdgeInsets paddingH(BuildContext context, String size) {
    final value = getSpacing(context, size);
    return EdgeInsets.symmetric(horizontal: value);
  }

  // Create EdgeInsets with dynamic vertical padding from theme
  static EdgeInsets paddingV(BuildContext context, String size) {
    final value = getSpacing(context, size);
    return EdgeInsets.symmetric(vertical: value);
  }
} 