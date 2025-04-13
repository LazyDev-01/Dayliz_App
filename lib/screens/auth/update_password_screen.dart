import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dayliz_app/providers/auth_provider.dart';
import 'package:dayliz_app/theme/app_theme.dart';
import 'package:dayliz_app/theme/app_spacing.dart';
import 'package:dayliz_app/utils/validators.dart';
import 'package:dayliz_app/widgets/buttons/dayliz_button.dart';
import 'package:dayliz_app/widgets/inputs/dayliz_text_field.dart';

class UpdatePasswordScreen extends ConsumerStatefulWidget {
  final String? accessToken;
  
  const UpdatePasswordScreen({
    Key? key,
    this.accessToken,
  }) : super(key: key);

  @override
  UpdatePasswordScreenState createState() => UpdatePasswordScreenState();
}

class UpdatePasswordScreenState extends ConsumerState<UpdatePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isSuccess = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isSuccess = false;
    });

    try {
      await ref.read(authNotifierProvider.notifier).updatePassword(
        password: _passwordController.text,
        accessToken: widget.accessToken,
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
    if (error.contains('expired')) {
      return 'Reset link has expired. Please request a new one';
    } else if (error.contains('invalid')) {
      return 'Invalid or expired reset link. Please request a new one';
    } else if (error.contains('rate limit')) {
      return 'Too many attempts. Please try again later';
    } else {
      return 'Failed to update password. Please try again';
    }
  }

  void _navigateToLogin() {
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (widget.accessToken == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Update Password'),
          elevation: 0,
        ),
        body: SafeArea(
          child: Padding(
            padding: AppSpacing.paddingLG,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: theme.colorScheme.error,
                ),
                AppSpacing.vMD,
                Text(
                  'Invalid Password Reset Link',
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                AppSpacing.vSM,
                Text(
                  'The password reset link is missing or invalid. Please request a new password reset link.',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                AppSpacing.vLG,
                DaylizButton(
                  label: 'Back to Login',
                  onPressed: _navigateToLogin,
                  type: DaylizButtonType.primary,
                  size: DaylizButtonSize.large,
                  isFullWidth: true,
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Password'),
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
                // Update password icon
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
                  'Set New Password',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displaySmall,
                ),
                AppSpacing.vXS,
                Text(
                  'Enter and confirm your new password',
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
                          'Password Updated Successfully!',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        AppSpacing.vXS,
                        Text(
                          'Your password has been updated. You can now log in with your new password.',
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
                
                if (!_isSuccess) ...[
                  // Password field
                  DaylizTextField(
                    controller: _passwordController,
                    label: 'New Password',
                    hint: 'Enter your new password',
                    obscureText: true,
                    textInputAction: TextInputAction.next,
                    prefixIcon: Icons.lock_outline,
                    validator: Validators.password,
                    errorText: null, // Will be handled by the form validator
                  ),
                  AppSpacing.vMD,
                  
                  // Confirm Password field
                  DaylizTextField(
                    controller: _confirmPasswordController,
                    label: 'Confirm Password',
                    hint: 'Confirm your new password',
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    prefixIcon: Icons.lock_outline,
                    validator: (value) => Validators.confirmField(
                      value,
                      _passwordController.text,
                      fieldName: 'Passwords',
                    ),
                    errorText: null, // Will be handled by the form validator
                  ),
                  AppSpacing.vLG,
                  
                  // Update button
                  DaylizButton(
                    label: 'Update Password',
                    onPressed: _isLoading ? null : _updatePassword,
                    isLoading: _isLoading,
                    type: DaylizButtonType.primary,
                    size: DaylizButtonSize.large,
                    isFullWidth: true,
                  ),
                ],
                
                AppSpacing.vMD,
                
                // Back to login
                if (_isSuccess) ...[
                  DaylizButton(
                    label: 'Go to Login',
                    onPressed: _navigateToLogin,
                    type: DaylizButtonType.primary,
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