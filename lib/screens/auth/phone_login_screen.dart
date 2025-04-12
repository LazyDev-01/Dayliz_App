import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dayliz_app/providers/auth_provider.dart';
import 'package:dayliz_app/theme/app_theme.dart';
import 'package:dayliz_app/theme/app_spacing.dart';
import 'package:dayliz_app/utils/validators.dart';
import 'package:dayliz_app/widgets/buttons/dayliz_button.dart';
import 'package:dayliz_app/widgets/inputs/dayliz_text_field.dart';

class PhoneLoginScreen extends ConsumerStatefulWidget {
  const PhoneLoginScreen({Key? key}) : super(key: key);

  @override
  PhoneLoginScreenState createState() => PhoneLoginScreenState();
}

class PhoneLoginScreenState extends ConsumerState<PhoneLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final phoneNumber = _formatPhoneNumber(_phoneController.text.trim());
      await ref.read(authNotifierProvider.notifier).sendOtp(
        phone: phoneNumber,
      );
      
      if (!mounted) return;
      
      // Navigate to OTP verification screen
      context.push(
        '/auth/verify-otp',
        extra: {'phone': phoneNumber},
      );
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _errorMessage = _formatErrorMessage(e.toString());
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatPhoneNumber(String phone) {
    // Format phone number to international format (required by Supabase)
    // Remove any non-digit characters
    String digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    // If the number doesn't start with a country code, add Indian country code
    if (!digits.startsWith('91') && digits.length == 10) {
      return '+91$digits';
    } else if (!digits.startsWith('+')) {
      return '+$digits';
    }
    
    return phone;
  }

  String _formatErrorMessage(String error) {
    // Format Supabase error messages for better user experience
    if (error.contains('rate limit')) {
      return 'Too many attempts. Please try again later';
    } else if (error.contains('Invalid phone')) {
      return 'Please enter a valid phone number';
    } else {
      return 'Failed to send verification code. Please try again';
    }
  }

  void _navigateToEmailLogin() {
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingLG,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppSpacing.vXL,
                // App Logo
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.local_grocery_store,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                ),
                AppSpacing.vLG,
                Text(
                  'Phone Verification',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displaySmall,
                ),
                AppSpacing.vXS,
                Text(
                  'We\'ll send a verification code to your phone',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                AppSpacing.vXL,
                
                // Error message
                if (_errorMessage != null) ...[
                  Container(
                    padding: AppSpacing.paddingMD,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: theme.colorScheme.error,
                        ),
                        AppSpacing.hSM,
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.vMD,
                ],
                
                // Phone field
                DaylizTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  hint: 'Enter your phone number',
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  prefixIcon: Icons.phone_android,
                  validator: Validators.phone,
                  errorText: null, // Will be handled by the form validator
                ),
                AppSpacing.vLG,
                
                // Send OTP button
                DaylizButton(
                  onPressed: _isLoading ? null : _sendOtp,
                  text: 'Send Verification Code',
                  isLoading: _isLoading,
                ),
                AppSpacing.vMD,
                
                // Login with email
                Center(
                  child: TextButton(
                    onPressed: _navigateToEmailLogin,
                    child: Text(
                      'Login with Email Instead',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.primaryColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 