import 'package:flutter/material.dart';

/// Constants for standard spacing values
class AppSpacing {
  // Horizontal spacing
  static const SizedBox hXS = SizedBox(width: 4);
  static const SizedBox hSM = SizedBox(width: 8);
  static const SizedBox hMD = SizedBox(width: 16);
  static const SizedBox hLG = SizedBox(width: 24);
  static const SizedBox hXL = SizedBox(width: 32);

  // Vertical spacing
  static const SizedBox vXS = SizedBox(height: 4);
  static const SizedBox vSM = SizedBox(height: 8);
  static const SizedBox vMD = SizedBox(height: 16);
  static const SizedBox vLG = SizedBox(height: 24);
  static const SizedBox vXL = SizedBox(height: 32);

  // Paddings
  static const EdgeInsets paddingXS = EdgeInsets.all(4);
  static const EdgeInsets paddingSM = EdgeInsets.all(8);
  static const EdgeInsets paddingMD = EdgeInsets.all(16);
  static const EdgeInsets paddingLG = EdgeInsets.all(24);
  static const EdgeInsets paddingXL = EdgeInsets.all(32);

  // Vertical only padding
  static const EdgeInsets paddingVXS = EdgeInsets.symmetric(vertical: 4);
  static const EdgeInsets paddingVSM = EdgeInsets.symmetric(vertical: 8);
  static const EdgeInsets paddingVMD = EdgeInsets.symmetric(vertical: 16);
  static const EdgeInsets paddingVLG = EdgeInsets.symmetric(vertical: 24);
  static const EdgeInsets paddingVXL = EdgeInsets.symmetric(vertical: 32);

  // Horizontal only padding
  static const EdgeInsets paddingHXS = EdgeInsets.symmetric(horizontal: 4);
  static const EdgeInsets paddingHSM = EdgeInsets.symmetric(horizontal: 8);
  static const EdgeInsets paddingHMD = EdgeInsets.symmetric(horizontal: 16);
  static const EdgeInsets paddingHLG = EdgeInsets.symmetric(horizontal: 24);
  static const EdgeInsets paddingHXL = EdgeInsets.symmetric(horizontal: 32);
} 