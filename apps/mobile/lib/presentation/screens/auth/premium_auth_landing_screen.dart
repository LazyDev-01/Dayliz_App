import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../providers/auth_providers.dart';
import '../../widgets/auth/animated_background.dart';
import '../../widgets/auth/premium_auth_button.dart';
import '../../widgets/auth/auth_button_types.dart';

/// Premium authentication landing screen for Q-Commerce
/// Features modern design with optimized auth methods for grocery delivery
class PremiumAuthLandingScreen extends ConsumerStatefulWidget {
  const PremiumAuthLandingScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PremiumAuthLandingScreen> createState() => _PremiumAuthLandingScreenState();
}

class _PremiumAuthLandingScreenState extends ConsumerState<PremiumAuthLandingScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _backgroundController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _acceptTerms = true; // Default checked for user consent

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    // Setup animations
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    ));

    // Start animations
    _animationController.forward();
    _backgroundController.repeat();

    // Clear any previous auth errors
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(authNotifierProvider.notifier).clearErrors();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isLoading = ref.watch(authLoadingProvider);
    final errorMessage = ref.watch(authErrorProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Animated Background
          AnimatedBackground(
            controller: _backgroundController,
          ),
          
          // Main Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  // Top spacing
                  SizedBox(height: size.height * 0.08),
                  
                  // App Branding Section
                  Expanded(
                    flex: 2,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: _buildBrandingSection(theme),
                      ),
                    ),
                  ),

                  // Reduced spacing between slogan and buttons
                  const SizedBox(height: 20),

                  // Authentication Buttons Section
                  Expanded(
                    flex: 2, // Reduced from 3 to 2 to center buttons better
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: _buildAuthButtonsSection(isLoading),
                      ),
                    ),
                  ),
                  
                  // Error Message
                  if (errorMessage != null && errorMessage.isNotEmpty)
                    _buildErrorMessage(errorMessage, theme),
                  
                  // Bottom Section - Reduced to fix overflow
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildBottomSection(theme),
                  ),

                  const SizedBox(height: 8), // Small bottom padding
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandingSection(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // App Name (No logo needed)
        Text(
          'Dayliz',
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 42,
            letterSpacing: -1,
          ),
        ),

        const SizedBox(height: 8),

        // Tagline
        Text(
          'Daily Needs. Delivered with Ease.',
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 18,
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAuthButtonsSection(bool isLoading) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0), // Add padding for better alignment
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch, // Ensure buttons stretch to full width
        children: [
          // Phone Authentication (Primary - now transparent)
          PremiumAuthButton(
            onPressed: isLoading ? null : _handlePhoneAuth,
            icon: Icons.phone_android_rounded,
            text: 'Continue with Phone',
            backgroundColor: Colors.transparent,
            textColor: Colors.white,
            borderColor: Colors.white.withValues(alpha: 0.3),
            isLoading: isLoading,
            priority: AuthButtonPriority.tertiary,
          ),

          const SizedBox(height: 16),

          // Google Authentication (Secondary - now transparent)
          PremiumAuthButton(
            onPressed: isLoading ? null : _handleGoogleAuth,
            iconWidget: SvgPicture.asset(
              'assets/images/google_logo.svg',
              height: 24,
              width: 24,
            ),
            text: 'Continue with Google',
            backgroundColor: Colors.transparent,
            textColor: Colors.white,
            borderColor: Colors.white.withValues(alpha: 0.3),
            isLoading: isLoading,
            priority: AuthButtonPriority.tertiary,
          ),

          const SizedBox(height: 16),

          // Email Authentication (Tertiary)
          PremiumAuthButton(
            onPressed: isLoading ? null : _handleEmailAuth,
            icon: Icons.email_outlined,
            text: 'Continue with Email',
            backgroundColor: Colors.transparent,
            textColor: Colors.white,
            borderColor: Colors.white.withValues(alpha: 0.3),
            isLoading: isLoading,
            priority: AuthButtonPriority.tertiary,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(String message, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.shade600,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Guest Mode
        TextButton(
          onPressed: _handleGuestMode,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.visibility_outlined,
                color: Colors.white.withValues(alpha: 0.8),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Browse as Guest',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 12),

        // Terms and Privacy with Checkbox - Smaller text to fit in one line
        Row(
          children: [
            Transform.scale(
              scale: 0.8,
              child: Checkbox(
                value: _acceptTerms,
                onChanged: (value) {
                  setState(() {
                    _acceptTerms = value ?? false;
                  });
                },
                activeColor: Colors.white,
                checkColor: Theme.of(context).primaryColor,
                side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.7),
                  width: 1.5,
                ),
              ),
            ),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'I agree to ',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 11,
                      ),
                    ),
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: () => _showTermsAndPrivacy('terms'),
                        child: const Text(
                          'Terms',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    TextSpan(
                      text: ' & ',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 11,
                      ),
                    ),
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: () => _showTermsAndPrivacy('privacy'),
                        child: const Text(
                          'Privacy',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),
      ],
    );
  }

  // Authentication Handlers
  Future<void> _handlePhoneAuth() async {
    if (!_acceptTerms) {
      _showTermsError();
      return;
    }
    debugPrint('🔄 Phone authentication selected');
    if (mounted) {
      context.push('/phone-auth');
    }
  }

  Future<void> _handleGoogleAuth() async {
    if (!_acceptTerms) {
      _showTermsError();
      return;
    }
    debugPrint('🔄 Google authentication selected');
    try {
      await ref.read(authNotifierProvider.notifier).signInWithGoogle();

      final authState = ref.read(authNotifierProvider);
      if (authState.isAuthenticated && authState.user != null && mounted) {
        debugPrint('✅ Google Sign-in successful, navigating to home');
        context.go('/home');
      }
    } catch (e) {
      debugPrint('❌ Google Sign-in error: $e');
    }
  }

  Future<void> _handleEmailAuth() async {
    if (!_acceptTerms) {
      _showTermsError();
      return;
    }
    debugPrint('🔄 Email authentication selected');
    if (mounted) {
      context.push('/login');
    }
  }

  void _handleGuestMode() {
    debugPrint('🔄 Guest mode selected');
    if (mounted) {
      context.go('/home');
    }
  }

  void _showTermsError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Please accept Terms & Conditions to continue'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showTermsAndPrivacy(String type) {
    debugPrint('🔄 Showing $type');
    if (type == 'privacy') {
      context.push('/privacy-policy');
    } else if (type == 'terms') {
      context.push('/terms-of-service');
    }
  }
}


