import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dayliz_app/providers/auth_provider.dart';
import 'package:dayliz_app/theme/app_theme.dart';
import 'package:dayliz_app/theme/app_spacing.dart';
import 'package:dayliz_app/widgets/buttons/dayliz_button.dart';
import 'package:dayliz_app/services/auth_service.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  final String email;
  
  const EmailVerificationScreen({
    Key? key,
    required this.email,
  }) : super(key: key);

  @override
  EmailVerificationScreenState createState() => EmailVerificationScreenState();
}

class EmailVerificationScreenState extends ConsumerState<EmailVerificationScreen> {
  bool _isLoading = false;
  bool _isSendingEmail = false;
  String? _errorMessage;
  bool _verificationSent = false;
  
  @override
  void initState() {
    super.initState();
    _checkVerificationStatus();
  }
  
  Future<void> _checkVerificationStatus() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final user = ref.read(currentUserProvider);
      final isVerified = user != null && AuthService.instance.isEmailVerified;
      
      if (isVerified && mounted) {
        // Email already verified, redirect to home
        GoRouter.of(context).go('/home');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to check verification status';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _sendVerificationEmail() async {
    if (_isSendingEmail) return;
    
    setState(() {
      _isSendingEmail = true;
      _errorMessage = null;
    });
    
    try {
      await ref.read(authNotifierProvider.notifier).sendEmailVerification(
        email: widget.email,
      );
      
      if (!mounted) return;
      
      setState(() {
        _verificationSent = true;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification email sent'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _errorMessage = e is AuthException 
            ? e.message 
            : 'Failed to send verification email';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSendingEmail = false;
        });
      }
    }
  }
  
  void _goToLogin() {
    GoRouter.of(context).go('/login');
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingLG,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSpacing.vLG,
              
              // Email verification icon
              const Icon(
                Icons.mark_email_unread_outlined,
                size: 80,
                color: AppTheme.primaryColor,
              ),
              AppSpacing.vMD,
              
              Text(
                'Verify Your Email',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium,
              ),
              AppSpacing.vSM,
              
              Text(
                'We\'ve sent a verification email to:\n${widget.email}',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              AppSpacing.vMD,
              
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
              
              // Main instruction text
              Container(
                padding: AppSpacing.paddingMD,
                decoration: BoxDecoration(
                  color: AppTheme.backgroundSecondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Please check your email and follow these steps:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    AppSpacing.vSM,
                    const Text('1. Open the verification email from Dayliz App'),
                    const Text('2. Click on the verification link in the email'),
                    const Text('3. Return to the app and sign in'),
                  ],
                ),
              ),
              AppSpacing.vXL,
              
              // Verify Email button
              DaylizButton(
                onPressed: _isSendingEmail ? null : _sendVerificationEmail,
                label: _verificationSent 
                    ? 'Resend Verification Email' 
                    : 'Send Verification Email',
                isLoading: _isSendingEmail,
              ),
              AppSpacing.vMD,
              
              // Already verified link
              Center(
                child: TextButton(
                  onPressed: _isLoading ? null : _checkVerificationStatus,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Already verified? ',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      Text(
                        'Check status',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AppSpacing.vSM,
              
              // Back to sign in
              Center(
                child: TextButton(
                  onPressed: _goToLogin,
                  child: Text(
                    'Back to Sign In',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.primaryColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 