import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Import our reusable haptic system
import '../../../core/services/haptic_service.dart';
import '../../../core/utils/address_formatter.dart';
import '../../providers/user_profile_providers.dart';
import 'svg_icon_button.dart';
import '../../../core/constants/app_colors.dart';

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
    // Add haptic feedback for smooth user experience using our reusable system
    HapticService.light();

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      // If can't pop, go to fallback route
      context.go(fallbackRoute);
    }
  }

  /// Handles direct home navigation
  void _handleDirectHomeNavigation(BuildContext context) {
    // Add haptic feedback for smooth user experience using our reusable system
    HapticService.light();
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

  /// Creates the home screen app bar with collapsible behavior and sticky search functionality
  ///
  /// Features:
  /// - Collapsible app bar that hides delivery address and profile on scroll down
  /// - Sticky search bar that remains visible when collapsed
  /// - Top-to-bottom gradient background (green to yellow)
  /// - Smooth animations for expand/collapse transitions
  /// - No rounded corners for modern flat design


  /// Legacy method for backward compatibility - returns single widget
  static Widget homeScreenCollapsible({
    required VoidCallback onSearchTap,
    required VoidCallback onProfileTap,
    String? userPhotoUrl,
    String searchHint = 'Search for products...',
  }) {
    // For now, return the old implementation to avoid breaking changes
    return _CollapsibleHomeAppBar(
      onSearchTap: onSearchTap,
      onProfileTap: onProfileTap,
      userPhotoUrl: userPhotoUrl,
      searchHint: searchHint,
    );
  }

  /// Creates the legacy home screen app bar (for backward compatibility)
  static PreferredSizeWidget homeScreen({
    required VoidCallback onSearchTap,
    required VoidCallback onProfileTap,
    String? userPhotoUrl,
    String searchHint = 'Search for products...',
  }) {
    return _OptimizedHomeAppBar(
      onSearchTap: onSearchTap,
      onProfileTap: onProfileTap,
      userPhotoUrl: userPhotoUrl,
      searchHint: searchHint,
    );
  }
}

/// Collapsible Home App Bar with sticky search functionality
///
/// Features:
/// - Collapsible behavior: hides delivery address and profile on scroll down
/// - Sticky search bar that remains visible when collapsed
/// - Smooth animations for expand/collapse transitions
/// - Top-to-bottom gradient background
class _CollapsibleHomeAppBar extends ConsumerWidget {
  final VoidCallback onSearchTap;
  final VoidCallback onProfileTap;
  final String? userPhotoUrl;
  final String searchHint;

  const _CollapsibleHomeAppBar({
    required this.onSearchTap,
    required this.onProfileTap,
    this.userPhotoUrl,
    required this.searchHint,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverAppBar(
      expandedHeight: 60, // Further reduced for complete collapse
      floating: false, // Don't show on scroll up
      pinned: false, // Don't pin the delivery section - let it scroll away completely
      snap: false, // No snap behavior
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      backgroundColor: Colors.transparent,
      // No toolbarHeight - this allows it to collapse completely
      toolbarHeight: 0, // This makes it disappear completely when collapsed
      flexibleSpace: FlexibleSpaceBar(
        background: _buildDeliveryAddressSection(context, ref),
        collapseMode: CollapseMode.parallax,
      ),
    );
  }

  /// Builds the delivery address section (collapsible part)
  Widget _buildDeliveryAddressSection(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        // Top-to-bottom gradient (green to yellow)
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFB5E853), // Fresh green at top
            Color(0xFFFFD54F), // Sunny yellow at bottom
          ],
        ),
        // No rounded corners for modern flat design
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000), // Subtle shadow
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false, // Don't add bottom padding
        child: Container(
          height: 48, // Reduced height for more compact design
          padding: const EdgeInsets.symmetric(horizontal: 16),
          margin: const EdgeInsets.only(top: 2), // Even smaller margin
          child: Row(
            children: [
              // Delivery address - wrapped in Expanded to prevent overflow
              Expanded(
                child: _buildDeliveryAddress(context, ref),
              ),
              const SizedBox(width: 12), // Fixed spacing
              // Profile icon
              _buildProfileIcon(),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the delivery address widget
  Widget _buildDeliveryAddress(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        HapticService.light();
        _navigateToAddressScreen(context);
      },
      child: Consumer(
        builder: (context, ref, child) {
          // Watch user profile state for reactive updates
          final userProfileState = ref.watch(userProfileNotifierProvider);
          final addresses = userProfileState.addresses ?? [];

          String address = 'Set your location';
          bool isLocationSet = false;

          if (addresses.isNotEmpty) {
            // Find default address or use first address
            final defaultAddress = addresses.firstWhere(
              (address) => address.isDefault,
              orElse: () => addresses.first,
            );

            // Format address for display (compact format)
            address = AddressFormatter.formatAddressCompact(defaultAddress);
            isLocationSet = true;
          }

          if (userProfileState.isAddressesLoading) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha(20),
                  ),
                  child: Icon(
                    Icons.location_on,
                    size: 18,
                    color: Colors.white.withAlpha(220),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Deliver to',
                            style: TextStyle(
                              color: Colors.white.withAlpha(180),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.keyboard_arrow_down,
                            size: 16,
                            color: Colors.white.withAlpha(200),
                          ),
                        ],
                      ),
                      const Text(
                        'Loading...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          // Main address display - optimized for space
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(20),
                ),
                child: Icon(
                  Icons.location_on,
                  size: 18,
                  color: Colors.white.withAlpha(220),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Deliver to',
                          style: TextStyle(
                            color: Colors.white.withAlpha(180),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.keyboard_arrow_down,
                          size: 16,
                          color: Colors.white.withAlpha(200),
                        ),
                      ],
                    ),
                    Text(
                      isLocationSet ? address : 'Select location',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Builds the profile icon widget
  Widget _buildProfileIcon() {
    return GestureDetector(
      onTap: onProfileTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withAlpha(30),
          border: Border.all(
            color: Colors.white.withAlpha(60),
            width: 1,
          ),
        ),
        child: userPhotoUrl != null && userPhotoUrl!.isNotEmpty
            ? ClipOval(
                child: Image.network(
                  userPhotoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.person,
                      color: Color(0xFF1F2937),
                      size: 20,
                    );
                  },
                ),
              )
            : const Icon(
                Icons.person,
                color: Color(0xFF1F2937),
                size: 20,
              ),
      ),
    );
  }

  /// Navigate to address screen for location management
  void _navigateToAddressScreen(BuildContext context) {
    debugPrint('🔄 [LocationIndicator] Navigating to address screen from app bar');
    context.push('/addresses');
  }
}

/// Optimized Home App Bar with delivery address and sticky search functionality
/// - Dayliz branding instead of location display
/// - Top-to-bottom gradient (green to yellow)
/// - No rounded corners for modern flat design
/// - Sticky search bar on scroll
/// - Enhanced profile icon
class _OptimizedHomeAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final VoidCallback onSearchTap;
  final VoidCallback onProfileTap;
  final String? userPhotoUrl;
  final String searchHint;

  const _OptimizedHomeAppBar({
    required this.onSearchTap,
    required this.onProfileTap,
    this.userPhotoUrl,
    required this.searchHint,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 70),
      child: Container(
        decoration: const BoxDecoration(
          // Top-to-bottom gradient (green to yellow)
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFB5E853), // Fresh green at top
              Color(0xFFFFD54F), // Sunny yellow at bottom
            ],
          ),
          // No rounded corners for modern flat design
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000), // Subtle shadow
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Main app bar with Dayliz branding
              Container(
                height: kToolbarHeight,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // Delivery address - wrapped in Expanded to prevent overflow
                    Expanded(
                      child: _buildDeliveryAddress(context, ref),
                    ),
                    const SizedBox(width: 12), // Fixed spacing instead of Spacer
                    // Profile icon
                    _buildProfileIcon(),
                  ],
                ),
              ),
              // Search bar
              _buildSearchBar(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 70);

  /// Builds the delivery address widget
  Widget _buildDeliveryAddress(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        HapticService.light();
        _navigateToAddressScreen(context);
      },
      child: Consumer(
        builder: (context, ref, child) {
          // Watch user profile state for reactive updates
          final userProfileState = ref.watch(userProfileNotifierProvider);
          final addresses = userProfileState.addresses ?? [];

          String address = 'Set your location';
          bool isLocationSet = false;

          if (addresses.isNotEmpty) {
            // Find default address or use first address
            final defaultAddress = addresses.firstWhere(
              (address) => address.isDefault,
              orElse: () => addresses.first,
            );

            // Format address for display (compact format)
            address = AddressFormatter.formatAddressCompact(defaultAddress);
            isLocationSet = true;
          }

          if (userProfileState.isAddressesLoading) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha(20),
                  ),
                  child: Icon(
                    Icons.location_on,
                    size: 18,
                    color: Colors.white.withAlpha(220),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded( // Added Expanded to prevent overflow
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Deliver to',
                            style: TextStyle(
                              color: Colors.white.withAlpha(180),
                              fontSize: 14, // Reduced from 16
                              fontWeight: FontWeight.w600, // Reduced from w700
                            ),
                          ),
                          const SizedBox(width: 6), // Reduced from 8
                          Icon(
                            Icons.keyboard_arrow_down,
                            size: 16, // Reduced from 18
                            color: Colors.white.withAlpha(200),
                          ),
                        ],
                      ),
                      const Text(
                        'Loading...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13, // Reduced from 14
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          // Main address display - optimized for space
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(20),
                ),
                child: Icon(
                  Icons.location_on,
                  size: 18,
                  color: Colors.white.withAlpha(220),
                ),
              ),
              const SizedBox(width: 8),
              Expanded( // Changed from Flexible to Expanded for better space usage
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Deliver to',
                          style: TextStyle(
                            color: Colors.white.withAlpha(180),
                            fontSize: 14, // Reduced from 16 to save space
                            fontWeight: FontWeight.w600, // Reduced from w700
                          ),
                        ),
                        const SizedBox(width: 6), // Reduced from 8
                        Icon(
                          Icons.keyboard_arrow_down,
                          size: 16, // Reduced from 18
                          color: Colors.white.withAlpha(200),
                        ),
                      ],
                    ),
                    Text(
                      isLocationSet ? address : 'Select location',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13, // Reduced from 14 to save space
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Navigate to address screen for location management
  void _navigateToAddressScreen(BuildContext context) {
    debugPrint('🔄 [LocationIndicator] Navigating to address screen from app bar');
    context.push('/addresses');
  }

  /// Builds the profile icon widget
  Widget _buildProfileIcon() {
    return GestureDetector(
      onTap: onProfileTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withAlpha(30),
          border: Border.all(
            color: Colors.white.withAlpha(60),
            width: 1,
          ),
        ),
        child: userPhotoUrl != null && userPhotoUrl!.isNotEmpty
            ? ClipOval(
                child: Image.network(
                  userPhotoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.person,
                      color: Color(0xFF1F2937),
                      size: 20,
                    );
                  },
                ),
              )
            : const Icon(
                Icons.person,
                color: Color(0xFF1F2937),
                size: 20,
              ),
      ),
    );
  }

  /// Builds the search bar widget with sticky functionality
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Hero(
        tag: 'search_bar', // Hero animation for sticky behavior
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: onSearchTap,
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(242),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withAlpha(150),
                  width: 1.0,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF1F2937),
                    size: 22,
                  ),
                  const SizedBox(width: 14),
                  Text(
                    searchHint,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


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
    HapticService.light();
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
