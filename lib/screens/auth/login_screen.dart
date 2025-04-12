import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dayliz_app/providers/auth_provider.dart';
import 'package:dayliz_app/theme/app_theme.dart';
import 'package:dayliz_app/theme/app_spacing.dart';
import 'package:dayliz_app/utils/validators.dart';
import 'package:dayliz_app/widgets/buttons/dayliz_button.dart';
import 'package:dayliz_app/widgets/inputs/dayliz_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authNotifierProvider.notifier).signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      if (!mounted) return;
      
      // Navigation will be handled by the router's redirect
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
    if (error.contains('Invalid login credentials')) {
      return 'Invalid email or password';
    } else if (error.contains('rate limit')) {
      return 'Too many login attempts. Please try again later';
    } else {
      return 'Login failed. Please try again';
    }
  }

  void _navigateToSignup() {
    context.go('/signup');
  }

  void _navigateToForgotPassword() {
    // TODO: Implement forgot password navigation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Forgot password functionality coming soon!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingLG,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppSpacing.vXL,
                // App Logo
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.local_grocery_store,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                ),
                AppSpacing.vLG,
                Text(
                  'Welcome Back!',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displaySmall,
                ),
                AppSpacing.vXS,
                Text(
                  'Login to continue shopping',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                AppSpacing.vXL,
                
                // Error message
                if (_errorMessage != null) ...[
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
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.email_outlined,
                  validator: Validators.email,
                  errorText: null, // Will be handled by the form validator
                ),
                AppSpacing.vMD,
                
                // Password field
                DaylizTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Enter your password',
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  prefixIcon: Icons.lock_outline,
                  validator: Validators.password,
                  errorText: null, // Will be handled by the form validator
                ),
                AppSpacing.vSM,
                
                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _navigateToForgotPassword,
                    child: Text(
                      'Forgot Password?',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.primaryColor,
                      ),
                    ),
                  ),
                ),
                AppSpacing.vLG,
                
                // Login button
                DaylizButton(
                  label: 'Login',
                  onPressed: _isLoading ? null : _login,
                  isLoading: _isLoading,
                  type: DaylizButtonType.primary,
                  size: DaylizButtonSize.large,
                  isFullWidth: true,
                ),
                AppSpacing.vMD,
                
                // Or divider
                Row(
                  children: [
                    Expanded(child: Divider(color: theme.dividerColor)),
                    Padding(
                      padding: AppSpacing.paddingHSM,
                      child: Text(
                        'OR',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: theme.dividerColor)),
                  ],
                ),
                AppSpacing.vMD,
                
                // Google sign in
                DaylizButton(
                  label: 'Continue with Google',
                  onPressed: () {
                    // TODO: Implement Google sign in
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Google Sign In coming soon!'),
                      ),
                    );
                  },
                  leadingIcon: Icons.g_mobiledata,
                  type: DaylizButtonType.secondary,
                  size: DaylizButtonSize.large,
                  isFullWidth: true,
                ),
                AppSpacing.vLG,
                
                // Sign up link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Don\'t have an account? ',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    TextButton(
                      onPressed: _navigateToSignup,
                      child: Text(
                        'Sign Up',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 