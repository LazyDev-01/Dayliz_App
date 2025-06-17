import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_providers.dart';
import '../../../core/utils/validators.dart';
import '../../widgets/auth/auth_background.dart';

/// Clean architecture login screen that uses Riverpod for state management
class CleanLoginScreen extends ConsumerStatefulWidget {
  const CleanLoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CleanLoginScreen> createState() => _CleanLoginScreenState();
}

class _CleanLoginScreenState extends ConsumerState<CleanLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true; // Default to true

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    // Clear errors to prevent registration errors from appearing on login screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(authNotifierProvider.notifier).clearErrors();
        debugPrint('LOGIN SCREEN: Cleared errors during initialization');
      }
    });
  }

  // Flag to prevent multiple navigations
  bool _isNavigating = false;

  @override
  Widget build(BuildContext context) {
    // UI/UX FIX: Only watch specific parts of the auth state
    // This prevents unnecessary rebuilds that could cause infinite loops
    final errorMessage = ref.watch(authErrorProvider);

    // UI/UX FIX: Don't automatically navigate based on auth state
    // We'll handle navigation explicitly in the login method

    return AuthBackground(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // App logo
              _buildLogo(),

              const SizedBox(height: 48),

              // Login form
              _buildLoginForm(),

              const SizedBox(height: 16),

              // Error message - CRITICAL FIX: Filter out cancellation errors
              if (errorMessage != null &&
                  errorMessage.isNotEmpty &&
                  !errorMessage.contains('cancelled by user') &&
                  !errorMessage.contains('UserCancellationException'))
                Text(
                  errorMessage,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),

              const SizedBox(height: 24),

              // Forgot password button
              _buildForgotPasswordButton(),

              const SizedBox(height: 16),

              // Login button
              _buildLoginButton(),

              const SizedBox(height: 32),

              // Register option
              _buildRegisterOption(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        // App Name
        Text(
          'Dayliz',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 42,
            letterSpacing: -1,
          ),
        ),

        const SizedBox(height: 24),

        // Sign in prompt
        Text(
          'Sign in to your account',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Email field with enhanced styling
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'Enter your email address',
                prefixIcon: Icon(
                  Icons.email_outlined,
                  color: Theme.of(context).primaryColor,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                labelStyle: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                ),
              ),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your email';
                }
                if (!isValidEmail(value.trim())) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
          ),

          const SizedBox(height: 20),

          // Password field with enhanced styling
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your password',
                prefixIcon: Icon(
                  Icons.lock_outline,
                  color: Theme.of(context).primaryColor,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey.shade600,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                labelStyle: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                ),
              ),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForgotPasswordButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Remember Me checkbox with enhanced styling
        Row(
          children: [
            Transform.scale(
              scale: 1.1,
              child: Checkbox(
                value: _rememberMe,
                onChanged: (value) {
                  setState(() {
                    _rememberMe = value ?? true;
                  });
                },
                activeColor: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _rememberMe = !_rememberMe;
                });
              },
              child: Text(
                'Remember Me',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),

        // Forgot Password button with enhanced styling
        TextButton(
          onPressed: () {
            // Navigate to forgot password screen with smooth transition
            context.push('/reset-password');
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: Text(
            'Forgot Password?',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    // Watch loading state for button-specific loading indicator
    final isLoading = ref.watch(authLoadingProvider);

    return ElevatedButton(
      onPressed: isLoading ? null : _login,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        elevation: 0,
        minimumSize: const Size(double.infinity, 52),
      ),
      child: isLoading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text(
              'Sign In',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
    );
  }





  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildRegisterOption() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account?",
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 16,
          ),
        ),
        TextButton(
          onPressed: () {
            // Navigate to register screen with smooth transition
            context.push('/signup');
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
          child: Text(
            'Sign Up',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }



  void _login() async {
    // Prevent multiple login attempts
    if (_isNavigating) {
      debugPrint('LOGIN: Already processing, ignoring duplicate request');
      return;
    }

    // Validate form using Flutter's built-in validation
    if (!_formKey.currentState!.validate()) {
      debugPrint('LOGIN: Form validation failed');
      return;
    }

    // CRITICAL FIX: Capture form values immediately and never clear them during process
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final rememberMe = _rememberMe;

    debugPrint('LOGIN: Starting login for $email');

    // Set navigating flag and clear previous errors
    _isNavigating = true;
    ref.read(authNotifierProvider.notifier).clearErrors();

    try {
      // Attempt login - DO NOT touch form fields during this process
      await ref.read(authNotifierProvider.notifier).login(
        email,
        password,
        rememberMe: rememberMe,
      );

      // Check auth state after login attempt
      final authState = ref.read(authNotifierProvider);

      if (authState.isAuthenticated && authState.user != null && mounted) {
        debugPrint('LOGIN: Success! Navigating to home');

        // CRITICAL FIX: Only clear form AFTER successful login
        _emailController.clear();
        _passwordController.clear();

        // Navigate immediately - no delay needed since router is now stable
        context.go('/home');
      } else {
        debugPrint('LOGIN: Failed - form fields preserved');
        // Form fields are automatically preserved since we never touched them
      }
    } catch (e) {
      debugPrint('LOGIN: Error - $e');
      // Form fields are automatically preserved since we never touched them
    } finally {
      // Reset navigating flag
      _isNavigating = false;
    }
  }


}

