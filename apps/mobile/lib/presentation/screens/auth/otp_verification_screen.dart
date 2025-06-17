import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

import '../../providers/auth_providers.dart';
import '../../providers/supabase_providers.dart';
import '../../widgets/auth/premium_auth_button.dart';
import '../../widgets/auth/auth_button_types.dart';
import '../../widgets/auth/auth_background.dart';

/// OTP verification screen for phone authentication
/// Handles 6-digit OTP input with auto-fill and resend functionality
class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  final String countryCode;

  const OtpVerificationScreen({
    Key? key,
    required this.phoneNumber,
    required this.countryCode,
  }) : super(key: key);

  @override
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen>
    with TickerProviderStateMixin {
  final _otpController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  String _otpCode = '';
  bool _isOtpComplete = false;
  int _resendTimer = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
    _startResendTimer();

    // Clear any previous errors
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(authNotifierProvider.notifier).clearErrors();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() {
          _resendTimer--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoading = ref.watch(authLoadingProvider);
    final errorMessage = ref.watch(authErrorProvider);

    return AuthBackground(
      showBackButton: true,
      onBackPressed: () => context.pop(),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),

                // Header Section
                _buildHeaderSection(theme),

                const SizedBox(height: 60),

                // OTP Input Section
                _buildOtpInputSection(theme),

                const SizedBox(height: 32),

                // Error Message
                if (errorMessage != null && errorMessage.isNotEmpty)
                  _buildErrorMessage(errorMessage, theme),

                const Spacer(),

                // Verify Button
                _buildVerifyButton(isLoading),

                const SizedBox(height: 20),

                // Resend Section
                _buildResendSection(theme),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(ThemeData theme) {
    return Column(
      children: [
        // Title
        Text(
          'Enter verification code',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 12),

        // Subtitle with phone number
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 16,
            ),
            children: [
              const TextSpan(text: 'We sent a 6-digit code to '),
              TextSpan(
                text: widget.phoneNumber,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOtpInputSection(ThemeData theme) {
    return Column(
      children: [
        // OTP Input Field
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: PinCodeTextField(
            appContext: context,
            length: 6,
            controller: _otpController,
            animationType: AnimationType.fade,
            animationDuration: const Duration(milliseconds: 300),
            enableActiveFill: true,
            keyboardType: TextInputType.number,
            textStyle: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            pinTheme: PinTheme(
              shape: PinCodeFieldShape.box,
              borderRadius: BorderRadius.circular(12),
              fieldHeight: 56,
              fieldWidth: 48,
              activeFillColor: Colors.white,
              inactiveFillColor: Colors.transparent, // Remove white background
              selectedFillColor: Colors.white,
              activeColor: Colors.white,
              inactiveColor: Colors.white.withValues(alpha: 0.3), // Subtle white border
              selectedColor: Colors.white,
              borderWidth: 2,
            ),
            backgroundColor: Colors.transparent, // Remove any background
            onChanged: (value) {
              setState(() {
                _otpCode = value;
                _isOtpComplete = value.length == 6;
              });

              // Auto-verify when complete
              if (value.length == 6) {
                _handleVerifyOtp();
              }
            },
            onCompleted: (value) {
              _handleVerifyOtp();
            },
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage(String message, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.shade600,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyButton(bool isLoading) {
    return PremiumAuthButton(
      onPressed: _isOtpComplete && !isLoading ? _handleVerifyOtp : null,
      icon: Icons.verified_user_outlined,
      text: 'Verify Code',
      backgroundColor: Colors.white,
      textColor: Theme.of(context).primaryColor,
      isLoading: isLoading,
      priority: AuthButtonPriority.primary,
      height: 48, // Reduced button height
    );
  }

  Widget _buildResendSection(ThemeData theme) {
    return Column(
      children: [
        // Resend Timer or Button
        if (_resendTimer > 0)
          Text(
            'Resend code in ${_resendTimer}s',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          )
        else
          TextButton(
            onPressed: _handleResendOtp,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Text(
              'Resend Code',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        
        const SizedBox(height: 16),
        
        // Change Number Option
        TextButton(
          onPressed: () => context.pop(),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: Text(
            'Change phone number',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
              decoration: TextDecoration.underline,
              decorationColor: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleVerifyOtp() async {
    if (_otpCode.length != 6) {
      return;
    }

    debugPrint('🔄 Verifying OTP: $_otpCode for ${widget.phoneNumber}');

    try {
      // Get Supabase client
      final supabase = ref.read(supabaseClientProvider);

      // Verify OTP using Supabase Auth
      final response = await supabase.auth.verifyOTP(
        phone: widget.phoneNumber,
        token: _otpCode,
        type: OtpType.sms,
      );

      if (response.user != null) {
        debugPrint('✅ OTP verified successfully for user: ${response.user!.id}');

        // Create user profile if this is a new user
        await _createUserProfileIfNeeded(response.user!);

        // Clear any errors and navigate to home
        ref.read(authNotifierProvider.notifier).clearErrors();

        // Navigate to home
        if (mounted) {
          context.go('/home');
        }
      } else {
        debugPrint('❌ OTP verification failed: No user returned');
        ref.read(authNotifierProvider.notifier).setValidationError('Verification failed. Please try again.');
      }
    } on AuthException catch (e) {
      debugPrint('❌ Supabase Auth error: ${e.message}');
      ref.read(authNotifierProvider.notifier).setValidationError(_getOtpErrorMessage(e));
    } catch (e) {
      debugPrint('❌ Unexpected error verifying OTP: $e');
      ref.read(authNotifierProvider.notifier).setValidationError('Verification failed. Please try again.');
    }
  }

  /// Create user profile in profiles table if this is a new user
  Future<void> _createUserProfileIfNeeded(User user) async {
    try {
      final supabase = ref.read(supabaseClientProvider);

      // Check if profile already exists
      final existingProfile = await supabase
          .from('profiles')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();

      if (existingProfile == null) {
        // Create new profile
        await supabase.from('profiles').insert({
          'id': user.id,
          'phone': user.phone,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });

        debugPrint('✅ User profile created for: ${user.id}');
      } else {
        debugPrint('ℹ️ User profile already exists for: ${user.id}');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to create user profile: $e');
      // Don't throw error as auth was successful
    }
  }

  /// Map Supabase OTP errors to user-friendly messages
  String _getOtpErrorMessage(AuthException error) {
    switch (error.message.toLowerCase()) {
      case 'invalid otp':
      case 'otp expired':
        return 'Invalid or expired code. Please try again.';
      case 'too many requests':
        return 'Too many attempts. Please wait before trying again.';
      default:
        return 'Verification failed. Please try again.';
    }
  }

  Future<void> _handleResendOtp() async {
    debugPrint('🔄 Resending OTP to: ${widget.phoneNumber}');

    try {
      // Get Supabase client
      final supabase = ref.read(supabaseClientProvider);

      // Resend OTP using Supabase Auth
      await supabase.auth.signInWithOtp(
        phone: widget.phoneNumber,
        shouldCreateUser: true,
      );

      debugPrint('✅ OTP resent successfully to ${widget.phoneNumber}');

      // Reset timer
      setState(() {
        _resendTimer = 60;
      });
      _startResendTimer();

      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Verification code sent'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } on AuthException catch (e) {
      debugPrint('❌ Failed to resend OTP: ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to resend code: ${e.message}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Unexpected error resending OTP: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to resend code. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }
}
