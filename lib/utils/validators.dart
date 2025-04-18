/// A utility class for form validation functions.
class Validators {
  /// Validates an email address.
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an email address';
    }
    
    // Simple regex for email validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }
  
  /// Validates a password.
  static String? password(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    
    if (value.length < minLength) {
      return 'Password must be at least $minLength characters long';
    }
    
    return null;
  }
  
  /// Validates a required field.
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return 'Please enter ${fieldName ?? 'this field'}';
    }
    
    return null;
  }
  
  /// Validates a phone number specifically for Indian format.
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a phone number';
    }
    
    // Remove any spaces, dashes or other formatting characters
    final cleanedValue = value.replaceAll(RegExp(r'[\s-]'), '');
    
    // Check if it starts with +91 (optional) and has 10 digits after that
    // Or just 10 digits for Indian numbers without the country code
    final indianPhoneRegex = RegExp(r'^(\+91)?[6-9]\d{9}$');
    if (!indianPhoneRegex.hasMatch(cleanedValue)) {
      return 'Please enter a valid 10-digit Indian phone number';
    }
    
    return null;
  }
  
  /// Validates a name.
  static String? name(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a name';
    }
    
    if (value.length < 2) {
      return 'Name must be at least 2 characters long';
    }
    
    return null;
  }
  
  /// Validates an Indian postal code (PIN code).
  static String? postalCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a postal code';
    }
    
    // Indian PIN codes are exactly 6 digits
    final postalCodeRegex = RegExp(r'^\d{6}$');
    if (!postalCodeRegex.hasMatch(value)) {
      return 'Please enter a valid 6-digit PIN code';
    }
    
    return null;
  }
  
  /// Validates a confirmation field (e.g., password confirmation).
  static String? confirmField(String? value, String? originalValue, {String fieldName = 'Fields'}) {
    if (value == null || value.isEmpty) {
      return 'Please confirm ${fieldName.toLowerCase()}';
    }
    
    if (value != originalValue) {
      return '$fieldName do not match';
    }
    
    return null;
  }
} 