import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/usecases/verify_email_usecase.dart';
import '../../providers/auth_providers.dart';
import '../../../theme/app_theme.dart';

/// A clean architecture screen that processes verification tokens from email links
/// This is a technical screen that is not meant to be seen by users for long
class CleanVerifyTokenHandler extends ConsumerStatefulWidget {
  final String token;
  final String type;

  const CleanVerifyTokenHandler({
    Key? key,
    required this.token,
    required this.type,
  }) : super(key: key);

  @override
  ConsumerState<CleanVerifyTokenHandler> createState() => _CleanVerifyTokenHandlerState();
}

class _CleanVerifyTokenHandlerState extends ConsumerState<CleanVerifyTokenHandler> {
  bool _isLoading = true;
  String? _error;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _processToken();
  }

  Future<void> _processToken() async {
    try {
      if (widget.type == 'verify_email') {
        // Process email verification token
        final success = await ref.read(authNotifierProvider.notifier).verifyEmail(
          token: widget.token,
        );

        if (success) {
          setState(() {
            _isLoading = false;
            _isSuccess = true;
          });

          // Delay navigation to allow user to see success message
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              context.go('/home');
            }
          });
        } else {
          setState(() {
            _isLoading = false;
            _error = 'Failed to verify email';
          });
        }
      } else if (widget.type == 'reset_password') {
        // For reset password links, redirect to update password screen with token
        if (mounted) {
          // Navigate to update password screen with token
          context.go('/update-password?token=${widget.token}');
          return;
        }
      } else {
        // If we get here, the token type is invalid
        setState(() {
          _isLoading = false;
          _error = 'Invalid token type';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  void _goToLogin() {
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verifying'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading) ...[
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
                const SizedBox(height: 24),
                const Text('Verifying your token...'),
              ] else if (_isSuccess) ...[
                const Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: Colors.green,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Verification successful!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'You will be redirected to the home screen shortly.',
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 24),
                Text(
                  _error ?? 'Something went wrong',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _goToLogin,
                  child: const Text('Go to Login'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
