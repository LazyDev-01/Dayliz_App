import 'package:flutter/material.dart';
import '../../widgets/home/banner_carousel.dart';
import '../../../domain/entities/banner.dart' as banner_entity;

/// Demo screen to showcase the enhanced banner carousel features
class BannerCarouselDemo extends StatelessWidget {
  const BannerCarouselDemo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enhanced Banner Carousel'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Modern Professional Banner Carousel',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enhanced with modern design, smooth animations, and professional styling.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            
            // Enhanced Banner Carousel
            BannerCarousel(
              banners: _getDemoBanners(),
              height: 220,
              onBannerTap: (banner) {
                _showBannerDialog(context, banner);
              },
            ),
            
            const SizedBox(height: 32),
            
            // Features List
            const Text(
              'Enhanced Features:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildFeatureItem(
              icon: Icons.design_services,
              title: 'Modern Design',
              description: 'Elevated cards with subtle shadows and rounded corners',
            ),
            _buildFeatureItem(
              icon: Icons.animation,
              title: 'Smooth Animations',
              description: 'Enhanced transitions with custom curves and haptic feedback',
            ),
            _buildFeatureItem(
              icon: Icons.touch_app,
              title: 'Better Interactions',
              description: 'Intelligent auto-scroll with pause on user interaction',
            ),
            _buildFeatureItem(
              icon: Icons.palette,
              title: 'Enhanced Gradients',
              description: 'Sophisticated gradient overlays with better opacity control',
            ),
            _buildFeatureItem(
              icon: Icons.accessibility,
              title: 'Accessibility',
              description: 'Improved accessibility with semantic labels and haptic feedback',
            ),
            _buildFeatureItem(
              icon: Icons.speed,
              title: 'Performance',
              description: 'Optimized rendering and memory management',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.blue,
              size: 24,
            ),
          ),
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
                  description,
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

  void _showBannerDialog(BuildContext context, banner_entity.Banner banner) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(banner.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(banner.subtitle),
            const SizedBox(height: 16),
            Text('Action: ${banner.actionType.toString().split('.').last}'),
            if (banner.actionUrl != null)
              Text('URL: ${banner.actionUrl}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  List<banner_entity.Banner> _getDemoBanners() {
    return [
      const banner_entity.Banner(
        id: '1',
        title: 'Fresh Groceries Delivered',
        subtitle: 'Get 20% off on your first order with free delivery',
        imageUrl: 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=800&h=400&fit=crop',
        actionUrl: '/categories/groceries',
        actionType: banner_entity.BannerActionType.category,
      ),
      const banner_entity.Banner(
        id: '2',
        title: 'Daily Essentials',
        subtitle: 'Free delivery on orders above ₹500',
        imageUrl: 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=800&h=400&fit=crop',
        actionUrl: '/categories/essentials',
        actionType: banner_entity.BannerActionType.category,
      ),
      const banner_entity.Banner(
        id: '3',
        title: 'Fresh Fruits & Vegetables',
        subtitle: 'Farm fresh produce at your doorstep',
        imageUrl: 'https://images.unsplash.com/photo-1610832958506-aa56368176cf?w=800&h=400&fit=crop',
        actionUrl: '/categories/fruits-vegetables',
        actionType: banner_entity.BannerActionType.category,
      ),
      const banner_entity.Banner(
        id: '4',
        title: 'Premium Quality Products',
        subtitle: 'Handpicked items for your family',
        imageUrl: 'https://images.unsplash.com/photo-1534723452862-4c874018d66d?w=800&h=400&fit=crop',
        actionUrl: '/collections/premium',
        actionType: banner_entity.BannerActionType.collection,
      ),
      const banner_entity.Banner(
        id: '5',
        title: 'Special Weekend Offers',
        subtitle: 'Up to 50% off on selected items',
        imageUrl: 'https://images.unsplash.com/photo-1607082348824-0a96f2a4b9da?w=800&h=400&fit=crop',
        actionUrl: '/offers/weekend',
        actionType: banner_entity.BannerActionType.url,
      ),
    ];
  }
}
