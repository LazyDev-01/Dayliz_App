import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_providers.dart';
import 'auth_prompt_dialog.dart';

/// AuthGuard widget that protects actions requiring authentication
/// Shows auth prompts for guest users, allows actions for authenticated users
class AuthGuard extends ConsumerWidget {
  final Widget child;
  final String action;
  final String? promptTitle;
  final String? promptMessage;
  final VoidCallback? onAuthRequired;
  final VoidCallback? onActionAllowed;
  final bool showPromptOnTap;

  const AuthGuard({
    Key? key,
    required this.child,
    required this.action,
    this.promptTitle,
    this.promptMessage,
    this.onAuthRequired,
    this.onActionAllowed,
    this.showPromptOnTap = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    if (!showPromptOnTap) {
      // Just return the child without any tap handling
      return child;
    }

    return GestureDetector(
      onTap: () => _handleTap(context, ref, isAuthenticated),
      child: child,
    );
  }

  void _handleTap(BuildContext context, WidgetRef ref, bool isAuthenticated) {
    if (isAuthenticated) {
      // User is authenticated, allow the action
      debugPrint('🔓 AUTH GUARD: User authenticated, allowing action: $action');
      onActionAllowed?.call();
    } else {
      // User is guest, show auth prompt
      debugPrint('🔒 AUTH GUARD: Guest user, showing auth prompt for action: $action');
      onAuthRequired?.call();
      _showAuthPrompt(context, action);
    }
  }

  void _showAuthPrompt(BuildContext context, String action) {
    // Get appropriate prompt content based on action
    final promptContent = _getPromptContent(action);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AuthPromptDialog(
        title: promptContent['title']!,
        message: promptContent['message']!,
        action: action,
        onSignIn: () {
          Navigator.of(context).pop();
          context.push('/login');
        },
        onSignUp: () {
          Navigator.of(context).pop();
          context.push('/signup');
        },
        onMaybeLater: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Map<String, String> _getPromptContent(String action) {
    switch (action) {
      case 'add_to_cart':
        return {
          'title': promptTitle ?? '🛒 Save Your Cart',
          'message': promptMessage ?? 'Sign in to save items',
        };
      case 'view_cart':
        return {
          'title': promptTitle ?? '🛒 Access Your Cart',
          'message': promptMessage ?? 'Sign in to view your cart',
        };
      case 'checkout':
        return {
          'title': promptTitle ?? '🛒 Complete Order',
          'message': promptMessage ?? 'Sign in to place your order',
        };
      case 'wishlist':
        return {
          'title': promptTitle ?? '❤️ Save Favorites',
          'message': promptMessage ?? 'Sign up to save favorites',
        };
      case 'profile':
        return {
          'title': promptTitle ?? '👤 Your Profile',
          'message': promptMessage ?? 'Create account to access profile',
        };
      case 'orders':
        return {
          'title': promptTitle ?? '📦 Your Orders',
          'message': promptMessage ?? 'Sign in to view orders',
        };
      default:
        return {
          'title': promptTitle ?? '🔐 Sign In Required',
          'message': promptMessage ?? 'Sign in to continue',
        };
    }
  }
}

/// Convenience method to check auth and show prompt if needed
class AuthGuardService {
  static bool checkAuthAndPrompt({
    required BuildContext context,
    required WidgetRef ref,
    required String action,
    String? promptTitle,
    String? promptMessage,
    VoidCallback? onAuthRequired,
  }) {
    final isAuthenticated = ref.read(isAuthenticatedProvider);

    if (isAuthenticated) {
      debugPrint('🔓 AUTH GUARD SERVICE: User authenticated, allowing action: $action');
      return true;
    } else {
      debugPrint('🔒 AUTH GUARD SERVICE: Guest user, showing auth prompt for action: $action');
      onAuthRequired?.call();

      // Get appropriate prompt content
      final promptContent = _getPromptContent(action, promptTitle, promptMessage);

      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => AuthPromptDialog(
          title: promptContent['title']!,
          message: promptContent['message']!,
          action: action,
          onSignIn: () {
            Navigator.of(context).pop();
            context.push('/login');
          },
          onSignUp: () {
            Navigator.of(context).pop();
            context.push('/signup');
          },
          onMaybeLater: () {
            Navigator.of(context).pop();
          },
        ),
      );

      return false;
    }
  }

  static Map<String, String> _getPromptContent(String action, String? promptTitle, String? promptMessage) {
    switch (action) {
      case 'add_to_cart':
        return {
          'title': promptTitle ?? '🛒 Save Your Cart',
          'message': promptMessage ?? 'Sign in to save items',
        };
      case 'view_cart':
        return {
          'title': promptTitle ?? '🛒 Access Your Cart',
          'message': promptMessage ?? 'Sign in to view your cart',
        };
      case 'checkout':
        return {
          'title': promptTitle ?? '🛒 Complete Order',
          'message': promptMessage ?? 'Sign in to place your order',
        };
      case 'wishlist':
        return {
          'title': promptTitle ?? '❤️ Save Favorites',
          'message': promptMessage ?? 'Sign up to save favorites',
        };
      case 'profile':
        return {
          'title': promptTitle ?? '👤 Your Profile',
          'message': promptMessage ?? 'Create account to access profile',
        };
      case 'orders':
        return {
          'title': promptTitle ?? '📦 Your Orders',
          'message': promptMessage ?? 'Sign in to view orders',
        };
      default:
        return {
          'title': promptTitle ?? '🔐 Sign In Required',
          'message': promptMessage ?? 'Sign in to continue',
        };
    }
  }
}
