import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/auth_providers.dart';
import '../../providers/supabase_providers.dart';
import '../../widgets/auth/premium_auth_button.dart';
import '../../widgets/auth/auth_button_types.dart';
import '../../widgets/auth/auth_background.dart';

/// Phone authentication screen for Q-Commerce
/// Handles phone number input and OTP verification
class PhoneAuthScreen extends ConsumerStatefulWidget {
  const PhoneAuthScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends ConsumerState<PhoneAuthScreen>
    with TickerProviderStateMixin {
  final _phoneController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _phoneNumber = '';
  final String _countryCode = '+91';
  bool _isValidPhone = false;
  String? _phoneError;

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

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();

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
    _phoneController.dispose();
    super.dispose();
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
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),

                  // Header Section
                  _buildHeaderSection(theme),

                  const SizedBox(height: 60),

                  // Phone Input Form
                  _buildPhoneInputForm(theme),

                  const SizedBox(height: 24),

                  // Error Message
                  if (errorMessage != null && errorMessage.isNotEmpty)
                    _buildErrorMessage(errorMessage, theme),

                  const Spacer(),

                  // Continue Button
                  _buildContinueButton(isLoading),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(ThemeData theme) {
    return Column(
      children: [
        // Phone Icon
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(
            Icons.phone_android_rounded,
            size: 36,
            color: Colors.white,
          ),
        ),

        const SizedBox(height: 20),

        // Single simplified text
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Enter your phone number to continue',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 18,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneInputForm(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Phone Number Input - Single unified form field
        Container(
          height: 56, // Fixed height matching login screen
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Country Code Section
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  '+91',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              // Divider
              Container(
                width: 1,
                height: 24,
                color: Colors.grey.shade300,
              ),
              // Phone Number Input Section
              Expanded(
                child: TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    hintText: 'Enter phone number',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w400,
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    counterText: '', // Remove counter text
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  textInputAction: TextInputAction.done,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _phoneNumber = '+91$value';
                      _isValidPhone = value.length == 10;
                      _phoneError = null; // Clear error when user types
                    });
                  },
                ),
              ),
            ],
          ),
        ),

        // Error Message (outside form field)
        if (_phoneError != null)
          Padding(
            padding: const EdgeInsets.only(top: 12, left: 4),
            child: Text(
              _phoneError!,
              style: TextStyle(
                color: Colors.red.shade300,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
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

  Widget _buildContinueButton(bool isLoading) {
    return PremiumAuthButton(
      onPressed: _isValidPhone && !isLoading ? _handleContinue : null,
      icon: Icons.arrow_forward_rounded,
      text: 'Send OTP',
      backgroundColor: Colors.transparent,
      textColor: Colors.white,
      borderColor: Colors.white.withValues(alpha: 0.3),
      isLoading: isLoading,
      priority: AuthButtonPriority.tertiary,
      height: 48, // Match login screen button height
    );
  }

  Future<void> _handleContinue() async {
    // Validate phone number
    final phoneText = _phoneController.text.trim();

    if (phoneText.isEmpty) {
      setState(() {
        _phoneError = 'Please enter your phone number';
      });
      return;
    }

    if (phoneText.length != 10) {
      setState(() {
        _phoneError = 'Please enter a valid 10-digit phone number';
      });
      return;
    }

    setState(() {
      _phoneError = null;
    });

    debugPrint('🔄 Sending OTP to: $_phoneNumber');

    try {
      // Get Supabase client
      final supabase = ref.read(supabaseClientProvider);

      // Send OTP using Supabase Auth
      await supabase.auth.signInWithOtp(
        phone: _phoneNumber,
        shouldCreateUser: true, // Create user if doesn't exist
      );

      debugPrint('✅ OTP sent successfully to $_phoneNumber');

      // Navigate to OTP verification screen
      if (mounted) {
        context.push('/otp-verification', extra: {
          'phoneNumber': _phoneNumber,
          'countryCode': _countryCode,
        });
      }
    } on AuthException catch (e) {
      debugPrint('❌ Supabase Auth error: ${e.message}');
      setState(() {
        _phoneError = _getPhoneAuthErrorMessage(e);
      });
    } catch (e) {
      debugPrint('❌ Unexpected error sending OTP: $e');
      setState(() {
        _phoneError = 'Failed to send OTP. Please try again.';
      });
    }
  }

  /// Map Supabase auth errors to user-friendly messages
  String _getPhoneAuthErrorMessage(AuthException error) {
    switch (error.message.toLowerCase()) {
      case 'invalid phone number':
        return 'Please enter a valid phone number';
      case 'phone rate limit exceeded':
        return 'Too many attempts. Please try again later';
      case 'sms not configured':
        return 'SMS service is currently unavailable';
      default:
        return 'Failed to send OTP. Please try again';
    }
  }

}
