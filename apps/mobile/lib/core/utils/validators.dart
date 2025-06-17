/// Validation utilities for form inputs
/// Contains common validation functions used across the app

/// Email validation helper function
bool isValidEmail(String email) {
  return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
}

/// Password validation helper function
bool isValidPassword(String password) {
  return password.length >= 6;
}

/// Phone number validation helper function
bool isValidPhoneNumber(String phoneNumber) {
  // Remove all non-digit characters
  final digitsOnly = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
  
  // Check if it has at least 10 digits (minimum for most countries)
  return digitsOnly.length >= 10;
}

/// Name validation helper function
bool isValidName(String name) {
  return name.trim().length >= 2;
}

/// OTP validation helper function
bool isValidOTP(String otp) {
  // Check if it's exactly 6 digits
  return RegExp(r'^\d{6}$').hasMatch(otp);
}

/// Generic required field validation
bool isRequired(String? value) {
  return value != null && value.trim().isNotEmpty;
}

/// URL validation helper function
bool isValidUrl(String url) {
  try {
    final uri = Uri.parse(url);
    return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
  } catch (e) {
    return false;
  }
}

/// Credit card number validation (basic Luhn algorithm)
bool isValidCreditCard(String cardNumber) {
  // Remove all non-digit characters
  final digitsOnly = cardNumber.replaceAll(RegExp(r'[^\d]'), '');
  
  if (digitsOnly.length < 13 || digitsOnly.length > 19) {
    return false;
  }
  
  // Luhn algorithm
  int sum = 0;
  bool alternate = false;
  
  for (int i = digitsOnly.length - 1; i >= 0; i--) {
    int digit = int.parse(digitsOnly[i]);
    
    if (alternate) {
      digit *= 2;
      if (digit > 9) {
        digit = (digit % 10) + 1;
      }
    }
    
    sum += digit;
    alternate = !alternate;
  }
  
  return sum % 10 == 0;
}

/// CVV validation helper function
bool isValidCVV(String cvv) {
  return RegExp(r'^\d{3,4}$').hasMatch(cvv);
}

/// Postal code validation helper function
bool isValidPostalCode(String postalCode) {
  // Basic validation - at least 3 characters
  return postalCode.trim().length >= 3;
}
