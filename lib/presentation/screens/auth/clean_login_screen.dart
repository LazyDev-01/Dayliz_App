import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../providers/auth_providers.dart';

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

    return Scaffold(
      body: SafeArea(
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

                const SizedBox(height: 16),

                // Or divider
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('OR'),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),

                const SizedBox(height: 16),

                // Google sign-in button
                _buildGoogleSignInButton(),

                const SizedBox(height: 24),

                // Register option
                _buildRegisterOption(),

                const SizedBox(height: 16),

                // Skip button
                _buildSkipButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Icon(
          Icons.shopping_bag_outlined,
          size: 80,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(height: 16),
        Text(
          'Dayliz',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in to your account',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Email field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'Enter your email',
              prefixIcon: Icon(Icons.email_outlined),
              border: OutlineInputBorder(),
            ),
            // UI/UX FIX: Remove validator to prevent form clearing
            // Validation is now done manually in _login() method
          ),

          const SizedBox(height: 16),

          // Password field
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Enter your password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              border: const OutlineInputBorder(),
            ),
            // UI/UX FIX: Remove validator to prevent form clearing
            // Validation is now done manually in _login() method
          ),
        ],
      ),
    );
  }

  Widget _buildForgotPasswordButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Remember Me checkbox
        Row(
          children: [
            Checkbox(
              value: _rememberMe,
              onChanged: (value) {
                setState(() {
                  _rememberMe = value ?? true;
                });
              },
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _rememberMe = !_rememberMe;
                });
              },
              child: const Text('Remember Me'),
            ),
          ],
        ),

        // Forgot Password button
        TextButton(
          onPressed: () {
            // Navigate to forgot password screen with smooth transition
            context.push('/reset-password');
          },
          child: const Text('Forgot Password?'),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    // Watch loading state for button-specific loading indicator
    final isLoading = ref.watch(authLoadingProvider);

    return ElevatedButton(
      onPressed: isLoading ? null : _login, // Disable button when loading
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text(
              'Sign In',
              style: TextStyle(fontSize: 16),
            ),
    );
  }

  Widget _buildGoogleSignInButton() {
    final isLoading = ref.watch(authLoadingProvider);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : _handleGoogleSignIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          elevation: 1,
          shadowColor: Colors.black.withOpacity(0.1),
        ),
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                ),
              )
            : SvgPicture.asset(
                'assets/images/google_logo.svg',
                height: 24,
                width: 24,
              ),
        label: Text(
          isLoading ? 'Signing in...' : 'Sign in with Google',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // Google Sign-In handler
  Future<void> _handleGoogleSignIn() async {
    try {
      debugPrint('🔄 Starting Google Sign-in from login screen');

      // Use the auth provider to handle Google sign-in
      await ref.read(authNotifierProvider.notifier).signInWithGoogle();

      // Check if sign-in was successful
      final authState = ref.read(authNotifierProvider);
      if (authState.isAuthenticated && authState.user != null) {
        debugPrint('✅ Google Sign-in successful, navigating to home');

        if (mounted) {
          // Navigate to home screen
          context.go('/home');
        }
      } else {
        debugPrint('❌ Google Sign-in failed - user not authenticated');

        // Check if there's an error message in the auth state
        final authState = ref.read(authNotifierProvider);

        // CRITICAL FIX: Don't show error for user cancellation
        if (authState.errorMessage != null && authState.errorMessage!.isNotEmpty) {
          // Check if it's a cancellation error
          if (authState.errorMessage!.contains('cancelled by user') ||
              authState.errorMessage!.contains('UserCancellationException')) {
            debugPrint('🔍 User cancellation detected in auth state - handling silently');
            // Clear the error from auth state
            ref.read(authNotifierProvider.notifier).clearErrors();
          } else {
            // Show error for actual issues
            if (mounted) {
              _showErrorSnackBar('Google Sign-in Error: ${authState.errorMessage}');
            }
          }
        } else {
          // No error message means user likely cancelled - handle silently
          debugPrint('🔍 No error message - likely user cancellation, handling silently');
        }
      }
    } catch (e) {
      debugPrint('❌ Error during Google Sign-in: $e');

      // CRITICAL FIX: Handle user cancellation gracefully
      if (e.toString().contains('UserCancellationException') ||
          e.toString().contains('cancelled by user')) {
        debugPrint('🔍 User cancelled Google Sign-in - handling silently');
        // Don't show any error message for user cancellation
        return;
      }

      // Provide more specific error messages for actual errors
      String userFriendlyMessage;
      if (e.toString().contains('ServerException')) {
        userFriendlyMessage = 'Server configuration error. Please contact support.';
      } else if (e.toString().contains('NetworkFailure')) {
        userFriendlyMessage = 'Network error. Please check your internet connection.';
      } else if (e.toString().contains('AuthException')) {
        userFriendlyMessage = 'Authentication error. Please try again.';
      } else {
        userFriendlyMessage = 'Google sign-in failed: ${e.toString()}';
      }

      if (mounted) {
        _showErrorSnackBar(userFriendlyMessage);
      }
    }
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
        const Text("Don't have an account?"),
        TextButton(
          onPressed: () {
            // Navigate to register screen with smooth transition
            context.push('/signup');
          },
          child: const Text('Sign Up'),
        ),
      ],
    );
  }

  Widget _buildSkipButton() {
    return Center(
      child: TextButton(
        onPressed: _handleSkip,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade400, width: 1),
          ),
        ),
        child: Text(
          'Skip',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _login() async {
    // Prevent multiple login attempts
    if (_isNavigating) {
      debugPrint('LOGIN: Already processing, ignoring duplicate request');
      return;
    }

    // CRITICAL FIX: Capture form values immediately and never clear them during process
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final rememberMe = _rememberMe;

    debugPrint('LOGIN: Starting login for $email');

    // Manual validation to prevent form clearing
    String? emailError;
    String? passwordError;

    if (email.isEmpty) {
      emailError = 'Please enter your email';
    } else if (!isValidEmail(email)) {
      emailError = 'Please enter a valid email address';
    }

    if (password.isEmpty) {
      passwordError = 'Please enter your password';
    } else if (password.length < 6) {
      passwordError = 'Password must be at least 6 characters';
    }

    // Show validation errors without touching form fields
    if (emailError != null || passwordError != null) {
      final errorMessage = emailError ?? passwordError ?? 'Please check your input';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

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

  // SKIP: Handle skip authentication
  void _handleSkip() {
    debugPrint('🎯 SKIP: User selected skip - bypassing authentication');
    debugPrint('🎯 SKIP: Current route: ${GoRouterState.of(context).uri.path}');
    debugPrint('🎯 SKIP: Attempting navigation to /home');

    // Navigate directly to home screen without authentication
    if (mounted) {
      try {
        context.go('/home');
        debugPrint('✅ SKIP: Navigation to /home initiated successfully');
      } catch (e) {
        debugPrint('❌ SKIP: Navigation failed: $e');
      }
    } else {
      debugPrint('❌ SKIP: Widget not mounted, cannot navigate');
    }
  }
}

/// Email validation helper function
bool isValidEmail(String email) {
  return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
}