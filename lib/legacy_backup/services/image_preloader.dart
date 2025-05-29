import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dayliz_app/services/image_service.dart';

/// Service to preload key images in the app for smooth transitions
class ImagePreloader {
  static final ImagePreloader _instance = ImagePreloader._internal();
  
  factory ImagePreloader() => _instance;
  
  ImagePreloader._internal();
  
  /// Flag to track if preloading has been done
  bool _hasPreloaded = false;
  
  /// Preload featured images and category images
  /// Call this at app startup or during splash screen
  Future<void> preloadKeyImages(BuildContext context) async {
    // Don't preload more than once
    if (_hasPreloaded) return;
    
    try {
      // Preload default category images - these appear on home screen
      final categoryThumbnails = [
        'https://placehold.co/100/4CAF50/FFFFFF?text=Fruits',
        'https://placehold.co/100/8BC34A/FFFFFF?text=Veggies',
        'https://placehold.co/100/03A9F4/FFFFFF?text=Dairy',
        'https://placehold.co/100/FFC107/FFFFFF?text=Bakery',
        'https://placehold.co/100/FF9800/FFFFFF?text=Snacks',
        'https://placehold.co/100/9C27B0/FFFFFF?text=Drinks',
      ];
      
      // Preload category images
      for (final imageUrl in categoryThumbnails) {
        precacheImage(
          CachedNetworkImageProvider(
            imageService.optimizeUrl(
              imageUrl,
              width: 120,
              height: 120,
              quality: 70,
            ),
          ),
          context,
        );
      }
      
      // Preload banner images
      final bannerUrls = [
        'https://placehold.co/800x300/FF5722/FFFFFF?text=Fresh+Deals',
        'https://placehold.co/800x300/3F51B5/FFFFFF?text=20%+Off',
      ];
      
      for (final url in bannerUrls) {
        precacheImage(
          CachedNetworkImageProvider(
            imageService.optimizeUrl(
              url,
              quality: 80,
            ),
          ),
          context,
        );
      }
      
      // Set flag to indicate preloading has been done
      _hasPreloaded = true;
      
      print('✅ Preloaded key images for smoother initial experience');
    } catch (e) {
      print('⚠️ Error preloading images: $e');
    }
  }
  
  /// Preload product-specific images before opening product detail
  /// Call this when user navigates to product list or category view
  Future<void> preloadProductImages(BuildContext context, List<String> imageUrls) async {
    try {      
      // Preload images at thumbnail quality
      for (final imageUrl in imageUrls) {
        precacheImage(
          CachedNetworkImageProvider(
            imageService.optimizeUrl(
              imageUrl,
              width: 150,
              height: 150,
              quality: 70,
            ),
          ),
          context,
        );
      }
    } catch (e) {
      print('⚠️ Error preloading product images: $e');
    }
  }
  
  /// Preload specific product detail images
  /// Call this when user is likely to tap on a product
  Future<void> preloadProductDetail(BuildContext context, String mainImageUrl, List<String>? additionalImages) async {
    try {
      // Preload main product image at high quality
      precacheImage(
        CachedNetworkImageProvider(
          imageService.optimizeUrl(
            mainImageUrl,
            quality: 90,
          ),
        ),
        context,
      );
      
      // Preload additional images if available
      if (additionalImages != null && additionalImages.isNotEmpty) {
        for (final imageUrl in additionalImages) {
          precacheImage(
            CachedNetworkImageProvider(
              imageService.optimizeUrl(
                imageUrl,
                quality: 80,
              ),
            ),
            context,
          );
        }
      }
    } catch (e) {
      print('⚠️ Error preloading product detail: $e');
    }
  }
}

/// Global singleton instance for easy access
final imagePreloader = ImagePreloader(); 