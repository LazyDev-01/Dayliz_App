import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../providers/auth_providers.dart';
import '../../../core/validators/validators.dart';

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
  String? _loginError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch auth state
    final authState = ref.watch(authNotifierProvider);

    // Check authentication status
    if (authState.isAuthenticated) {
      // If authenticated, navigate to home page on next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/home');
      });
    }

    // Update login error if there's an error message in the state
    if (authState.errorMessage != null && _loginError != authState.errorMessage) {
      // Filter out the "No authenticated user found" error as it's not relevant for login
      if (authState.errorMessage != "No authenticated user found") {
        _loginError = authState.errorMessage;
      } else {
        // Clear the error if it's "No authenticated user found"
        _loginError = null;
      }
    }

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

                // Error message
                if (_loginError != null)
                  Text(
                    _loginError!,
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
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!isValidEmail(value)) {
                return 'Please enter a valid email address';
              }
              return null;
            },
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
            // Navigate to forgot password screen
            context.go('/reset-password');
          },
          child: const Text('Forgot Password?'),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    final isLoading = ref.watch(authLoadingProvider);

    return ElevatedButton(
      onPressed: isLoading ? null : _login,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Text(
              'Sign In',
              style: TextStyle(fontSize: 16),
            ),
    );
  }

  Widget _buildGoogleSignInButton() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: null, // Disabled for now
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          icon: SvgPicture.asset(
            'assets/images/google_logo.svg',
            height: 24,
            width: 24,
          ),
          label: const Text('Sign in with Google'),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber.shade200),
          ),
          child: const Text(
            'Google Sign-In is temporarily unavailable. Please use email/password instead.',
            style: TextStyle(color: Colors.amber, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  // Google Sign-In method is temporarily disabled
  // Will be implemented in a future update

  Widget _buildRegisterOption() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Don't have an account?"),
        TextButton(
          onPressed: () {
            // Navigate to register screen
            context.go('/signup');
          },
          child: const Text('Sign Up'),
        ),
      ],
    );
  }

  void _login() async {
    // Validate form
    if (_formKey.currentState?.validate() == true) {
      // Get form values
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      debugPrint('Starting login process for $email');

      // Attempt login
      await ref.read(authNotifierProvider.notifier).login(
        email,
        password,
        rememberMe: _rememberMe,
      );

      // Check if we're authenticated after login
      final authState = ref.read(authNotifierProvider);
      debugPrint('Login complete. Auth state: isAuthenticated=${authState.isAuthenticated}, user=${authState.user != null}');

      if (authState.isAuthenticated && authState.user != null) {
        debugPrint('User authenticated in _login, navigating to home');
        // If authenticated, navigate to home
        if (mounted) {
          final navigator = GoRouter.of(context);
          // Use a slight delay to ensure the state is fully updated
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              navigator.go('/home');
            }
          });
        }
      }
    }
  }
}

/// Email validation helper function
bool isValidEmail(String email) {
  return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
}