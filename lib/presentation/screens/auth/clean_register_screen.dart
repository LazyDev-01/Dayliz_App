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
  String? _emailError; // New variable to track email-specific errors

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
              Future.microtask(() {
                if (mounted) {
                  context.go('/home');
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
    if (authState.isAuthenticated && authState.user != null) {
      // If authenticated, navigate to home page on next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/home');
      });
    }

    // Update register error if there's an error message in the state
    if (authState.errorMessage != null && _registerError != authState.errorMessage) {
      // Filter out the "No authenticated user found" error as it's not relevant for registration
      if (authState.errorMessage != "No authenticated user found") {
        _registerError = authState.errorMessage;
      } else {
        // Clear the error if it's "No authenticated user found"
        _registerError = null;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
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

                // Error message placeholder - actual error is shown below the form

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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter your email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: const OutlineInputBorder(),
                  // Show error outline if there's an email-specific error
                  errorBorder: _emailError != null
                    ? OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.error,
                          width: 2.0,
                        ),
                      )
                    : null,
                  // Don't show the error text in the field itself
                  errorStyle: const TextStyle(height: 0, fontSize: 0),
                ),
                validator: (value) {
                  // Clear email error when validating
                  if (_emailError != null) {
                    setState(() {
                      _emailError = null;
                    });
                  }
                  return Validators.validateEmail(value);
                },
              ),
              // Display email-specific error message
              if (_emailError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6.0, left: 12.0),
                  child: Text(
                    _emailError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12.0,
                    ),
                  ),
                ),
            ],
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
              // Otherwise, navigate back (which should be login)
              Navigator.of(context).pop();
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
      _emailError = null;
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
            // Navigate directly to home screen without any delay
            debugPrint('Navigating to home screen...');
            context.go('/home');
          }
        } else {
          debugPrint('Registration completed but user is not authenticated yet');
          // Try to get the current user manually
          try {
            debugPrint('Attempting to manually check authentication status...');
            // Try to get the current authentication state again
            final authState = ref.read(authNotifierProvider);

            // Check if we're authenticated now
            if (authState.isAuthenticated) {
              debugPrint('Manual check found authenticated user, navigating to home');
              if (mounted) {
                context.go('/home');
                return;
              }
            } else {
              debugPrint('Manual check did not find authenticated user');
            }
          } catch (e) {
            debugPrint('Error during manual authentication check: $e');
          }

          // Show a success message but don't navigate away
          setState(() {
            _registerError = 'Account created successfully! Please sign in.';
          });

          // Optionally, navigate to login screen after a delay
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.of(context).pop(); // Go back to login screen
            }
          });
        }
      } catch (e) {
        debugPrint('Registration error: $e');
        // Show error in UI
        setState(() {
          String errorMsg = e.toString().toLowerCase();

          // Check if the error message already contains a user-friendly message about duplicate email
          if (errorMsg.contains('already registered') ||
              errorMsg.contains('email is already') ||
              errorMsg.contains('email already') ||
              errorMsg.contains('already exists') ||
              errorMsg.contains('duplicate')) {
            // Set email-specific error instead of general register error
            _emailError = 'Email id already exists!';
            // Scroll to the email field to make the error visible
            _formKey.currentState?.validate(); // This will trigger the validator and show the error
          }
          // Check for password format errors
          else if (errorMsg.contains('password must') ||
                   errorMsg.contains('password should') ||
                   errorMsg.contains('password requirements')) {
            _registerError = 'Password must contain at least one lowercase letter, one uppercase letter, one number, and one special character.';
          }
          // Check for invalid email format
          else if (errorMsg.contains('invalid email') ||
                   errorMsg.contains('email format')) {
            _registerError = 'Please enter a valid email address.';
          }
          // For any other error, display a cleaned-up version of the error message
          else {
            _registerError = 'Registration failed: ${e.toString().replaceAll('Exception: ', '')}';
          }
        });
      }
    }
  }
}