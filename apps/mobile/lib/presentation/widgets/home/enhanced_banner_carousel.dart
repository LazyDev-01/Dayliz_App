import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/entities/banner.dart' as banner_entity;
import '../../providers/banner_providers.dart';
import 'banner_carousel.dart';

/// Enhanced banner carousel that integrates with Riverpod state management
class EnhancedBannerCarousel extends ConsumerStatefulWidget {
  final double height;
  final Duration autoScrollDuration;
  final Duration animationDuration;
  final bool enableAutoScroll;

  const EnhancedBannerCarousel({
    Key? key,
    this.height = 200,
    this.autoScrollDuration = const Duration(seconds: 5),
    this.animationDuration = const Duration(milliseconds: 400),
    this.enableAutoScroll = true,
  }) : super(key: key);

  @override
  ConsumerState<EnhancedBannerCarousel> createState() => _EnhancedBannerCarouselState();
}

class _EnhancedBannerCarouselState extends ConsumerState<EnhancedBannerCarousel> {
  @override
  void initState() {
    super.initState();
    // Load banners when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bannerNotifierProvider.notifier).loadActiveBanners();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bannerState = ref.watch(bannerNotifierProvider);
    final isLoading = ref.watch(bannersLoadingProvider);
    final hasError = ref.watch(hasErrorProvider);
    final errorMessage = ref.watch(bannersErrorProvider);

    if (isLoading) {
      return _buildLoadingState();
    }

    if (hasError) {
      return _buildErrorState(errorMessage ?? 'An error occurred');
    }

    if (!bannerState.hasBanners) {
      return _buildEmptyState();
    }

    return BannerCarousel(
      banners: bannerState.activeBanners,
      height: widget.height,
      autoScrollDuration: widget.autoScrollDuration,
      animationDuration: widget.animationDuration,
      enableAutoScroll: widget.enableAutoScroll,
      onBannerTap: _handleBannerTap,
    );
  }

  void _handleBannerTap(banner_entity.Banner banner) {
    debugPrint('Banner tapped: ${banner.title}');
    
    // Handle different action types
    switch (banner.actionType) {
      case banner_entity.BannerActionType.category:
        if (banner.actionUrl != null) {
          context.push(banner.actionUrl!);
        }
        break;
      case banner_entity.BannerActionType.product:
        if (banner.actionUrl != null) {
          context.push(banner.actionUrl!);
        }
        break;
      case banner_entity.BannerActionType.collection:
        if (banner.actionUrl != null) {
          context.push(banner.actionUrl!);
        }
        break;
      case banner_entity.BannerActionType.url:
        if (banner.actionUrl != null) {
          // Handle external URLs or custom navigation
          context.push(banner.actionUrl!);
        }
        break;
      case banner_entity.BannerActionType.none:
        // No action for display-only banners
        break;
    }
  }

  Widget _buildLoadingState() {
    return Container(
      height: widget.height,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Container(
      height: widget.height,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red[400],
            ),
            const SizedBox(height: 12),
            Text(
              'Failed to load banners',
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                color: Colors.red[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(bannerNotifierProvider.notifier).refreshBanners();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[400],
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: widget.height,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 12),
            Text(
              'No banners available',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Check back later for new promotions',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
