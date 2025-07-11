import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/banner_providers.dart';
import '../../widgets/home/enhanced_banner_carousel.dart';

/// Test screen to verify banner backend integration
class BannerIntegrationTest extends ConsumerStatefulWidget {
  const BannerIntegrationTest({Key? key}) : super(key: key);

  @override
  ConsumerState<BannerIntegrationTest> createState() => _BannerIntegrationTestState();
}

class _BannerIntegrationTestState extends ConsumerState<BannerIntegrationTest> {
  @override
  void initState() {
    super.initState();
    // Load banners when screen initializes
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Banner Integration Test'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(bannerNotifierProvider.notifier).refreshBanners();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            _buildStatusCard(bannerState, isLoading, hasError, errorMessage),
            
            const SizedBox(height: 24),
            
            // Banner Carousel
            const Text(
              'Live Banner Carousel',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const EnhancedBannerCarousel(height: 200),
            
            const SizedBox(height: 32),
            
            // Banner Details
            if (bannerState.hasBanners) ...[
              const Text(
                'Banner Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...bannerState.banners.map((banner) => _buildBannerCard(banner)),
            ],
            
            const SizedBox(height: 32),
            
            // Test Actions
            _buildTestActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(bannerState, bool isLoading, bool hasError, String? errorMessage) {
    Color cardColor;
    IconData icon;
    String title;
    String subtitle;

    if (isLoading) {
      cardColor = Colors.blue[50]!;
      icon = Icons.hourglass_empty;
      title = 'Loading...';
      subtitle = 'Fetching banners from database';
    } else if (hasError) {
      cardColor = Colors.red[50]!;
      icon = Icons.error_outline;
      title = 'Error';
      subtitle = errorMessage ?? 'Unknown error occurred';
    } else if (bannerState.hasBanners) {
      cardColor = Colors.green[50]!;
      icon = Icons.check_circle_outline;
      title = 'Success';
      subtitle = 'Loaded ${bannerState.banners.length} banner(s) from database';
    } else {
      cardColor = Colors.orange[50]!;
      icon = Icons.info_outline;
      title = 'No Banners';
      subtitle = 'No active banners found in database';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 32, color: Colors.grey[700]),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerCard(banner) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  banner.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: banner.isCurrentlyActive ? Colors.green[100] : Colors.red[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  banner.status,
                  style: TextStyle(
                    fontSize: 12,
                    color: banner.isCurrentlyActive ? Colors.green[700] : Colors.red[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            banner.subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Action: ${banner.actionType.displayName}',
                style: const TextStyle(fontSize: 12),
              ),
              if (banner.actionUrl != null) ...[
                const SizedBox(width: 16),
                Text(
                  'URL: ${banner.actionUrl}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[600],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTestActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Test Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              ref.read(bannerNotifierProvider.notifier).refreshBanners();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh Banners'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              ref.read(bannerNotifierProvider.notifier).reset();
            },
            icon: const Icon(Icons.clear),
            label: const Text('Reset State'),
          ),
        ),
      ],
    );
  }
}
