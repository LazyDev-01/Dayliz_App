import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/app_colors.dart';

/// Unified Validation System for all forms in Dayliz App
class UnifiedValidationSystem {
  
  /// Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }
  
  /// Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    
    // Check for at least one uppercase letter
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    
    // Check for at least one lowercase letter
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }
    
    // Check for at least one digit
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    
    // Check for at least one special character
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Password must contain at least one special character';
    }
    
    return null;
  }
  
  /// Phone number validation
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    
    // Remove all non-digit characters
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
    
    // Check for Indian phone number format (10 digits)
    if (digitsOnly.length == 10) {
      // Must start with 6, 7, 8, or 9
      if (!RegExp(r'^[6-9]').hasMatch(digitsOnly)) {
        return 'Please enter a valid Indian phone number';
      }
      return null;
    }
    
    // Check for international format with country code
    if (digitsOnly.length == 12 && digitsOnly.startsWith('91')) {
      final phoneNumber = digitsOnly.substring(2);
      if (!RegExp(r'^[6-9]').hasMatch(phoneNumber)) {
        return 'Please enter a valid Indian phone number';
      }
      return null;
    }
    
    return 'Please enter a valid phone number (10 digits)';
  }
  
  /// Name validation
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters long';
    }
    
    if (value.trim().length > 50) {
      return 'Name must be less than 50 characters';
    }
    
    // Check for valid characters (letters, spaces, hyphens, apostrophes)
    if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(value.trim())) {
      return 'Name can only contain letters, spaces, hyphens, and apostrophes';
    }
    
    return null;
  }
  
  /// Address validation
  static String? validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'Address is required';
    }
    
    if (value.trim().length < 10) {
      return 'Please enter a complete address (at least 10 characters)';
    }
    
    if (value.trim().length > 200) {
      return 'Address must be less than 200 characters';
    }
    
    return null;
  }
  
  /// Postal code validation (Indian PIN codes)
  static String? validatePostalCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'PIN code is required';
    }
    
    // Indian PIN code format: 6 digits
    if (!RegExp(r'^\d{6}$').hasMatch(value)) {
      return 'Please enter a valid 6-digit PIN code';
    }
    
    return null;
  }
  
  /// Required field validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
  
  /// Confirm password validation
  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != password) {
      return 'Passwords do not match';
    }
    
    return null;
  }
  
  /// Amount validation
  static String? validateAmount(String? value, {double? minAmount, double? maxAmount}) {
    if (value == null || value.isEmpty) {
      return 'Amount is required';
    }
    
    final amount = double.tryParse(value);
    if (amount == null) {
      return 'Please enter a valid amount';
    }
    
    if (amount <= 0) {
      return 'Amount must be greater than zero';
    }
    
    if (minAmount != null && amount < minAmount) {
      return 'Minimum amount is ₹${minAmount.toStringAsFixed(0)}';
    }
    
    if (maxAmount != null && amount > maxAmount) {
      return 'Maximum amount is ₹${maxAmount.toStringAsFixed(0)}';
    }
    
    return null;
  }
}

/// Universal Validation Error Display Widget
class ValidationErrorDisplay extends StatelessWidget {
  final String? errorMessage;
  final bool isVisible;
  
  const ValidationErrorDisplay({
    Key? key,
    this.errorMessage,
    this.isVisible = true,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    if (!isVisible || errorMessage == null || errorMessage!.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: 4.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(
          color: Colors.red[200]!,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline,
            size: 16.sp,
            color: Colors.red[600],
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              errorMessage!,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.red[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Universal Form Field with built-in validation
class UniversalFormField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconTap;
  final TextInputType keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool enabled;
  final int? maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final bool showValidationError;
  
  const UniversalFormField({
    Key? key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconTap,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.validator,
    this.onChanged,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
    this.showValidationError = true,
  }) : super(key: key);
  
  @override
  State<UniversalFormField> createState() => _UniversalFormFieldState();
}

class _UniversalFormFieldState extends State<UniversalFormField> {
  String? _errorMessage;
  bool _hasBeenTouched = false;
  
  void _validateField() {
    if (widget.validator != null && _hasBeenTouched) {
      setState(() {
        _errorMessage = widget.validator!(widget.controller.text);
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final hasError = _errorMessage != null && _errorMessage!.isNotEmpty;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          obscureText: widget.obscureText,
          enabled: widget.enabled,
          maxLines: widget.maxLines,
          maxLength: widget.maxLength,
          inputFormatters: widget.inputFormatters,
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            prefixIcon: widget.prefixIcon != null 
                ? Icon(widget.prefixIcon, size: 20.sp)
                : null,
            suffixIcon: widget.suffixIcon != null
                ? GestureDetector(
                    onTap: widget.onSuffixIconTap,
                    child: Icon(widget.suffixIcon, size: 20.sp),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: Colors.red[400]!, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: Colors.red[400]!, width: 2),
            ),
            filled: true,
            fillColor: widget.enabled ? Colors.white : Colors.grey[100],
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            // Hide default error text
            errorStyle: const TextStyle(height: 0, fontSize: 0),
          ),
          onChanged: (value) {
            if (!_hasBeenTouched) {
              setState(() {
                _hasBeenTouched = true;
              });
            }
            _validateField();
            widget.onChanged?.call(value);
          },
          onTap: () {
            if (!_hasBeenTouched) {
              setState(() {
                _hasBeenTouched = true;
              });
            }
          },
          // Remove validator to prevent default error display
          validator: null,
        ),
        
        // Custom validation error display
        if (widget.showValidationError)
          ValidationErrorDisplay(
            errorMessage: _errorMessage,
            isVisible: hasError,
          ),
      ],
    );
  }
}
