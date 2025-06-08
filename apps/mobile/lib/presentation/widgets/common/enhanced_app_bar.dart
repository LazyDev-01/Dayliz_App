import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import 'animated_cloud_background.dart';
import 'back_button_widget.dart';

/// Enum for different cloud animation types
enum CloudAnimationType {
  subtle,
  prominent,
  dense,
  peaceful,
}

/// Enhanced app bar with rounded corners and premium styling
class EnhancedAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// The title of the app bar
  final String title;

  /// Whether to show a back button
  final bool showBackButton;

  /// Whether to show a drawer toggle
  final bool showDrawerToggle;

  /// The fallback route to navigate to if there's nothing in the navigation stack
  final String fallbackRoute;

  /// Custom callback to override default back navigation behavior
  final VoidCallback? onBackPressed;

  /// The tooltip text for the back button
  final String? backButtonTooltip;

  /// The actions to display at the end of the app bar
  final List<Widget>? actions;

  /// The bottom widget of the app bar (e.g., TabBar)
  final PreferredSizeWidget? bottom;

  /// Whether to center the title
  final bool centerTitle;

  /// The background color of the app bar
  final Color? backgroundColor;

  /// The foreground color of the app bar (affects text and icon colors)
  final Color? foregroundColor;

  /// The elevation of the app bar
  final double? elevation;

  /// Whether to show a shadow under the app bar
  final bool showShadow;

  /// Custom leading widget to replace the back button
  final Widget? leading;

  /// Whether to enable animated cloud background
  final bool enableCloudAnimation;

  /// The type of cloud animation to use
  final CloudAnimationType cloudType;

  /// Custom cloud color (defaults to white with opacity)
  final Color? cloudColor;

  /// Cloud opacity (0.0 to 1.0)
  final double cloudOpacity;

  /// Whether this is the home screen (affects styling)
  final bool isHomeScreen;

  /// Creates an enhanced app bar with rounded corners and premium styling
  const EnhancedAppBar({
    Key? key,
    required this.title,
    this.showBackButton = false,
    this.showDrawerToggle = false,
    this.fallbackRoute = '/home',
    this.onBackPressed,
    this.backButtonTooltip,
    this.actions,
    this.bottom,
    this.centerTitle = true,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.showShadow = true,
    this.leading,
    this.enableCloudAnimation = false,
    this.cloudType = CloudAnimationType.subtle,
    this.cloudColor,
    this.cloudOpacity = 0.2,
    this.isHomeScreen = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Set default colors based on whether it's home screen or not
    final effectiveBackgroundColor = backgroundColor ?? 
        (isHomeScreen ? AppColors.primary : Colors.white);
    final effectiveForegroundColor = foregroundColor ?? 
        (isHomeScreen ? Colors.white : Colors.black);
    final effectiveCloudColor = cloudColor ?? Colors.white;

    Widget appBarWidget;
    
    if (enableCloudAnimation) {
      appBarWidget = Stack(
        children: [
          // Base app bar
          _buildBaseAppBar(
            context,
            effectiveBackgroundColor,
            effectiveForegroundColor,
          ),
          
          // Animated cloud background overlay
          Positioned.fill(
            child: _buildCloudBackground(effectiveCloudColor),
          ),
        ],
      );
    } else {
      appBarWidget = _buildBaseAppBar(
        context,
        effectiveBackgroundColor,
        effectiveForegroundColor,
      );
    }

    // Wrap in container with rounded corners and shadow
    return Container(
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(8),
        ),
        boxShadow: showShadow ? [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 1,
          ),
        ] : null,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(8),
        ),
        child: appBarWidget,
      ),
    );
  }

  Widget _buildBaseAppBar(
    BuildContext context,
    Color backgroundColor,
    Color foregroundColor,
  ) {
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          color: foregroundColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: centerTitle,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: 0, // Remove default elevation as we handle it with container
      shadowColor: Colors.transparent,
      actions: actions,
      bottom: bottom,
      leading: _buildLeading(context, foregroundColor),
      iconTheme: IconThemeData(color: foregroundColor),
      actionsIconTheme: IconThemeData(color: foregroundColor),
    );
  }

  /// Builds the cloud background based on the selected type
  Widget _buildCloudBackground(Color cloudColor) {
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

  /// Builds the leading widget based on the configuration.
  Widget? _buildLeading(BuildContext context, Color foregroundColor) {
    if (leading != null) {
      return leading;
    }

    if (showBackButton) {
      return IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new,
          color: foregroundColor,
        ),
        onPressed: onBackPressed ?? () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            context.go(fallbackRoute);
          }
        },
        tooltip: backButtonTooltip ?? 'Back',
      );
    }

    if (showDrawerToggle) {
      return IconButton(
        icon: Icon(
          Icons.menu,
          color: foregroundColor,
        ),
        onPressed: () {
          Scaffold.of(context).openDrawer();
        },
        tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
      );
    }

    return null;
  }

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + (bottom?.preferredSize.height ?? 0)
  );
}

/// Factory methods for creating enhanced app bar configurations
class EnhancedAppBars {
  /// Creates a simple app bar with rounded corners
  static EnhancedAppBar simple({
    required String title,
    List<Widget>? actions,
    Color? backgroundColor,
    Color? foregroundColor,
    double? elevation,
    bool centerTitle = true,
    bool showShadow = true,
  }) {
    return EnhancedAppBar(
      title: title,
      showBackButton: false,
      actions: actions,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: elevation,
      centerTitle: centerTitle,
      showShadow: showShadow,
    );
  }

  /// Creates an app bar with a back button and rounded corners
  static EnhancedAppBar withBackButton({
    required String title,
    String fallbackRoute = '/home',
    VoidCallback? onBackPressed,
    String? backButtonTooltip,
    List<Widget>? actions,
    Color? backgroundColor,
    Color? foregroundColor,
    double? elevation,
    bool centerTitle = true,
    bool showShadow = true,
  }) {
    return EnhancedAppBar(
      title: title,
      showBackButton: true,
      fallbackRoute: fallbackRoute,
      onBackPressed: onBackPressed,
      backButtonTooltip: backButtonTooltip,
      actions: actions,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: elevation,
      centerTitle: centerTitle,
      showShadow: showShadow,
    );
  }

  /// Creates the home screen app bar with enhanced profile icon, search bar with border, and category icons
  static PreferredSizeWidget homeScreen({
    required VoidCallback onSearchTap,
    required VoidCallback onProfileTap,
    String? userPhotoUrl,
    String searchHint = 'Search for products...',
    Color? backgroundColor,
    Color? foregroundColor,
    double? elevation,
    List<Widget>? additionalActions,
    bool showShadow = true,
    bool enableCloudAnimation = false,
    CloudAnimationType cloudType = CloudAnimationType.peaceful,
    Color? cloudColor,
    double cloudOpacity = 0.15,
    Function(String)? onCategoryTap,
  }) {
    // Enhanced profile icon with sophisticated design
    final profileIcon = _EnhancedProfileIcon(
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
      // Add any additional actions
      if (additionalActions != null) ...additionalActions,
    ];

    final effectiveBackgroundColor = backgroundColor ?? AppColors.primary;
    final effectiveCloudColor = cloudColor ?? Colors.white;

    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 80), // Reduced size since no category icons
      child: Container(
        decoration: BoxDecoration(
          // Fresh Green to Sunny Yellow - 120deg linear gradient for better balance
          gradient: LinearGradient(
            begin: const Alignment(-0.8, -1.0), // 120 degrees equivalent
            end: const Alignment(0.8, 1.0),
            colors: [
              const Color(0xFFB5E853), // Slightly brighter fresh green
              const Color(0xFFFFD54F), // Slightly brighter sunny yellow
            ],
          ),
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(16), // Increased radius for modern look
          ),
          boxShadow: showShadow ? [
            // Fresh green shadow for depth
            BoxShadow(
              color: const Color(0xFFB5E853).withAlpha(20),
              blurRadius: 18,
              offset: const Offset(0, 6),
              spreadRadius: 0,
            ),
            // Sunny yellow glow effect
            BoxShadow(
              color: const Color(0xFFFFD54F).withAlpha(25),
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
          ] : null,
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
                                Icon(
                                  Icons.search_rounded, // More modern rounded search icon
                                  color: const Color(0xFF1F2937), // Dark gray for contrast
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
                      child: _buildCloudBackgroundStatic(effectiveCloudColor, cloudType, cloudOpacity),
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

  /// Helper method to build cloud background for static methods
  static Widget _buildCloudBackgroundStatic(Color cloudColor, CloudAnimationType cloudType, double opacity) {
    switch (cloudType) {
      case CloudAnimationType.subtle:
        return CloudBackgrounds.subtle(
          cloudColor: cloudColor,
          opacity: opacity,
        );
      case CloudAnimationType.prominent:
        return CloudBackgrounds.prominent(
          cloudColor: cloudColor,
          opacity: opacity,
        );
      case CloudAnimationType.dense:
        return CloudBackgrounds.dense(
          cloudColor: cloudColor,
          opacity: opacity,
        );
      case CloudAnimationType.peaceful:
        return CloudBackgrounds.peaceful(
          cloudColor: cloudColor,
          opacity: opacity,
        );
    }
  }
}

/// Enhanced profile icon widget with sophisticated design and animations
class _EnhancedProfileIcon extends StatefulWidget {
  final String? userPhotoUrl;
  final VoidCallback onTap;

  const _EnhancedProfileIcon({
    required this.userPhotoUrl,
    required this.onTap,
  });

  @override
  State<_EnhancedProfileIcon> createState() => _EnhancedProfileIconState();
}

class _EnhancedProfileIconState extends State<_EnhancedProfileIcon>
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
        const Color(0xFFB5E853).withAlpha(200), // Brighter fresh green
        const Color(0xFFFFD54F).withAlpha(220), // Brighter sunny yellow
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFB5E853).withAlpha(150), // Brighter fresh green
            const Color(0xFFFFD54F).withAlpha(180), // Brighter sunny yellow
          ],
        ),
      ),
      child: Center(
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