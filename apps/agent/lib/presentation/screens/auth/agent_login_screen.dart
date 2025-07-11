import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_components/ui_components.dart';
import '../../../core/providers/auth_provider.dart';

/// 🔷 2. EXISTING AGENT LOGIN
/// 📄 Screen Title: "Agent Login"
/// Inputs:
/// 🆔 Agent ID (e.g., DLZ-AG-00123)
/// 🔒 Password
/// 
/// Buttons:
/// ✅ Login
/// ❓ Forgot Password
class AgentLoginScreen extends ConsumerStatefulWidget {
  const AgentLoginScreen({super.key});

  @override
  ConsumerState<AgentLoginScreen> createState() => _AgentLoginScreenState();
}

class _AgentLoginScreenState extends ConsumerState<AgentLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailOrPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailOrPhoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Add haptic feedback
    HapticFeedback.lightImpact();

    // Clear any previous errors
    ref.read(authProvider.notifier).clearError();

    try {
      final success = await ref.read(authProvider.notifier).login(
        emailOrPhone: _emailOrPhoneController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        if (success) {
          // Navigate to dashboard after successful login
          context.go('/dashboard');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login successful! Welcome back.'),
              backgroundColor: Color(0xFF2E7D32),
            ),
          );
        } else {
          // Error is handled by the provider and will be shown in UI
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleForgotPassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Forgot Password'),
        content: const Text(
          'Please contact support at support@dayliz.com with your email or phone number to reset your password.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch auth state for loading and error handling
    final authState = ref.watch(authProvider);
    final isAuthLoading = authState.isLoading;
    final authError = authState.error;

    // Update local loading state based on auth state
    if (_isLoading != isAuthLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _isLoading = isAuthLoading);
        }
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Agent Login',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/auth'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                
                // Header Section
                const Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.badge,
                        size: 64,
                        color: Color(0xFF2E7D32),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Welcome Back!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Enter your credentials to continue',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // 📧 Email or Phone Input
                DaylizTextField(
                  controller: _emailOrPhoneController,
                  labelText: 'Email or Phone',
                  hintText: 'Enter your email or phone number',
                  prefixIcon: Icons.person,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email or phone number';
                    }
                    // Check if it's a valid email or phone format
                    final isEmail = value.contains('@');
                    final isPhone = RegExp(r'^\+?[\d\s\-\(\)]+$').hasMatch(value);

                    if (!isEmail && !isPhone) {
                      return 'Please enter a valid email address or phone number';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 20),
                
                // 🔒 Password Input
                DaylizTextField(
                  controller: _passwordController,
                  labelText: 'Password',
                  hintText: 'Enter your password',
                  prefixIcon: Icons.lock,
                  obscureText: _obscurePassword,
                  suffixIconWidget: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
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

                // Error Display
                if (authError != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            authError,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),
                
                // ✅ Login Button
                DaylizButton(
                  text: 'Login',
                  onPressed: _isLoading ? null : _handleLogin,
                  backgroundColor: const Color(0xFF2E7D32),
                  textColor: Colors.white,
                  isLoading: _isLoading,
                ),
                
                const SizedBox(height: 16),
                
                // ❓ Forgot Password Button
                TextButton(
                  onPressed: _handleForgotPassword,
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
