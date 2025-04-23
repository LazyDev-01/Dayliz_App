import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../providers/auth_providers.dart';
import '../../../core/validators/validators.dart';

/// Clean architecture registration screen that uses Riverpod for state management
class CleanRegisterScreen extends ConsumerStatefulWidget {
  const CleanRegisterScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CleanRegisterScreen> createState() => _CleanRegisterScreenState();
}

class _CleanRegisterScreenState extends ConsumerState<CleanRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _registerError;

  @override
  void initState() {
    super.initState();
    // Add post-frame callback to listen for auth state changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listenManual(
        authNotifierProvider,
        (previous, next) {
          debugPrint('Auth state changed: isAuthenticated=${next.isAuthenticated}, user=${next.user != null}');

          // Check for errors
          if (next.errorMessage != null && next.errorMessage!.isNotEmpty) {
            setState(() {
              _registerError = next.errorMessage;
            });
          }

          // Check for successful authentication
          if (next.isAuthenticated && next.user != null) {
            debugPrint('User authenticated, navigating to home');
            if (mounted) {
              // Use Future.microtask to avoid build phase navigation issues
              final navigator = GoRouter.of(context);
              Future.microtask(() {
                if (mounted) {
                  navigator.go('/home');
                }
              });
            }
          }
        },
      );
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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

    // Update register error if there's an error message in the state
    if (authState.errorMessage != null && _registerError != authState.errorMessage) {
      _registerError = authState.errorMessage;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
      ),
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

                const SizedBox(height: 32),

                // Registration form
                _buildRegistrationForm(),

                const SizedBox(height: 16),

                // Error message
                if (_registerError != null)
                  Text(
                    _registerError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),

                const SizedBox(height: 24),

                // Register button
                _buildRegisterButton(),

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

                // Login option
                _buildLoginOption(),
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
          Icons.person_add_outlined,
          size: 60,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(height: 16),
        Text(
          'Join Dayliz',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Create a new account',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }

  Widget _buildRegistrationForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Name field
          TextFormField(
            controller: _nameController,
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              hintText: 'Enter your full name',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(),
            ),
            validator: Validators.validateName,
          ),

          const SizedBox(height: 16),

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
            validator: Validators.validateEmail,
          ),

          const SizedBox(height: 16),

          // Phone field
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone (Optional)',
              hintText: 'Enter your phone number',
              prefixIcon: Icon(Icons.phone_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                return Validators.validatePhone(value);
              }
              return null; // Phone is optional
            },
          ),

          const SizedBox(height: 16),

          // Password field
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Create a password',
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
              helperText: 'Password must contain lowercase, uppercase, number, and special character (e.g., Test@123)',
              helperMaxLines: 2,
            ),
            validator: Validators.validatePassword,
          ),

          const SizedBox(height: 16),

          // Confirm password field
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              hintText: 'Confirm your password',
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
            validator: (value) => Validators.validateConfirmPassword(
              value,
              _passwordController.text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterButton() {
    final isLoading = ref.watch(authLoadingProvider);

    return Column(
      children: [
        // Error message
        if (_registerError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              _registerError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
          ),

        // Register button
        ElevatedButton(
          onPressed: isLoading ? null : _handleRegister,
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
                  'Create Account',
                  style: TextStyle(fontSize: 16),
                ),
        ),
      ],
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
          label: const Text('Sign up with Google'),
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

  Widget _buildLoginOption() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Already have an account?'),
        TextButton(
          onPressed: () {
            // Check if we're already authenticated
            final authState = ref.read(authNotifierProvider);
            if (authState.isAuthenticated && authState.user != null) {
              // If authenticated, navigate to home
              context.go('/home');
            } else {
              // Otherwise, navigate to login
              context.go('/login');
            }
          },
          child: const Text('Sign In'),
        ),
      ],
    );
  }

  /// Check if password meets Supabase requirements
  bool _isPasswordValid(String password) {
    // Check for lowercase letters
    bool hasLowercase = RegExp(r'[a-z]').hasMatch(password);
    // Check for uppercase letters
    bool hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    // Check for numbers
    bool hasNumber = RegExp(r'[0-9]').hasMatch(password);
    // Check for special characters
    bool hasSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);

    return hasLowercase && hasUppercase && hasNumber && hasSpecial && password.length >= 8;
  }

  Future<void> _handleRegister() async {
    // Clear any previous errors
    setState(() {
      _registerError = null;
    });

    // Validate form
    if (_formKey.currentState?.validate() == true) {
      // Get form values
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final phone = _phoneController.text.trim();
      final password = _passwordController.text;

      // Double-check password requirements
      if (!_isPasswordValid(password)) {
        setState(() {
          _registerError = 'Password must contain at least one lowercase letter, one uppercase letter, one number, and one special character.';
        });
        return;
      }

      try {
        debugPrint('CleanRegisterScreen: Starting registration process');
        debugPrint('CleanRegisterScreen: email = $email');
        debugPrint('CleanRegisterScreen: name = $name');
        debugPrint('CleanRegisterScreen: phone = ${phone.isEmpty ? "null" : phone}');

        // Attempt registration
        debugPrint('CleanRegisterScreen: Calling authNotifierProvider.register');
        await ref.read(authNotifierProvider.notifier).register(
          email,
          password,
          name,
          phone: phone.isEmpty ? null : phone,
        );
        debugPrint('CleanRegisterScreen: register call completed');

        // Check if we're authenticated after registration
        final authState = ref.read(authNotifierProvider);
        debugPrint('Registration complete. Auth state: isAuthenticated=${authState.isAuthenticated}, user=${authState.user != null}');

        if (authState.isAuthenticated && authState.user != null) {
          debugPrint('User authenticated in _handleRegister, navigating to home');
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
      } catch (e) {
        debugPrint('Registration error: $e');
        // Show error in UI
        setState(() {
          _registerError = 'Registration failed: ${e.toString()}';
        });
      }
    }
  }
}