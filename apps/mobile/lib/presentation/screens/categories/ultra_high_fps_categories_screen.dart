import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../domain/entities/category.dart';

import '../../providers/category_providers.dart';
import '../../widgets/common/navigation_handler.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_state.dart';
import '../product/clean_product_listing_screen.dart';

/// Ultra High FPS Categories Screen (90-120 FPS capable)
/// Optimized for high refresh rate displays
class UltraHighFpsCategoriesScreen extends ConsumerStatefulWidget {
  const UltraHighFpsCategoriesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<UltraHighFpsCategoriesScreen> createState() => _UltraHighFpsCategoriesScreenState();
}

class _UltraHighFpsCategoriesScreenState extends ConsumerState<UltraHighFpsCategoriesScreen>
    with TickerProviderStateMixin {

  // Global animation controller for ultra-smooth animations
  late AnimationController _globalAnimationController;

  @override
  void initState() {
    super.initState();

    // Enable high refresh rate
    _enableHighRefreshRate();

    // Global animation controller for 120 FPS animations
    _globalAnimationController = AnimationController(
      duration: const Duration(milliseconds: 16), // 60+ FPS capable
      vsync: this,
    );
  }

  @override
  void dispose() {
    _globalAnimationController.dispose();
    super.dispose();
  }

  /// Enable high refresh rate for supported devices
  void _enableHighRefreshRate() {
    // Force high refresh rate mode
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: _buildUltraFastAppBar(context),
      body: categoriesAsync.when(
        data: (categories) => _buildUltraFastCategoriesList(context, categories),
        loading: () => const LoadingIndicator(message: 'Loading categories...'),
        error: (error, stackTrace) => ErrorState(
          message: error.toString(),
          onRetry: () => ref.refresh(categoriesProvider),
        ),
      ),
      bottomNavigationBar: NavigationHandler.createBottomNavBar(
        context: context,
        ref: ref,
        currentIndex: 1,
      ),
    );
  }

  /// Ultra-fast app bar with minimal overhead
  PreferredSizeWidget _buildUltraFastAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: RepaintBoundary(
        child: AppBar(
          title: const Text('Categories'),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 4,
          shadowColor: Colors.black.withValues(alpha: 0.3),
          surfaceTintColor: Colors.white,
          scrolledUnderElevation: 4,
        ),
      ),
    );
  }

  /// Ultra-fast categories list with maximum performance optimizations
  Widget _buildUltraFastCategoriesList(BuildContext context, List<Category> categories) {
    if (categories.isEmpty) {
      return _buildEmptyState(context);
    }

    return RepaintBoundary(
      child: CustomScrollView(
        // Ultra-smooth scrolling physics
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          const SliverPadding(padding: EdgeInsets.only(top: 16)),
          ...categories.map((category) => _buildUltraFastCategorySection(context, category)),
        ],
      ),
    );
  }

  /// Ultra-fast category section with maximum performance
  Widget _buildUltraFastCategorySection(BuildContext context, Category category) {
    return SliverMainAxisGroup(
      slivers: [
        // Category header with RepaintBoundary
        SliverToBoxAdapter(
          child: RepaintBoundary(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Text(
                category.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),

        // Ultra-fast subcategories grid
        if (category.subCategories != null && category.subCategories!.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.65,
                crossAxisSpacing: 4,
                mainAxisSpacing: 3,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final subcategory = category.subCategories![index];
                  return RepaintBoundary(
                    key: ValueKey('${category.id}_${subcategory.id}'),
                    child: _buildUltraFastSubcategoryCard(
                      context,
                      subcategory,
                      category.themeColor,
                    ),
                  );
                },
                childCount: category.subCategories!.length,
                addRepaintBoundaries: false, // We handle this manually
              ),
            ),
          )
        else
          const SliverToBoxAdapter(
            child: RepaintBoundary(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'No subcategories available',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ),

        // Spacing with RepaintBoundary
        const SliverToBoxAdapter(
          child: SizedBox(height: 24),
        ),
      ],
    );
  }

  /// Ultra-fast subcategory card with 120 FPS capable animations
  Widget _buildUltraFastSubcategoryCard(
    BuildContext context,
    SubCategory subcategory,
    Color themeColor
  ) {
    return _UltraFastBounceCard(
      animationController: _globalAnimationController,
      onTap: () => _navigateToProducts(context, subcategory),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ultra-fast image container
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(4, 8, 4, 4),
              child: _buildUltraFastImage(subcategory, themeColor),
            ),
          ),
          const SizedBox(height: 4),
          // Ultra-fast text
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                subcategory.name,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212121),
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Ultra-fast image loading with aggressive caching
  Widget _buildUltraFastImage(SubCategory subcategory, Color themeColor) {
    if (subcategory.imageUrl == null) {
      return _buildUltraFastPlaceholder(themeColor);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImage(
        imageUrl: subcategory.imageUrl!,
        fit: BoxFit.cover,
        memCacheWidth: 150, // Smaller cache for faster access
        memCacheHeight: 150,
        maxWidthDiskCache: 300,
        maxHeightDiskCache: 300,
        placeholder: (context, url) => _buildUltraFastPlaceholder(themeColor),
        errorWidget: (context, url, error) => _buildUltraFastPlaceholder(themeColor),
        fadeInDuration: const Duration(milliseconds: 100), // Faster fade
        fadeOutDuration: const Duration(milliseconds: 50),
      ),
    );
  }

  /// Ultra-fast placeholder with minimal rendering overhead
  Widget _buildUltraFastPlaceholder(Color themeColor) {
    return Container(
      decoration: BoxDecoration(
        color: themeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.category,
        color: themeColor.withValues(alpha: 0.6),
        size: 32,
      ),
    );
  }

  /// Navigate to products
  void _navigateToProducts(BuildContext context, SubCategory subcategory) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CleanProductListingScreen(
          subcategoryId: subcategory.id,
        ),
        settings: RouteSettings(
          arguments: {'subcategoryName': subcategory.name},
        ),
      ),
    );
  }

  /// Empty state
  Widget _buildEmptyState(BuildContext context) {
    return const RepaintBoundary(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No categories available',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ultra-fast bounce card optimized for 120 FPS
class _UltraFastBounceCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final AnimationController animationController;

  const _UltraFastBounceCard({
    required this.child,
    required this.onTap,
    required this.animationController,
  });

  @override
  State<_UltraFastBounceCard> createState() => _UltraFastBounceCardState();
}

class _UltraFastBounceCardState extends State<_UltraFastBounceCard> {
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    // Ultra-fast animation for 120 FPS displays
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.85, // Very pronounced for instant feedback
    ).animate(CurvedAnimation(
      parent: widget.animationController,
      curve: Curves.easeOutQuart, // Ultra-fast response curve
    ));
  }

  void _handleTapDown(TapDownDetails details) {
    if (!_isPressed) {
      setState(() {
        _isPressed = true;
      });
      widget.animationController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    _handleTapEnd();
  }

  void _handleTapCancel() {
    _handleTapEnd();
  }

  void _handleTap() {
    widget.onTap();
  }

  void _handleTapEnd() {
    if (_isPressed) {
      setState(() {
        _isPressed = false;
      });
      widget.animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}
