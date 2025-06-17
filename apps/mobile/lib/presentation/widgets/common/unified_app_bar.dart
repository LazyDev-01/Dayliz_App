import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'svg_icon_button.dart';
import '../../../core/constants/app_colors.dart';
import 'animated_cloud_background.dart';

/// Unified app bar system for consistent design across all screens
/// 
/// Design Specifications:
/// - White background
/// - Shadow effect
/// - Dark grey text for titles
/// - Two types of back buttons: previous page & direct home
class UnifiedAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// The title text to display
  final String title;
  
  /// Whether to show a back button
  final bool showBackButton;
  
  /// Type of back button navigation
  final BackButtonType backButtonType;
  
  /// Custom back button callback (overrides default behavior)
  final VoidCallback? onBackPressed;
  
  /// Fallback route for standard back navigation
  final String fallbackRoute;
  
  /// Actions to display on the right side
  final List<Widget>? actions;
  
  /// Whether to center the title
  final bool centerTitle;
  
  /// Custom leading widget (overrides back button)
  final Widget? leading;
  
  /// Bottom widget (e.g., TabBar)
  final PreferredSizeWidget? bottom;

  /// Whether to show shadow effect
  final bool showShadow;

  const UnifiedAppBar({
    Key? key,
    required this.title,
    this.showBackButton = true,
    this.backButtonType = BackButtonType.previousPage,
    this.onBackPressed,
    this.fallbackRoute = '/home',
    this.actions,
    this.centerTitle = true,
    this.leading,
    this.bottom,
    this.showShadow = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: showShadow ? [
          const BoxShadow(
            color: Color(0x1A000000), // 10% black opacity for subtle shadow
            offset: Offset(0, 2),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ] : null,
      ),
      child: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF374151), // Dark grey color (Tailwind gray-700)
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.15,
          ),
        ),
        centerTitle: centerTitle,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF374151),
        elevation: 0, // Remove default elevation since we use custom shadow
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: _buildLeading(context),
        actions: actions,
        bottom: bottom,
        iconTheme: const IconThemeData(
          color: Color(0xFF374151), // Dark grey for icons
        ),
        actionsIconTheme: const IconThemeData(
          color: Color(0xFF374151), // Dark grey for action icons
        ),
      ),
    );
  }

  /// Builds the leading widget (back button or custom widget)
  Widget? _buildLeading(BuildContext context) {
    if (leading != null) {
      return leading;
    }

    if (!showBackButton) {
      return null;
    }

    switch (backButtonType) {
      case BackButtonType.previousPage:
        return SvgIconButtons.back(
          onPressed: onBackPressed ?? () => _handlePreviousPageNavigation(context),
          tooltip: 'Back',
        );
      case BackButtonType.directHome:
        return SvgIconButtons.back(
          onPressed: onBackPressed ?? () => _handleDirectHomeNavigation(context),
          tooltip: 'Back to Home',
        );
    }
  }

  /// Handles previous page navigation with fallback
  void _handlePreviousPageNavigation(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      // If can't pop, go to fallback route
      context.go(fallbackRoute);
    }
  }

  /// Handles direct home navigation
  void _handleDirectHomeNavigation(BuildContext context) {
    context.go('/home');
  }

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + (bottom?.preferredSize.height ?? 0),
  );
}

/// Enum for different back button navigation types
enum BackButtonType {
  /// Standard back navigation to previous page
  previousPage,

  /// Direct navigation to home screen
  directHome,
}

/// Enum for different cloud animation types
enum CloudAnimationType {
  /// Subtle clouds for general screens
  subtle,

  /// Prominent clouds for feature highlights
  prominent,

  /// Dense clouds for special events
  dense,

  /// Peaceful clouds for home screen
  peaceful,
}

/// Factory methods for creating unified app bars for common use cases
class UnifiedAppBars {
  /// Creates a simple app bar with title only (no back button)
  static UnifiedAppBar simple({
    required String title,
    List<Widget>? actions,
    bool centerTitle = true,
    PreferredSizeWidget? bottom,
    bool showShadow = true,
  }) {
    return UnifiedAppBar(
      title: title,
      showBackButton: false,
      actions: actions,
      centerTitle: centerTitle,
      bottom: bottom,
      showShadow: showShadow,
    );
  }

  /// Creates an app bar with standard back navigation (previous page)
  static UnifiedAppBar withBackButton({
    required String title,
    String fallbackRoute = '/home',
    VoidCallback? onBackPressed,
    List<Widget>? actions,
    bool centerTitle = true,
    PreferredSizeWidget? bottom,
  }) {
    return UnifiedAppBar(
      title: title,
      showBackButton: true,
      backButtonType: BackButtonType.previousPage,
      fallbackRoute: fallbackRoute,
      onBackPressed: onBackPressed,
      actions: actions,
      centerTitle: centerTitle,
      bottom: bottom,
    );
  }

  /// Creates an app bar with standard back navigation (previous page) without shadow
  static UnifiedAppBar withBackButtonNoShadow({
    required String title,
    String fallbackRoute = '/home',
    VoidCallback? onBackPressed,
    List<Widget>? actions,
    bool centerTitle = true,
    PreferredSizeWidget? bottom,
  }) {
    return UnifiedAppBar(
      title: title,
      showBackButton: true,
      backButtonType: BackButtonType.previousPage,
      fallbackRoute: fallbackRoute,
      onBackPressed: onBackPressed,
      actions: actions,
      centerTitle: centerTitle,
      bottom: bottom,
      showShadow: false,
    );
  }

  /// Creates an app bar with direct home navigation
  static UnifiedAppBar withHomeButton({
    required String title,
    VoidCallback? onBackPressed,
    List<Widget>? actions,
    bool centerTitle = true,
    PreferredSizeWidget? bottom,
  }) {
    return UnifiedAppBar(
      title: title,
      showBackButton: true,
      backButtonType: BackButtonType.directHome,
      onBackPressed: onBackPressed,
      actions: actions,
      centerTitle: centerTitle,
      bottom: bottom,
    );
  }

  /// Creates an app bar with search functionality
  static UnifiedAppBar withSearch({
    required String title,
    required VoidCallback onSearchPressed,
    BackButtonType backButtonType = BackButtonType.previousPage,
    String fallbackRoute = '/home',
    VoidCallback? onBackPressed,
    List<Widget>? additionalActions,
    bool centerTitle = true,
  }) {
    final actions = <Widget>[
      SvgIconButtons.search(
        onPressed: onSearchPressed,
        tooltip: 'Search',
      ),
      if (additionalActions != null) ...additionalActions,
    ];

    return UnifiedAppBar(
      title: title,
      showBackButton: true,
      backButtonType: backButtonType,
      fallbackRoute: fallbackRoute,
      onBackPressed: onBackPressed,
      actions: actions,
      centerTitle: centerTitle,
    );
  }

  /// Creates an app bar with cart functionality
  static UnifiedAppBar withCart({
    required String title,
    required VoidCallback onCartPressed,
    int? cartItemCount,
    BackButtonType backButtonType = BackButtonType.previousPage,
    String fallbackRoute = '/home',
    VoidCallback? onBackPressed,
    List<Widget>? additionalActions,
    bool centerTitle = true,
  }) {
    final actions = <Widget>[
      SvgIconButtons.cart(
        onPressed: onCartPressed,
        badgeCount: cartItemCount,
        tooltip: 'Shopping Cart',
      ),
      if (additionalActions != null) ...additionalActions,
    ];

    return UnifiedAppBar(
      title: title,
      showBackButton: true,
      backButtonType: backButtonType,
      fallbackRoute: fallbackRoute,
      onBackPressed: onBackPressed,
      actions: actions,
      centerTitle: centerTitle,
    );
  }

  /// Creates an app bar with both search and cart functionality
  static UnifiedAppBar withSearchAndCart({
    required String title,
    required VoidCallback onSearchPressed,
    required VoidCallback onCartPressed,
    int? cartItemCount,
    BackButtonType backButtonType = BackButtonType.previousPage,
    String fallbackRoute = '/home',
    VoidCallback? onBackPressed,
    List<Widget>? additionalActions,
    bool centerTitle = true,
  }) {
    final actions = <Widget>[
      SvgIconButtons.search(
        onPressed: onSearchPressed,
        tooltip: 'Search',
      ),
      SvgIconButtons.cart(
        onPressed: onCartPressed,
        badgeCount: cartItemCount,
        tooltip: 'Shopping Cart',
      ),
      if (additionalActions != null) ...additionalActions,
    ];

    return UnifiedAppBar(
      title: title,
      showBackButton: true,
      backButtonType: backButtonType,
      fallbackRoute: fallbackRoute,
      onBackPressed: onBackPressed,
      actions: actions,
      centerTitle: centerTitle,
    );
  }

  /// Creates the home screen app bar with enhanced profile icon, search bar, and cloud animation
  ///
  /// This preserves all the original home screen features while using the unified system:
  /// - Enhanced profile icon with animations
  /// - Integrated search bar with custom styling
  /// - Gradient background (green to yellow)
  /// - Optional cloud animations
  /// - "Dayliz" branding with custom typography
  static PreferredSizeWidget homeScreen({
    required VoidCallback onSearchTap,
    required VoidCallback onProfileTap,
    String? userPhotoUrl,
    String searchHint = 'Search for products...',
    bool enableCloudAnimation = false,
    CloudAnimationType cloudType = CloudAnimationType.peaceful,
    Color? cloudColor,
    double cloudOpacity = 0.15,
  }) {
    return _UnifiedHomeAppBar(
      onSearchTap: onSearchTap,
      onProfileTap: onProfileTap,
      userPhotoUrl: userPhotoUrl,
      searchHint: searchHint,
      enableCloudAnimation: enableCloudAnimation,
      cloudType: cloudType,
      cloudColor: cloudColor ?? Colors.white,
      cloudOpacity: cloudOpacity,
    );
  }
}

/// Unified Home App Bar that preserves all original home screen features
/// while integrating with the unified app bar system
class _UnifiedHomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onSearchTap;
  final VoidCallback onProfileTap;
  final String? userPhotoUrl;
  final String searchHint;
  final bool enableCloudAnimation;
  final CloudAnimationType cloudType;
  final Color cloudColor;
  final double cloudOpacity;

  const _UnifiedHomeAppBar({
    required this.onSearchTap,
    required this.onProfileTap,
    this.userPhotoUrl,
    required this.searchHint,
    required this.enableCloudAnimation,
    required this.cloudType,
    required this.cloudColor,
    required this.cloudOpacity,
  });

  @override
  Widget build(BuildContext context) {
    // Enhanced profile icon with sophisticated design
    final profileIcon = _UnifiedEnhancedProfileIcon(
      userPhotoUrl: userPhotoUrl,
      onTap: onProfileTap,
    );

    // Create the actions list with the enhanced profile icon
    final actions = <Widget>[
      // Enhanced profile icon button with increased spacing
      Padding(
        padding: const EdgeInsets.only(right: 20.0), // Increased right padding
        child: profileIcon,
      ),
    ];

    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 80), // Reduced size since no category icons
      child: Container(
        decoration: BoxDecoration(
          // Fresh Green to Sunny Yellow - 120deg linear gradient for better balance
          gradient: const LinearGradient(
            begin: Alignment(-0.8, -1.0), // 120 degrees equivalent
            end: Alignment(0.8, 1.0),
            colors: [
              Color(0xFFB5E853), // Slightly brighter fresh green
              Color(0xFFFFD54F), // Slightly brighter sunny yellow
            ],
          ),
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(16), // Increased radius for modern look
          ),
          boxShadow: [
            // Fresh green shadow for depth
            BoxShadow(
              color: Color(0xFFB5E853).withAlpha(20),
              blurRadius: 18,
              offset: const Offset(0, 6),
              spreadRadius: 0,
            ),
            // Sunny yellow glow effect
            BoxShadow(
              color: Color(0xFFFFD54F).withAlpha(25),
              blurRadius: 28,
              offset: const Offset(0, 3),
              spreadRadius: -4,
            ),
            // Light highlight
            BoxShadow(
              color: Colors.white.withAlpha(60),
              blurRadius: 1,
              offset: const Offset(0, 1),
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
          child: Builder(
            builder: (context) {
              final mediaQuery = MediaQuery.of(context);
              final statusBarHeight = mediaQuery.padding.top;

              // Calculate dynamic spacing based on status bar height - increased for less clutter
              final topSpacing = statusBarHeight > 24 ? 16.0 : 12.0;

              final appBar = AppBar(
                title: Container(
                  margin: EdgeInsets.only(top: topSpacing), // Add top margin for breathing room
                  child: const Text(
                    'Dayliz',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 24,
                      color: Color(0xFF1F2937), // Dark gray for excellent contrast
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                centerTitle: false,
                backgroundColor: Colors.transparent, // Let gradient show through
                foregroundColor: const Color(0xFF1F2937), // Dark gray icons for excellent contrast
                elevation: 0,
                shadowColor: Colors.transparent,
                actions: actions.map((action) {
                  // Add top margin to actions (profile icon) for consistent spacing
                  return Container(
                    margin: EdgeInsets.only(top: topSpacing),
                    child: action,
                  );
                }).toList(),
                toolbarHeight: kToolbarHeight + 16, // Adjusted to match profile icon proportions
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(60), // Reduced to just accommodate search bar
                  child: Column(
                    children: [
                      // Search bar section
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12), // Reduced bottom padding
                        child: GestureDetector(
                          onTap: onSearchTap,
                          child: Container(
                            height: 44, // Matches profile icon size
                            decoration: BoxDecoration(
                              // Enhanced search bar with better contrast
                              color: Colors.white.withAlpha(242), // rgba(255, 255, 255, 0.95)
                              borderRadius: BorderRadius.circular(14), // More rounded for modern look
                              border: Border.all(
                                color: Colors.white.withAlpha(150), // Slightly more visible border
                                width: 1.0, // Thinner border for cleaner look
                              ),
                              boxShadow: [
                                // Enhanced shadow for depth - 0 2px 6px rgba(0, 0, 0, 0.08)
                                BoxShadow(
                                  color: Colors.black.withAlpha(20), // rgba(0, 0, 0, 0.08)
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                  spreadRadius: 0,
                                ),
                                // Inner highlight for premium feel
                                BoxShadow(
                                  color: Colors.white.withAlpha(120),
                                  blurRadius: 1,
                                  offset: const Offset(0, 1),
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 14),
                                const Icon(
                                  Icons.search_rounded, // More modern rounded search icon
                                  color: Color(0xFF1F2937), // Dark gray for contrast
                                  size: 22, // Slightly larger for better visibility
                                ),
                                const SizedBox(width: 14),
                                Text(
                                  searchHint,
                                  style: const TextStyle(
                                    color: Color(0xFF6B7280), // Neutral gray for placeholder text
                                    fontSize: 16, // Better readability
                                    fontWeight: FontWeight.w500, // Medium weight for premium feel
                                    letterSpacing: 0.2, // Subtle letter spacing
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );

              if (enableCloudAnimation) {
                return Stack(
                  children: [
                    appBar,
                    // Animated cloud background overlay
                    Positioned.fill(
                      child: _buildCloudBackground(),
                    ),
                  ],
                );
              } else {
                return appBar;
              }
            },
          ),
        ),
      ),
    );
  }

  /// Builds the cloud background based on the selected type
  Widget _buildCloudBackground() {
    switch (cloudType) {
      case CloudAnimationType.subtle:
        return CloudBackgrounds.subtle(
          cloudColor: cloudColor,
          opacity: cloudOpacity,
        );
      case CloudAnimationType.prominent:
        return CloudBackgrounds.prominent(
          cloudColor: cloudColor,
          opacity: cloudOpacity,
        );
      case CloudAnimationType.dense:
        return CloudBackgrounds.dense(
          cloudColor: cloudColor,
          opacity: cloudOpacity,
        );
      case CloudAnimationType.peaceful:
        return CloudBackgrounds.peaceful(
          cloudColor: cloudColor,
          opacity: cloudOpacity,
        );
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 80);
}

/// Enhanced profile icon widget with sophisticated design and animations
/// Unified version that preserves all original functionality
class _UnifiedEnhancedProfileIcon extends StatefulWidget {
  final String? userPhotoUrl;
  final VoidCallback onTap;

  const _UnifiedEnhancedProfileIcon({
    required this.userPhotoUrl,
    required this.onTap,
  });

  @override
  State<_UnifiedEnhancedProfileIcon> createState() => _UnifiedEnhancedProfileIconState();
}

class _UnifiedEnhancedProfileIconState extends State<_UnifiedEnhancedProfileIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _animationController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _animationController.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white, // Solid white background for better visibility
                border: Border.all(
                  color: _isPressed
                      ? Colors.white
                      : Colors.white.withAlpha(230),
                  width: 1.0, // Reduced border width for thinner boundary
                ),
                boxShadow: [
                  // Main shadow
                  BoxShadow(
                    color: Colors.black.withAlpha(40), // Stronger shadow for better definition
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                    spreadRadius: 0,
                  ),
                  // Glow effect when pressed
                  if (_isPressed)
                    BoxShadow(
                      color: Colors.white.withAlpha(150),
                      blurRadius: 12 * _glowAnimation.value,
                      offset: const Offset(0, 0),
                      spreadRadius: 2 * _glowAnimation.value,
                    ),
                  // Inner highlight
                  BoxShadow(
                    color: Colors.white.withAlpha(100),
                    blurRadius: 1,
                    offset: const Offset(-0.5, -0.5),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Container(
                margin: const EdgeInsets.all(1), // Reduced margin for thinner boundary
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: widget.userPhotoUrl != null
                      ? null
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primaryLight.withAlpha(200), // More vibrant colors
                            AppColors.primary.withAlpha(220),
                          ],
                        ),
                ),
                child: ClipOval(
                  child: widget.userPhotoUrl != null
                      ? Stack(
                          children: [
                            // User photo
                            Image.network(
                              widget.userPhotoUrl!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildDefaultAvatar();
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return _buildLoadingAvatar();
                              },
                            ),
                            // Subtle overlay for better contrast
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withAlpha(10),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : _buildDefaultAvatar(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
        Color(0xFFB5E853), // Brighter fresh green
        Color(0xFFFFD54F), // Brighter sunny yellow
        ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.person_rounded,
          size: 24,
          color: Colors.white,
          shadows: [
            Shadow(
              color: Colors.black.withAlpha(60), // Stronger shadow for better definition
              offset: const Offset(0, 1),
              blurRadius: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingAvatar() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFB5E853), // Brighter fresh green
            Color(0xFFFFD54F), // Brighter sunny yellow
          ],
        ),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
