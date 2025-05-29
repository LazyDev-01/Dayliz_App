import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_providers.dart';
import '../../../core/validators/validators.dart';

/// Clean architecture forgot password screen that uses Riverpod for state management
class CleanForgotPasswordScreen extends ConsumerStatefulWidget {
  const CleanForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CleanForgotPasswordScreen> createState() => _CleanForgotPasswordScreenState();
}

class _CleanForgotPasswordScreenState extends ConsumerState<CleanForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Use Navigator.pop() for smooth back transition
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              // Fallback to context.go if no previous route exists
              context.go('/login');
            }
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: _emailSent
                ? _buildSuccessView()
                : _buildForgotPasswordForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildForgotPasswordForm() {
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
          'Forgot Password',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 16),

        // Description
        Text(
          'Enter your email address and we\'ll send you a link to reset your password.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 32),

        // Form
        Form(
          key: _formKey,
          child: Column(
            children: [
              // Email field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter your email address',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: Validators.validateEmail,
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
          onPressed: _isSubmitting ? null : _handleResetPassword,
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
              : const Text(
                  'Reset Password',
                  style: TextStyle(fontSize: 16),
                ),
        ),

        const SizedBox(height: 24),

        // Back to login
        TextButton(
          onPressed: () {
            // Use Navigator.pop() for smooth back transition
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              // Fallback to context.go if no previous route exists
              context.go('/login');
            }
          },
          child: const Text('Back to Login'),
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
          'Email Sent',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 16),

        // Success message
        Text(
          'We\'ve sent a password reset link to ${_emailController.text}. Please check your email inbox.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 32),

        // Back to login button
        ElevatedButton(
          onPressed: () {
            // Use Navigator.pop() for smooth back transition
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              // Fallback to context.go if no previous route exists
              context.go('/login');
            }
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Back to Login',
            style: TextStyle(fontSize: 16),
          ),
        ),

        const SizedBox(height: 16),

        // Didn't receive email
        TextButton(
          onPressed: () {
            if (mounted) {
              setState(() {
                _emailSent = false;
              });
            }
          },
          child: const Text('Didn\'t receive the email? Try again'),
        ),
      ],
    );
  }

  Future<void> _handleResetPassword() async {
    // Clear previous errors
    if (mounted) {
      setState(() {
        _errorMessage = null;
      });
    }

    // Validate form
    if (_formKey.currentState?.validate() == true) {
      // Show loading indicator
      if (mounted) {
        setState(() {
          _isSubmitting = true;
        });
      }

      // Get form value
      final email = _emailController.text.trim();

      try {
        // Attempt to reset password
        final success = await ref.read(authNotifierProvider.notifier).forgotPassword(email);

        // Check if widget is still mounted before calling setState
        if (!mounted) return;

        // If successful, show success view
        if (success) {
          setState(() {
            _isSubmitting = false;
            _emailSent = true;
          });
        } else {
          // If failed, show error message
          setState(() {
            _isSubmitting = false;
            _errorMessage = 'Failed to send reset email. Please try again.';
          });
        }
      } catch (e) {
        // Check if widget is still mounted before calling setState
        if (!mounted) return;

        // Handle any unexpected errors
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'An error occurred. Please try again later.';
        });
      }
    }
  }
}