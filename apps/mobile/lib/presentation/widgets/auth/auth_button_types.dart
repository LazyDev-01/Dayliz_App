import 'package:flutter/material.dart';

/// Authentication button types and enums
/// Shared across all authentication screens

/// Enum for auth button priority styling
enum AuthButtonPriority {
  primary,
  secondary,
  tertiary,
}

/// Auth button configuration class
class AuthButtonConfig {
  final String text;
  final AuthButtonPriority priority;
  final bool isLoading;
  final VoidCallback? onPressed;

  const AuthButtonConfig({
    required this.text,
    required this.priority,
    this.isLoading = false,
    this.onPressed,
  });
}

/// Social auth provider types
enum SocialAuthProvider {
  google,
  facebook,
  apple,
  phone,
  email,
}

/// Auth screen types
enum AuthScreenType {
  login,
  signup,
  phoneAuth,
  otpVerification,
  forgotPassword,
}
