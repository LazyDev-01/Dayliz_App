import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dayliz_app/providers/auth_provider.dart';
import 'package:dayliz_app/theme/app_theme.dart';
import 'package:dayliz_app/theme/app_spacing.dart';
import 'package:dayliz_app/utils/validators.dart';
import 'package:dayliz_app/widgets/buttons/dayliz_button.dart';
import 'package:dayliz_app/widgets/inputs/dayliz_text_field.dart';

enum PhoneOtpScreenMode {
  requestOtp,
  verifyOtp,
}

class PhoneOtpScreen extends ConsumerStatefulWidget {
  const PhoneOtpScreen({
    Key? key,
    this.initialPhone,
    this.onSuccess,
  }) : super(key: key);

  final String? initialPhone;
  final Function(String)? onSuccess;

  @override
  PhoneOtpScreenState createState() => PhoneOtpScreenState();
}

class PhoneOtpScreenState extends ConsumerState<PhoneOtpScreen> {
  final _phoneFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  
  PhoneOtpScreenMode _mode = PhoneOtpScreenMode.requestOtp;
  bool _isLoading = false;
  String? _errorMessage;
  String? _phone;
  
  @override
  void initState() {
    super.initState();
    if (widget.initialPhone != null) {
      _phoneController.text = widget.initialPhone!;
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    if (!_phoneFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final phone = _formatPhoneNumber(_phoneController.text.trim());
      
      try {
        // Try to send OTP through Supabase
        await ref.read(authNotifierProvider.notifier).sendOtp(
          phone: phone,
        );
      } catch (supabaseError) {
        // If phone provider is disabled, just move to the next screen in mock mode
        debugPrint('⚠️ Using mock OTP mode due to error: $supabaseError');
        if (supabaseError.toString().contains('phone_provider_disabled')) {
          // No need to show an error, just continue with mock mode
        } else {
          // For other errors, re-throw
          rethrow;
        }
      }
      
      if (!mounted) return;
      
      setState(() {
        _mode = PhoneOtpScreenMode.verifyOtp;
        _phone = phone;
      });
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

  Future<void> _verifyOtp() async {
    if (!_otpFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // For testing purposes, allow 123456 as a valid verification code
      final otpCode = _otpController.text.trim();
      
      if (otpCode == "123456") {
        // If using the test code, simulate successful verification
        debugPrint('✅ Mock OTP verification successful for $_phone with test code');
        
        // Simulate a delay for better UX
        await Future.delayed(const Duration(seconds: 1));
        
        if (!mounted) return;
        
        // Navigate to home screen
        context.go('/home');
        return;
      }
      
      // Otherwise try real verification 
      final result = await ref.read(authNotifierProvider.notifier).verifyOtp(
        phone: _phone!,
        token: otpCode,
      );
      
      if (!mounted) return;
      
      if (widget.onSuccess != null) {
        widget.onSuccess!(_phone!);
      } else {
        // Navigation will be handled by the router's redirect to the home screen
      }
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
    // Remove spaces, dashes, and other non-digit characters
    String digits = phone.replaceAll(RegExp(r'\D'), '');
    
    // If no country code, add +91 (for India)
    if (!digits.startsWith('+')) {
      if (digits.startsWith('91')) {
        digits = '+$digits';
      } else {
        digits = '+91$digits';
      }
    }
    
    return digits;
  }

  String _formatErrorMessage(String error) {
    if (error.contains('rate limit')) {
      return 'Too many attempts. Please try again later';
    } else if (error.contains('verification code')) {
      return 'Invalid verification code. Please try again';
    } else if (error.contains('phone number')) {
      return 'Invalid phone number format';
    } else {
      return 'Verification failed. Please try again';
    }
  }

  void _goBack() {
    if (_mode == PhoneOtpScreenMode.verifyOtp) {
      setState(() {
        _mode = PhoneOtpScreenMode.requestOtp;
        _errorMessage = null;
      });
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_mode == PhoneOtpScreenMode.requestOtp 
            ? 'Phone Verification' 
            : 'Verify OTP'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBack,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingLG,
          child: _mode == PhoneOtpScreenMode.requestOtp
              ? _buildPhoneForm(theme)
              : _buildOtpForm(theme),
        ),
      ),
    );
  }

  Widget _buildPhoneForm(ThemeData theme) {
    return Form(
      key: _phoneFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.vLG,
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
                Icons.phone_android,
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
            'We\'ll send you a one-time password to verify your phone number',
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
            prefixIcon: Icons.phone,
            validator: Validators.phone,
            errorText: null, // Will be handled by the form validator
          ),
          AppSpacing.vLG,
          
          // Send OTP button
          DaylizButton(
            label: 'Send OTP',
            onPressed: _isLoading ? null : _requestOtp,
            isLoading: _isLoading,
            type: DaylizButtonType.primary,
            size: DaylizButtonSize.large,
            isFullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildOtpForm(ThemeData theme) {
    return Form(
      key: _otpFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.vLG,
          // OTP Icon
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline,
                size: 50,
                color: Colors.white,
              ),
            ),
          ),
          AppSpacing.vLG,
          Text(
            'Enter Verification Code',
            textAlign: TextAlign.center,
            style: theme.textTheme.displaySmall,
          ),
          AppSpacing.vXS,
          Text(
            'We\'ve sent a 6-digit code to ${_phone ?? "your phone number"}',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
          // Add testing note
          AppSpacing.vXS,
          Text(
            'For testing, use code: 123456 (always works)',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
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
          
          // OTP field
          DaylizTextField(
            controller: _otpController,
            label: 'Verification Code',
            hint: 'Enter 6-digit code',
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            prefixIcon: Icons.sms_outlined,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the verification code';
              }
              if (value.length != 6 || int.tryParse(value) == null) {
                return 'Please enter a valid 6-digit code';
              }
              return null;
            },
            errorText: null, // Will be handled by the form validator
          ),
          AppSpacing.vLG,
          
          // Verify OTP button
          DaylizButton(
            label: 'Verify',
            onPressed: _isLoading ? null : _verifyOtp,
            isLoading: _isLoading,
            type: DaylizButtonType.primary,
            size: DaylizButtonSize.large,
            isFullWidth: true,
          ),
          AppSpacing.vMD,
          
          // Resend OTP
          TextButton.icon(
            onPressed: _isLoading ? null : _requestOtp,
            icon: const Icon(Icons.refresh),
            label: const Text('Resend Code'),
          ),
        ],
      ),
    );
  }
} 