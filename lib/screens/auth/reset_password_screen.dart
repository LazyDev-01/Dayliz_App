import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dayliz_app/providers/auth_provider.dart';
import 'package:dayliz_app/theme/app_theme.dart';
import 'package:dayliz_app/theme/app_spacing.dart';
import 'package:dayliz_app/utils/validators.dart';
import 'package:dayliz_app/widgets/buttons/dayliz_button.dart';
import 'package:dayliz_app/widgets/inputs/dayliz_text_field.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({Key? key}) : super(key: key);

  @override
  ResetPasswordScreenState createState() => ResetPasswordScreenState();
}

class ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isSuccess = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isSuccess = false;
    });

    try {
      await ref.read(authNotifierProvider.notifier).resetPassword(
        email: _emailController.text.trim(),
      );
      
      if (!mounted) return;
      
      setState(() {
        _isSuccess = true;
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

  String _formatErrorMessage(String error) {
    // Format Supabase error messages for better user experience
    if (error.contains('rate limit')) {
      return 'Too many attempts. Please try again later';
    } else if (error.contains('email not found')) {
      return 'No account found with this email address';
    } else {
      return 'Failed to send password reset link. Please try again';
    }
  }

  void _navigateToLogin() {
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingLG,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppSpacing.vMD,
                // Reset password icon
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_reset,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                ),
                AppSpacing.vLG,
                Text(
                  'Forgot Your Password?',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displaySmall,
                ),
                AppSpacing.vXS,
                Text(
                  'Enter your email and we\'ll send you a link to reset your password',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                AppSpacing.vXL,
                
                // Success message
                if (_isSuccess) ...[
                  Container(
                    padding: AppSpacing.paddingMD,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          color: Colors.green,
                          size: 48,
                        ),
                        AppSpacing.vSM,
                        Text(
                          'Reset link sent!',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        AppSpacing.vXS,
                        Text(
                          'Please check your email inbox for instructions to reset your password.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.vMD,
                ],
                
                // Error message
                if (_errorMessage != null && !_isSuccess) ...[
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
                
                // Email field
                DaylizTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'Enter your email',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  prefixIcon: Icons.email_outlined,
                  validator: Validators.email,
                  errorText: null, // Will be handled by the form validator
                ),
                AppSpacing.vLG,
                
                // Reset button
                DaylizButton(
                  label: 'Send Reset Link',
                  onPressed: _isLoading || _isSuccess ? null : _resetPassword,
                  isLoading: _isLoading,
                  type: DaylizButtonType.primary,
                  size: DaylizButtonSize.large,
                  isFullWidth: true,
                ),
                AppSpacing.vMD,
                
                // Back to login
                if (_isSuccess) ...[
                  DaylizButton(
                    label: 'Back to Login',
                    onPressed: _navigateToLogin,
                    type: DaylizButtonType.secondary,
                    size: DaylizButtonSize.large,
                    isFullWidth: true,
                  ),
                ] else ...[
                  TextButton.icon(
                    onPressed: _navigateToLogin,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back to Login'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
} 