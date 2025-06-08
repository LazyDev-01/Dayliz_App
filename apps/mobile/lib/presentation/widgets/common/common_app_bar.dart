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

/// A common app bar widget that can be used throughout the app for consistent UI.
///
/// This widget provides a standardized app bar with various customization options
/// while maintaining a consistent look and feel across the app.
class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
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

  /// Creates a common app bar with consistent styling.
  ///
  /// If [showBackButton] is true, a [BackButtonWidget] will be used as the leading widget
  /// unless a custom [leading] widget is provided.
  const CommonAppBar({
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
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor = backgroundColor ?? AppColors.primary;
    final effectiveCloudColor = cloudColor ?? Colors.white;

    if (enableCloudAnimation) {
      return Stack(
        children: [
          // Base app bar
          AppBar(
            title: Text(title),
            centerTitle: centerTitle,
            backgroundColor: effectiveBackgroundColor,
            foregroundColor: foregroundColor,
            elevation: showShadow ? (elevation ?? 4) : 0,
            shadowColor: showShadow ? Colors.black.withAlpha(76) : Colors.transparent,
            actions: actions,
            bottom: bottom,
            leading: _buildLeading(context),
          ),
          
          // Animated cloud background overlay
          Positioned.fill(
            child: _buildCloudBackground(effectiveCloudColor),
          ),
        ],
      );
    } else {
      return AppBar(
        title: Text(title),
        centerTitle: centerTitle,
        backgroundColor: effectiveBackgroundColor,
        foregroundColor: foregroundColor,
        elevation: showShadow ? (elevation ?? 4) : 0,
        shadowColor: showShadow ? Colors.black.withAlpha(76) : Colors.transparent,
        actions: actions,
        bottom: bottom,
        leading: _buildLeading(context),
      );
    }
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
  Widget? _buildLeading(BuildContext context) {
    if (leading != null) {
      return leading;
    }

    if (showBackButton) {
      return BackButtonWidget(
        tooltip: backButtonTooltip,
        fallbackRoute: fallbackRoute,
        onPressed: onBackPressed,
      );
    }

    if (showDrawerToggle) {
      return IconButton(
        icon: const Icon(Icons.menu),
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

/// Factory methods for creating common app bar configurations
class CommonAppBars {
  /// Creates a simple app bar with a title and no back button
  static CommonAppBar simple({
    required String title,
    List<Widget>? actions,
    Color? backgroundColor,
    Color? foregroundColor,
    double? elevation,
    bool centerTitle = true,
    bool showShadow = true,
  }) {
    return CommonAppBar(
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

  /// Creates an app bar with a back button
  static CommonAppBar withBackButton({
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
    return CommonAppBar(
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

  /// Creates an app bar with a search action
  static CommonAppBar withSearch({
    required String title,
    required VoidCallback onSearchPressed,
    bool showBackButton = false,
    String fallbackRoute = '/home',
    VoidCallback? onBackPressed,
    List<Widget>? additionalActions,
    Color? backgroundColor,
    Color? foregroundColor,
    double? elevation,
    bool centerTitle = true,
    bool showShadow = true,
  }) {
    final actions = <Widget>[
      IconButton(
        icon: const Icon(Icons.search),
        onPressed: onSearchPressed,
      ),
      if (additionalActions != null) ...additionalActions,
    ];

    return CommonAppBar(
      title: title,
      showBackButton: showBackButton,
      fallbackRoute: fallbackRoute,
      onBackPressed: onBackPressed,
      actions: actions,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: elevation,
      centerTitle: centerTitle,
      showShadow: showShadow,
    );
  }

  /// Creates an app bar with cart and search actions
  static CommonAppBar withCartAndSearch({
    required String title,
    required VoidCallback onSearchPressed,
    required VoidCallback onCartPressed,
    required int cartItemCount,
    bool showBackButton = false,
    String fallbackRoute = '/home',
    VoidCallback? onBackPressed,
    List<Widget>? additionalActions,
    Color? backgroundColor,
    Color? foregroundColor,
    double? elevation,
    bool centerTitle = true,
    bool showShadow = true,
  }) {
    final actions = <Widget>[
      IconButton(
        icon: const Icon(Icons.search),
        onPressed: onSearchPressed,
        tooltip: 'Search',
      ),
      IconButton(
        icon: Badge(
          isLabelVisible: cartItemCount > 0,
          label: Text(
            cartItemCount.toString(),
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
          child: const Icon(Icons.shopping_cart_outlined),
        ),
        onPressed: onCartPressed,
        tooltip: 'Cart',
      ),
      if (additionalActions != null) ...additionalActions,
    ];

    return CommonAppBar(
      title: title,
      showBackButton: showBackButton,
      fallbackRoute: fallbackRoute,
      onBackPressed: onBackPressed,
      actions: actions,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: elevation,
      centerTitle: centerTitle,
      showShadow: showShadow,
    );
  }

  /// Creates an app bar with an integrated search bar
  static PreferredSizeWidget withSearchBar({
    required String title,
    required VoidCallback onSearchTap,
    required String searchHint,
    bool showBackButton = false,
    String fallbackRoute = '/home',
    VoidCallback? onBackPressed,
    List<Widget>? actions,
    Color? backgroundColor,
    Color? foregroundColor,
    double? elevation,
    bool centerTitle = true,
    bool showShadow = true,
  }) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 56), // Extra height for search bar
      child: AppBar(
        title: Text(title),
        centerTitle: centerTitle,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        elevation: showShadow ? (elevation ?? 4) : 0,
        shadowColor: showShadow ? Colors.black.withAlpha(76) : Colors.transparent, // Using withAlpha instead of withOpacity
        actions: actions,
        leading: showBackButton
          ? BackButtonWidget(
              tooltip: 'Back',
              fallbackRoute: fallbackRoute,
              onPressed: onBackPressed,
            )
          : null,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: GestureDetector(
              onTap: onSearchTap,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey[300]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(13), // Using withAlpha instead of withOpacity
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    Icon(Icons.search, color: Colors.grey[600]),
                    const SizedBox(width: 12),
                    Text(
                      searchHint,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Creates an app bar with a drawer toggle
  static CommonAppBar withDrawer({
    required String title,
    List<Widget>? actions,
    Color? backgroundColor,
    Color? foregroundColor,
    double? elevation,
    bool centerTitle = true,
    bool showShadow = true,
  }) {
    return CommonAppBar(
      title: title,
      showBackButton: false,
      showDrawerToggle: true,
      actions: actions,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: elevation,
      centerTitle: centerTitle,
      showShadow: showShadow,
    );
  }

  /// Creates a dedicated app bar for the home screen with integrated search bar
  ///
  /// This provides a specialized version of the app bar specifically for the home screen
  /// while still leveraging the common components framework.
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
    bool enableCloudAnimation = true,
    CloudAnimationType cloudType = CloudAnimationType.peaceful,
    Color? cloudColor,
    double cloudOpacity = 0.15,
  }) {
    // Enhanced profile icon with sophisticated design
    final profileIcon = _EnhancedProfileIcon(
      userPhotoUrl: userPhotoUrl,
      onTap: onProfileTap,
    );

    // Create the actions list with the enhanced profile icon
    final actions = <Widget>[
      // Enhanced profile icon button
      Padding(
        padding: const EdgeInsets.only(right: 16.0),
        child: profileIcon,
      ),
      // Add any additional actions
      if (additionalActions != null) ...additionalActions,
    ];

    final effectiveBackgroundColor = backgroundColor ?? AppColors.primary;
    final effectiveCloudColor = cloudColor ?? Colors.white;

    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 72), // Increased height from 56 to 72
      child: Builder(
        builder: (context) {
          final appBar = AppBar(
            title: const Text(
              'Dayliz',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 26, // Increased font size from 24 to 26
                color: Colors.white, // Explicitly set title color to white
              ),
            ),
            centerTitle: false, // Keep title aligned to the left
            backgroundColor: effectiveBackgroundColor,
            foregroundColor: Colors.white, // Ensure all foreground elements are white
            elevation: showShadow ? (elevation ?? 4) : 0,
            shadowColor: showShadow ? Colors.black.withAlpha(76) : Colors.transparent,
            actions: actions,
            toolbarHeight: kToolbarHeight + 8, // Slightly increase toolbar height
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(64), // Increased from 56 to 64
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12), // Increased bottom padding from 8 to 12
                child: GestureDetector(
                  onTap: onSearchTap,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey[300]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(13),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        Icon(Icons.search, color: Colors.grey[600]),
                        const SizedBox(width: 12),
                        Text(
                          searchHint,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withAlpha(200),
                    Colors.white.withAlpha(180),
                  ],
                ),
                border: Border.all(
                  color: _isPressed 
                      ? AppColors.primaryLight.withAlpha(180)
                      : Colors.white.withAlpha(120),
                  width: 1.5,
                ),
                boxShadow: [
                  // Main shadow
                  BoxShadow(
                    color: Colors.black.withAlpha(38),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                    spreadRadius: 0.5,
                  ),
                  // Glow effect when pressed
                  if (_isPressed)
                    BoxShadow(
                      color: AppColors.primaryLight.withAlpha(102),
                      blurRadius: 10 * _glowAnimation.value,
                      offset: const Offset(0, 0),
                      spreadRadius: 1.5 * _glowAnimation.value,
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
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: widget.userPhotoUrl != null
                      ? null
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primaryLight.withAlpha(51),
                            AppColors.primary.withAlpha(76),
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
                                    Colors.black.withAlpha(13),
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
            AppColors.primaryLight.withAlpha(102),
            AppColors.primary.withAlpha(128),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.person_rounded,
          size: 28,
          color: Colors.white,
          shadows: [
            Shadow(
              color: Colors.black.withAlpha(76),
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
            AppColors.shimmerBase,
            AppColors.shimmerHighlight,
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
              AppColors.primary.withAlpha(128),
            ),
          ),
        ),
      ),
    );
  }
}
