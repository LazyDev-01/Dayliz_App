import 'package:flutter/material.dart';

/// A utility class for preloading images
class ImagePreloader {
  /// Singleton instance
  static final ImagePreloader instance = ImagePreloader._internal();

  /// Private constructor
  ImagePreloader._internal();

  /// Factory constructor
  factory ImagePreloader() => instance;

  /// Preload key images that are used throughout the app
  void preloadKeyImages(BuildContext context) {
    // List of images to preload with error handling
    final imagesToPreload = [
      'assets/images/app_logo.png',
      'assets/images/splash_logo.png',
      'assets/images/empty_cart.png',
      'assets/images/empty_wishlist.png',
      'assets/images/empty_orders.png',
      'assets/images/empty_search.png',
      'assets/icons/fruits.png',
      'assets/icons/vegetables.png',
      'assets/icons/dairy.png',
      'assets/icons/bakery.png',
      'assets/icons/meat.png',
      'assets/icons/cash.png',
      'assets/icons/credit_card.png',
      'assets/images/placeholder_product.png',
      'assets/images/placeholder_profile.png',
    ];

    // Preload each image with error handling
    for (final imagePath in imagesToPreload) {
      _preloadImageSafely(imagePath, context);
    }
  }

  /// Safely preload an image with error handling
  void _preloadImageSafely(String imagePath, BuildContext context) {
    try {
      precacheImage(AssetImage(imagePath), context).catchError((error) {
        debugPrint('Warning: Failed to preload image: $imagePath - $error');
        // Continue execution even if image fails to load
        return null;
      });
    } catch (e) {
      debugPrint('Warning: Error preloading image: $imagePath - $e');
      // Continue execution even if image fails to load
    }
  }
}
