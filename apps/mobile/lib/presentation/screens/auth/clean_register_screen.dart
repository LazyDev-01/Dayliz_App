import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lottie/lottie.dart';

import '../../providers/auth_providers.dart';
import '../../widgets/auth/auth_background.dart';
import '../../../core/utils/constants.dart';


/// Clean architecture registration screen that uses Riverpod for state management
class CleanRegisterScreen extends ConsumerStatefulWidget {
  const CleanRegisterScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CleanRegisterScreen> createState() => _CleanRegisterScreenState();
}

class _CleanRegisterScreenState extends ConsumerState<CleanRegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Step management
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 2;

  // Animation controllers
  late AnimationController _slideAnimationController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _fadeAnimationController;
  late Animation<double> _fadeAnimation;

  // Focus nodes for better UX
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _registerError;
  String? _emailError;

  // Flag to track if we've shown the success dialog
  bool _hasShownSuccessDialog = false;

  // Flag to prevent multiple registration attempts
  bool _isRegistering = false;

  // Flag to check email existence
  bool _isCheckingEmail = false;

  // Flag to show Lottie animation instead of dialog
  bool _showLottieSuccess = false;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _slideAnimationController = AnimationController(
      duration: AppConstants.defaultAnimationDuration,
      vsync: this,
    );

    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    // Initialize animations
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeIn,
    ));

    // Start fade animation
    _fadeAnimationController.forward();

    // CRITICAL FIX: Remove auth state listener that causes premature navigation
    // Success dialog will be handled directly in _handleRegister method
    debugPrint('REGISTER: Screen initialized');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _pageController.dispose();
    _slideAnimationController.dispose();
    _fadeAnimationController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showLottieSuccess) {
      return _buildLottieSuccessScreen();
    }

    return AuthBackground(
      showBackButton: _currentStep > 0,
      onBackPressed: () => _goToPreviousStep(),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (index) {
            setState(() {
              _currentStep = index;
            });
          },
          children: [
            _buildStep1(),
            _buildStep2(),
          ],
        ),
      ),
    );
  }

  // Step navigation methods
  void _goToPreviousStep() {
    if (_currentStep > 0) {
      _slideAnimationController.reverse().then((_) {
        _pageController.previousPage(
          duration: AppConstants.defaultAnimationDuration,
          curve: Curves.easeInOut,
        );
        _slideAnimationController.forward();
      });
    }
  }

  void _goToNextStep() {
    if (_currentStep < _totalSteps - 1) {
      _slideAnimationController.reverse().then((_) {
        _pageController.nextPage(
          duration: AppConstants.defaultAnimationDuration,
          curve: Curves.easeInOut,
        );
        _slideAnimationController.forward();
      });
    }
  }



  // Step 1: Name and Email
  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),

          // App logo/icon
          Icon(
            Icons.person_add_outlined,
            size: 60,
            color: Colors.white,
          ),

          const SizedBox(height: 16),

          // Join Dayliz text
          Text(
            'Join Dayliz',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),

          // UI/UX FIX: Removed "Create a new account" subtitle as requested

          const SizedBox(height: 40),

          // Name field
          _buildAnimatedTextField(
            controller: _nameController,
            focusNode: _nameFocusNode,
            label: 'Full Name',
            hint: 'Enter your full name',
            icon: Icons.person_outline,
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
          ),

          const SizedBox(height: 20),

          // Email field
          _buildAnimatedTextField(
            controller: _emailController,
            focusNode: _emailFocusNode,
            label: 'Email Address',
            hint: 'Enter your email address',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            errorText: _emailError,
          ),

          const SizedBox(height: 40),

          // Continue button
          _buildContinueButton(),

          const SizedBox(height: 20),

          const SizedBox(height: 20),

          // Login option
          _buildLoginOption(),
        ],
      ),
    );
  }

  // Step 2: Passwords - REDESIGNED for clean, professional look
  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),

          // Clean, minimal header
          const Text(
            'Set Your Password',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2E2E2E),
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 50),

          // Password field - clean design
          _buildCleanPasswordField(
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            label: 'Password',
            hint: 'Enter your password',
            obscureText: _obscurePassword,
            onToggleVisibility: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),

          const SizedBox(height: 24),

          // Confirm password field - clean design
          _buildCleanPasswordField(
            controller: _confirmPasswordController,
            focusNode: _confirmPasswordFocusNode,
            label: 'Confirm Password',
            hint: 'Confirm your password',
            obscureText: _obscureConfirmPassword,
            onToggleVisibility: () {
              setState(() {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              });
            },
          ),

          const SizedBox(height: 16),

          // Minimal password requirements
          _buildPasswordRequirements(),

          const SizedBox(height: 40),

          // Professional create account button
          _buildProfessionalCreateButton(),
        ],
      ),
    );
  }

  // Clean password field design for Step 2
  Widget _buildCleanPasswordField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
  }) {
    return AnimatedBuilder(
      animation: focusNode,
      builder: (context, child) {
        final isFocused = focusNode.hasFocus;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: isFocused
                    ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.02),
                blurRadius: isFocused ? 8 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            obscureText: obscureText,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2E2E2E),
            ),
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              prefixIcon: Icon(
                Icons.lock_outline,
                color: isFocused ? const Color(0xFF4CAF50) : const Color(0xFF9E9E9E),
                size: 22,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: const Color(0xFF9E9E9E),
                  size: 22,
                ),
                onPressed: onToggleVisibility,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE57373), width: 2),
              ),
              filled: true,
              fillColor: const Color(0xFFFAFAFA),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              labelStyle: TextStyle(
                color: isFocused ? const Color(0xFF4CAF50) : const Color(0xFF9E9E9E),
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              hintStyle: const TextStyle(
                color: Color(0xFFBDBDBD),
                fontSize: 14,
              ),
            ),
          ),
        );
      },
    );
  }

  // Minimal password requirements display
  Widget _buildPasswordRequirements() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            size: 16,
            color: Color(0xFF6C757D),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Use 8+ characters with uppercase, lowercase, number & symbol',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Professional create account button
  Widget _buildProfessionalCreateButton() {
    final isLoading = _isRegistering || ref.watch(authLoadingProvider);

    return Column(
      children: [
        // Error message with clean design
        if (_registerError != null)
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5F5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFCDD2)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Color(0xFFE53E3E),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _registerError!,
                    style: const TextStyle(
                      color: Color(0xFFE53E3E),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Professional button with comfortable spacing
        AnimatedContainer(
          duration: AppConstants.defaultAnimationDuration,
          child: ElevatedButton(
            onPressed: isLoading ? null : _handleRegister,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              shadowColor: const Color(0xFF4CAF50).withValues(alpha: 0.3),
              minimumSize: const Size(double.infinity, 52),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // Animated text field with modern styling
  Widget _buildAnimatedTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextCapitalization? textCapitalization,
    bool isPassword = false,
    bool? obscureText,
    VoidCallback? onToggleVisibility,
    String? errorText,
    String? helperText,
  }) {
    return AnimatedBuilder(
      animation: focusNode,
      builder: (context, child) {
        final isFocused = focusNode.hasFocus;
        return AnimatedContainer(
          duration: AppConstants.defaultAnimationDuration,
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: const Color(0xFF4CAF50).withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: keyboardType,
                textCapitalization: textCapitalization ?? TextCapitalization.none,
                obscureText: obscureText ?? false,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  labelText: label,
                  hintText: hint,
                  prefixIcon: Icon(
                    icon,
                    color: isFocused ? const Color(0xFF4CAF50) : Colors.grey[600],
                  ),
                  suffixIcon: isPassword
                      ? IconButton(
                          icon: Icon(
                            obscureText == true ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey[600],
                          ),
                          onPressed: onToggleVisibility,
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  labelStyle: TextStyle(
                    color: isFocused ? const Color(0xFF4CAF50) : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  helperText: helperText,
                  helperMaxLines: 2,
                  helperStyle: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                  errorStyle: const TextStyle(height: 0, fontSize: 0),
                ),
              ),
              if (errorText != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6.0, left: 12.0),
                  child: Text(
                    errorText,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12.0,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // Continue button for Step 1 - Updated for comfortable spacing
  Widget _buildContinueButton() {
    return AnimatedContainer(
      duration: AppConstants.defaultAnimationDuration,
      child: ElevatedButton(
        onPressed: _isCheckingEmail ? null : _validateStep1AndContinue,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
        ),
        child: _isCheckingEmail
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Continue',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }

  // Create account button for Step 2
  Widget _buildCreateAccountButton() {
    final isLoading = _isRegistering || ref.watch(authLoadingProvider);

    return Column(
      children: [
        // Error message
        if (_registerError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Text(
                _registerError!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          ),

        // Create account button
        AnimatedContainer(
          duration: AppConstants.defaultAnimationDuration,
          child: ElevatedButton(
            onPressed: isLoading ? null : _handleRegister,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              shadowColor: const Color(0xFF4CAF50).withOpacity(0.3),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // Step 1 validation and navigation
  Future<void> _validateStep1AndContinue() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    // Clear previous errors
    setState(() {
      _emailError = null;
    });

    // Validate name
    if (name.isEmpty) {
      _showValidationError('Please enter your name');
      _nameFocusNode.requestFocus();
      return;
    } else if (name.length < 2) {
      _showValidationError('Name must be at least 2 characters');
      _nameFocusNode.requestFocus();
      return;
    }

    // Validate email format
    if (email.isEmpty) {
      _showValidationError('Please enter your email address');
      _emailFocusNode.requestFocus();
      return;
    } else if (!isValidEmail(email)) {
      _showValidationError('Please enter a valid email address');
      _emailFocusNode.requestFocus();
      return;
    }

    // Check if email already exists before proceeding to Step 2
    await _checkEmailExistence(email);
  }

  // Check if email is already registered
  Future<void> _checkEmailExistence(String email) async {
    try {
      debugPrint('Checking if email exists: $email');

      // Show loading state on continue button
      setState(() {
        _isCheckingEmail = true;
      });

      // Check if email already exists using the auth provider
      final emailExists = await ref.read(authNotifierProvider.notifier).checkEmailExists(email);

      setState(() {
        _isCheckingEmail = false;
      });

      if (emailExists) {
        // Email already exists, show error message
        _showValidationError('Email id already registered! Try different.');
        _emailFocusNode.requestFocus();
        return;
      }

      // Email doesn't exist, proceed to Step 2
      _goToNextStep();
      Future.delayed(AppConstants.defaultAnimationDuration, () {
        _passwordFocusNode.requestFocus();
      });

    } catch (e) {
      debugPrint('Error in email check: $e');

      setState(() {
        _isCheckingEmail = false;
      });

      // Check if it's a network connectivity issue
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('socketexception') ||
          errorString.contains('failed host lookup') ||
          errorString.contains('network') ||
          errorString.contains('connection')) {

        // Show network error dialog with options
        _showNetworkErrorDialog(email);
        return;
      }

      // For other errors, proceed to Step 2 to avoid blocking the user
      _goToNextStep();
      Future.delayed(AppConstants.defaultAnimationDuration, () {
        _passwordFocusNode.requestFocus();
      });
    }
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showNetworkErrorDialog(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.orange),
              SizedBox(width: 8),
              Text('Network Error'),
            ],
          ),
          content: const Text(
            'Unable to verify email due to network connectivity issues. '
            'Please check your internet connection and try again.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Retry email check
                _checkEmailExistence(email);
              },
              child: const Text('Retry'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Proceed anyway (skip email check)
                _goToNextStep();
                Future.delayed(AppConstants.defaultAnimationDuration, () {
                  _passwordFocusNode.requestFocus();
                });
              },
              child: const Text('Continue Anyway'),
            ),
          ],
        );
      },
    );
  }

  // Lottie success screen
  Widget _buildLottieSuccessScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // TODO: Add Lottie animation here
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 80,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Account Created!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Welcome to Dayliz! Your account has been created successfully.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                context.go('/home');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Get Started',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
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
        // UI/UX FIX: Removed "Create a new account" text as requested
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
            // UI/UX FIX: Remove validator to prevent form clearing
            // Validation is now done manually in _handleRegister() method
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
                // UI/UX FIX: Remove validator to prevent form clearing
                // Validation is now done manually in _handleRegister() method
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
            // UI/UX FIX: Remove validator to prevent form clearing
            // Validation is now done manually in _handleRegister() method
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
            // UI/UX FIX: Remove validator to prevent form clearing
            // Validation is now done manually in _handleRegister() method
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterButton() {
    // Watch loading state for button-specific loading indicator
    final isLoading = _isRegistering || ref.watch(authLoadingProvider);

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
          onPressed: isLoading ? null : _handleRegister, // Disable button when loading
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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





  Widget _buildLoginOption() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account?',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 16,
          ),
        ),
        TextButton(
          onPressed: () {
            // Check if we're already authenticated
            final authState = ref.read(authNotifierProvider);
            if (authState.isAuthenticated && authState.user != null) {
              // If authenticated, navigate to home
              context.go('/home');
            } else {
              // SMOOTH TRANSITION FIX: Use Navigator.pop() for smooth back transition
              // This provides the smooth slide-back animation when returning to login
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                // Fallback to context.go if no previous route exists
                context.go('/login');
              }
            }
          },
          child: const Text(
            'Sign In',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
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

  /// Email validation helper function
  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }



  // ENHANCED FIX: Show success dialog with improved navigation handling
  void _showSuccessDialog(BuildContext context) {
    debugPrint('ENHANCED FIX: Showing success dialog');

    // Show a full-screen dialog that can't be dismissed by tapping outside
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withAlpha(128),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) {
        return PopScope(
          // Prevent back button from dismissing the dialog
          canPop: false,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 70,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Success!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Account created successfully!',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        debugPrint('ENHANCED FIX: User clicked Continue to Home');

                        // Capture context before async operation
                        final navigator = Navigator.of(context);
                        final router = GoRouter.of(context);

                        // Close the dialog first
                        navigator.pop();

                        // ENHANCED FIX: Add a small delay to ensure dialog closes properly
                        // before navigation to prevent router conflicts
                        Future.delayed(const Duration(milliseconds: 100), () {
                          if (mounted) {
                            debugPrint('ENHANCED FIX: Navigating to home screen after dialog close');
                            router.go('/home');
                          }
                        });
                      },
                      child: const Text(
                        'Continue to Home',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleRegister() async {
    // Prevent multiple registration attempts
    if (_isRegistering) {
      debugPrint('UI/UX FIX: Already processing registration, ignoring duplicate request');
      return;
    }

    // Clear any previous errors
    setState(() {
      _registerError = null;
      _emailError = null;
    });

    // Reset the success dialog flag
    _hasShownSuccessDialog = false;

    // UI/UX CRITICAL FIX: Store form values BEFORE validation to prevent clearing
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    debugPrint('UI/UX FIX: Form values captured - email: $email, name: $name');

    // UI/UX CRITICAL FIX: Manual validation without triggering form rebuild
    String? nameError;
    String? emailError;
    String? passwordError;
    String? confirmPasswordError;

    // Validate name
    if (name.isEmpty) {
      nameError = 'Please enter your name';
    } else if (name.length < 2) {
      nameError = 'Name must be at least 2 characters';
    }

    // Validate email
    if (email.isEmpty) {
      emailError = 'Please enter your email address';
    } else if (!isValidEmail(email)) {
      emailError = 'Please enter a valid email address';
    }

    // Validate password
    if (password.isEmpty) {
      passwordError = 'Please enter your password';
    } else if (!_isPasswordValid(password)) {
      passwordError = 'Password must contain lowercase, uppercase, number, and special character';
    }

    // Validate confirm password
    if (confirmPassword.isEmpty) {
      confirmPasswordError = 'Please confirm your password';
    } else if (confirmPassword != password) {
      confirmPasswordError = 'Passwords do not match';
    }

    // If there are validation errors, show them without clearing the form
    if (nameError != null || emailError != null ||
        passwordError != null || confirmPasswordError != null) {
      debugPrint('UI/UX FIX: Manual validation failed');

      // Show validation errors via SnackBar
      final errorMessage = nameError ?? emailError ??
                          passwordError ?? confirmPasswordError ?? 'Please check your input';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // Manual validation passed, proceed with registration
      // Double-check password requirements
      if (!_isPasswordValid(password)) {
        setState(() {
          _registerError = 'Password must contain at least one lowercase letter, one uppercase letter, one number, and one special character.';
        });
        // Restore form values after error
        _nameController.text = name;
        _emailController.text = email;
        _passwordController.text = password;
        _confirmPasswordController.text = confirmPassword;
        return;
      }

      // Set registering flag to prevent duplicate attempts
      setState(() {
        _isRegistering = true;
      });

      // UI/UX CRITICAL FIX: Restore form values immediately after state change
      // This ensures the form stays filled during the loading process
      _nameController.text = name;
      _emailController.text = email;
      _passwordController.text = password;
      _confirmPasswordController.text = confirmPassword;

      try {
        debugPrint('CleanRegisterScreen: Starting registration process');
        debugPrint('CleanRegisterScreen: email = $email');
        debugPrint('CleanRegisterScreen: name = $name');

        // CRITICAL FIX: First check if the auth state is already authenticated
        // If it is, sign out before attempting registration
        final authState = ref.read(authNotifierProvider);
        if (authState.isAuthenticated) {
          debugPrint('CleanRegisterScreen: User is already authenticated, signing out first');
          try {
            // Sign out directly using Supabase
            await Supabase.instance.client.auth.signOut();
            debugPrint('CleanRegisterScreen: Signed out successfully');
          } catch (e) {
            debugPrint('CleanRegisterScreen: Error signing out: $e');
          }
        }

        // Attempt registration
        debugPrint('CleanRegisterScreen: Calling authNotifierProvider.register');
        await ref.read(authNotifierProvider.notifier).register(
          email,
          password,
          name,
        );
        debugPrint('CleanRegisterScreen: register call completed');

        // Hide loading indicator
        setState(() {
          _isRegistering = false;
        });

        // CRITICAL FIX: Check if there was an error message set during registration
        // This would indicate a duplicate email or other registration error
        final updatedAuthState = ref.read(authNotifierProvider);
        if (updatedAuthState.errorMessage != null && updatedAuthState.errorMessage!.isNotEmpty) {
          debugPrint('CleanRegisterScreen: Registration error: ${updatedAuthState.errorMessage}');

          // Check if it's a duplicate email error
          final errorMsg = updatedAuthState.errorMessage!.toLowerCase();
          if (errorMsg.contains('already registered') ||
              errorMsg.contains('email is already') ||
              errorMsg.contains('email already') ||
              errorMsg.contains('already exists') ||
              errorMsg.contains('duplicate') ||
              errorMsg.contains('already in use')) {

            setState(() {
              _emailError = 'Email id already exists!';
              // Trigger validation to show the error
              _formKey.currentState?.validate();
            });
            // Restore form values after error
            _nameController.text = name;
            _emailController.text = email;
            _passwordController.text = password;
            _confirmPasswordController.text = confirmPassword;
            return;
          } else {
            // For other errors, show in the general error area
            setState(() {
              _registerError = updatedAuthState.errorMessage;
            });
            // Restore form values after error
            _nameController.text = name;
            _emailController.text = email;
            _passwordController.text = password;
            _confirmPasswordController.text = confirmPassword;
            return;
          }
        }

        // CRITICAL FIX: Check if registration was successful and show Lottie animation
        if (updatedAuthState.isAuthenticated && updatedAuthState.user != null) {
          debugPrint('REGISTER: Success! Showing Lottie animation');

          if (mounted && !_hasShownSuccessDialog) {
            _hasShownSuccessDialog = true;
            // Show Lottie success animation instead of dialog
            setState(() {
              _showLottieSuccess = true;
            });

            // Auto-navigate to home after 3 seconds
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted) {
                context.go('/home');
              }
            });
          }
        } else {
          debugPrint('REGISTER: Completed but user not authenticated');
          setState(() {
            _registerError = 'Account created successfully! Please sign in.';
          });
        }
      } catch (e) {
        debugPrint('Registration error: $e');
        // Hide loading indicator
        setState(() {
          _isRegistering = false;
        });

        // Show error in UI
        setState(() {
          String errorMsg = e.toString().toLowerCase();
          debugPrint('Processing error message: $errorMsg');

          // ENHANCED: More comprehensive check for duplicate email errors
          if (errorMsg.contains('already registered') ||
              errorMsg.contains('email is already') ||
              errorMsg.contains('email already') ||
              errorMsg.contains('already exists') ||
              errorMsg.contains('duplicate') ||
              errorMsg.contains('already in use') ||
              errorMsg.contains('already signed up') ||
              errorMsg.contains('already has an account') ||
              errorMsg.contains('email exists') ||
              errorMsg.contains('user exists') ||
              errorMsg.contains('exists') && errorMsg.contains('email')) {
            debugPrint('Detected duplicate email error');
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
        // Restore form values after any error
        _nameController.text = name;
        _emailController.text = email;
        _passwordController.text = password;
        _confirmPasswordController.text = confirmPassword;
      } finally {
        // Reset registering flag
        setState(() {
          _isRegistering = false;
        });
      }

      // CRITICAL FIX: No fallback logic needed - success dialog handled directly above
      debugPrint('REGISTER: Registration process complete');
  }
}