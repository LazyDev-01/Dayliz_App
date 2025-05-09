/// Validation utilities for form inputs
class Validators {
  /// Validates an email address
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email address';
    }

    if (!isValidEmail(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  /// Validates a password
  static String? validatePassword(String? value, {int minLength = 8}) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }

    if (value.length < minLength) {
      return 'Password must be at least $minLength characters';
    }

    // Check for lowercase letters
    bool hasLowercase = value.contains(RegExp(r'[a-z]'));
    if (!hasLowercase) {
      return 'Password must contain at least one lowercase letter';
    }

    // Check for uppercase letters
    bool hasUppercase = value.contains(RegExp(r'[A-Z]'));
    if (!hasUppercase) {
      return 'Password must contain at least one uppercase letter';
    }

    // Check for numbers
    bool hasNumber = value.contains(RegExp(r'[0-9]'));
    if (!hasNumber) {
      return 'Password must contain at least one number';
    }

    // Check for special characters
    bool hasSpecial = value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    if (!hasSpecial) {
      return 'Password must contain at least one special character';
    }

    // Provide an example of a valid password
    if (value.length < 10) {
      return 'For better security, use at least 10 characters (e.g., Test@123456)';
    }

    return null;
  }

  /// Validates a required field
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Please enter your $fieldName';
    }

    return null;
  }

  /// Validates a phone number
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }

    if (!isValidPhone(value)) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  /// Validates a name field
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your name';
    }

    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }

    return null;
  }

  /// Validates a confirmation password matches the original password
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != password) {
      return 'Passwords do not match';
    }

    return null;
  }
}

/// Checks if a string is a valid email address format
bool isValidEmail(String email) {
  return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
}

/// Checks if a string is a valid phone number format
bool isValidPhone(String phone) {
  // This is a basic validation pattern, you may want to replace with a more specific one
  return RegExp(r'^\+?[0-9]{10,15}$').hasMatch(phone);
}