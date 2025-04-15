import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dayliz_app/providers/auth_provider.dart';
import 'package:dayliz_app/services/auth_service.dart' show AuthException;

/// A screen that processes verification tokens from email links
/// This is a technical screen that is not meant to be seen by users for long
class VerifyTokenHandler extends ConsumerStatefulWidget {
  final String token;
  final String type;
  
  const VerifyTokenHandler({
    Key? key,
    required this.token,
    required this.type,
  }) : super(key: key);

  @override
  VerifyTokenHandlerState createState() => VerifyTokenHandlerState();
}

class VerifyTokenHandlerState extends ConsumerState<VerifyTokenHandler> {
  bool _isLoading = true;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _processToken();
  }
  
  Future<void> _processToken() async {
    try {
      if (widget.type == 'verify_email') {
        final success = await ref.read(authNotifierProvider.notifier).verifyEmail(
          token: widget.token,
        );
        
        if (success && mounted) {
          // Verification successful, navigate to home
          GoRouter.of(context).go('/home');
          return;
        }
      } else if (widget.type == 'reset_password') {
        // For reset password links, just redirect to reset password screen with token
        if (mounted) {
          GoRouter.of(context).go('/update-password?token=${widget.token}');
          return;
        }
      }
      
      // If we get here, something went wrong
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Invalid or expired token';
        });
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _error = e is AuthException 
            ? e.message 
            : 'Failed to verify token';
      });
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
        title: const Text('Verifying'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                const Text('Verifying your token...'),
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