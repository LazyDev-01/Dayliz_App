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
  
  /// Validates a phone number.
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a phone number';
    }
    
    // Simple regex for phone validation (allow +, digits, spaces, and dashes)
    final phoneRegex = RegExp(r'^\+?[\d\s-]{10,15}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Please enter a valid phone number';
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
  
  /// Validates a postal code/ZIP code.
  static String? postalCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a postal code';
    }
    
    // Simple regex for postal code validation (5-6 digits, can include letters for some countries)
    final postalCodeRegex = RegExp(r'^[a-zA-Z0-9]{5,7}$');
    if (!postalCodeRegex.hasMatch(value)) {
      return 'Please enter a valid postal code';
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