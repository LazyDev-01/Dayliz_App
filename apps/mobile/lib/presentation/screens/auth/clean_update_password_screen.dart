import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/common/unified_app_bar.dart';

import '../../providers/auth_providers.dart';
import '../../../core/validators/validators.dart';

/// Clean architecture password update screen that uses Riverpod for state management
/// This screen handles both:
/// 1. Password reset via token (from email link)
/// 2. Password update for authenticated users
class CleanUpdatePasswordScreen extends ConsumerStatefulWidget {
  final String? token;
  final bool isReset;

  const CleanUpdatePasswordScreen({
    Key? key,
    this.token,
    this.isReset = true,
  }) : super(key: key);

  @override
  ConsumerState<CleanUpdatePasswordScreen> createState() => _CleanUpdatePasswordScreenState();
}

class _CleanUpdatePasswordScreenState extends ConsumerState<CleanUpdatePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;
  bool _passwordUpdated = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UnifiedAppBars.withBackButton(
        title: widget.isReset ? 'Reset Password' : 'Update Password',
        onBackPressed: () => _goBack(context),
        fallbackRoute: widget.isReset ? '/auth/login' : '/profile',
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: _passwordUpdated
                ? _buildSuccessView()
                : _buildPasswordForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordForm() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Icon
        Icon(
          Icons.lock_reset,
          size: 70,
          color: Theme.of(context).primaryColor,
        ),

        const SizedBox(height: 24),

        // Title
        Text(
          widget.isReset ? 'Reset Your Password' : 'Update Your Password',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 16),

        // Description
        Text(
          widget.isReset
              ? 'Please enter your new password below.'
              : 'Enter your current password and choose a new password.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 32),

        // Form
        Form(
          key: _formKey,
          child: Column(
            children: [
              // Current password field (only for password update, not reset)
              if (!widget.isReset) ...[
                TextFormField(
                  controller: _currentPasswordController,
                  obscureText: _obscureCurrentPassword,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    hintText: 'Enter your current password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureCurrentPassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureCurrentPassword = !_obscureCurrentPassword;
                        });
                      },
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your current password';
                    }
                    return null;
                  },
                  enabled: !_isSubmitting,
                ),
                const SizedBox(height: 16),
              ],

              // New password field
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNewPassword,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  hintText: 'Enter your new password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureNewPassword = !_obscureNewPassword;
                      });
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: Validators.validatePassword,
                enabled: !_isSubmitting,
              ),

              const SizedBox(height: 16),

              // Confirm password field
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  hintText: 'Confirm your new password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
                enabled: !_isSubmitting,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Error message
        if (_errorMessage != null)
          Text(
            _errorMessage!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),

        const SizedBox(height: 24),

        // Submit button
        ElevatedButton(
          onPressed: _isSubmitting ? null : _handleUpdatePassword,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  widget.isReset ? 'Reset Password' : 'Update Password',
                  style: const TextStyle(fontSize: 16),
                ),
        ),

        const SizedBox(height: 24),

        // Back button
        TextButton(
          onPressed: () => _goBack(context),
          child: Text(widget.isReset ? 'Back to Login' : 'Cancel'),
        ),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Success icon
        Icon(
          Icons.check_circle_outline,
          size: 80,
          color: Colors.green,
        ),

        const SizedBox(height: 24),

        // Success title
        Text(
          'Password Updated',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 16),

        // Success message
        Text(
          widget.isReset
              ? 'Your password has been reset successfully. You can now log in with your new password.'
              : 'Your password has been updated successfully.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 32),

        // Continue button
        ElevatedButton(
          onPressed: () => _goToNextScreen(context),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            widget.isReset ? 'Go to Login' : 'Continue',
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  void _goBack(BuildContext context) {
    if (widget.isReset) {
      context.go('/login');
    } else {
      context.pop();
    }
  }

  void _goToNextScreen(BuildContext context) {
    if (widget.isReset) {
      context.go('/login');
    } else {
      context.go('/profile');
    }
  }

  Future<void> _handleUpdatePassword() async {
    // Clear previous errors
    setState(() {
      _errorMessage = null;
    });

    // Validate form
    if (_formKey.currentState?.validate() == true) {
      // Show loading indicator
      setState(() {
        _isSubmitting = true;
      });

      try {
        bool success;

        if (widget.isReset) {
          // Reset password with token
          success = await ref.read(authNotifierProvider.notifier).updatePassword(
                password: _newPasswordController.text,
                accessToken: widget.token,
              );
        } else {
          // Change password for authenticated user
          success = await ref.read(authNotifierProvider.notifier).changePassword(
                currentPassword: _currentPasswordController.text,
                newPassword: _newPasswordController.text,
              );
        }

        // If successful, show success view
        if (success) {
          setState(() {
            _isSubmitting = false;
            _passwordUpdated = true;
          });
        } else {
          // If failed, show error message
          setState(() {
            _isSubmitting = false;
            _errorMessage = widget.isReset
                ? 'Failed to reset password. Please try again.'
                : 'Failed to update password. Please check your current password and try again.';
          });
        }
      } catch (e) {
        // Handle any unexpected errors
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'An error occurred: ${e.toString()}';
        });
      }
    }
  }
}
