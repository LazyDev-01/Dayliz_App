import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';

/// A service for optimized image loading and processing
class ImageService {
  static final ImageService _instance = ImageService._internal();
  
  factory ImageService() => _instance;
  
  ImageService._internal();
  
  /// Base URL for Cloudinary transformation
  /// Replace with your actual Cloudinary cloud name
  final String _cloudinaryBase = 'https://res.cloudinary.com/daylizapp/image/fetch';
  
  /// Prefix for local assets
  final String _assetPrefix = 'assets/';
  
  /// Default placeholder image path
  final String _defaultPlaceholderPath = 'assets/images/placeholder.png';
  
  /// Memory cache for failed URLs to avoid repeated attempts
  final Set<String> _failedUrls = {};
  
  /// Get device pixel ratio for appropriate image sizing
  double get devicePixelRatio => WidgetsBinding.instance.window.devicePixelRatio;
  
  /// Transform an image URL to use Cloudinary for optimization
  /// Parameters:
  ///   url: Original image URL
  ///   width: Desired width in logical pixels
  ///   height: Desired height in logical pixels
  ///   quality: Image quality (0-100)
  String optimizeUrl(String url, {int? width, int? height, int quality = 80}) {
    // If it's already a failed URL, return placeholder immediately
    if (_failedUrls.contains(url)) {
      return _defaultPlaceholderPath;
    }
    
    // If it's a local asset, return as is
    if (url.startsWith(_assetPrefix)) {
      return url;
    }
    
    // Handle null or empty URLs
    if (url.isEmpty) {
      return _defaultPlaceholderPath;
    }
    
    // Skip optimization for development placeholder images
    if (url.contains('placehold.co') || url.contains('placeholder.com')) {
      return url;
    }
    
    try {
      // Check if URL is valid
      final uri = Uri.parse(url);
      if (!uri.isAbsolute || (!url.startsWith('http://') && !url.startsWith('https://'))) {
        _failedUrls.add(url);
        return _defaultPlaceholderPath;
      }
      
      // Calculate device-appropriate dimensions if specified
      final deviceWidth = width != null ? (width * devicePixelRatio).round() : null;
      final deviceHeight = height != null ? (height * devicePixelRatio).round() : null;
      
      // Build Cloudinary transformation URL
      String transformations = '';
      
      // Add width/height transformations if specified
      if (deviceWidth != null || deviceHeight != null) {
        transformations += '/c_fill';
        if (deviceWidth != null) transformations += ',w_$deviceWidth';
        if (deviceHeight != null) transformations += ',h_$deviceHeight';
      }
      
      // Add quality transformation
      transformations += ',q_$quality';
      
      // Add format optimization - convert to WebP for better performance
      transformations += ',f_auto';
      
      // Return full Cloudinary URL
      return '$_cloudinaryBase$transformations/$url';
    } catch (e) {
      // If URL parsing fails, mark as failed and return placeholder
      _failedUrls.add(url);
      return _defaultPlaceholderPath;
    }
  }
  
  /// Get optimized CachedNetworkImage widget
  /// Handles loading, errors, and proper caching
  Widget getOptimizedImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? errorWidget,
    Widget? placeholder,
    String? heroTag,
    BorderRadius? borderRadius,
    int quality = 80,
    bool preload = false,
  }) {
    // Handle empty or invalid URLs immediately
    if (imageUrl.isEmpty || _failedUrls.contains(imageUrl)) {
      return _buildPlaceholderWidget(width, height, errorWidget);
    }
    
    // Optimize URL
    final optimizedUrl = optimizeUrl(
      imageUrl, 
      width: width?.toInt(), 
      height: height?.toInt(),
      quality: quality,
    );
    
    // If URL optimization returned the placeholder path, show placeholder
    if (optimizedUrl == _defaultPlaceholderPath) {
      return _buildPlaceholderWidget(width, height, errorWidget);
    }
    
    // Default placeholder uses shimmer effect
    final defaultPlaceholder = Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        color: Colors.white,
      ),
    );
    
    // Create the CachedNetworkImage widget with robust error handling
    Widget imageWidget = CachedNetworkImage(
      imageUrl: optimizedUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => placeholder ?? defaultPlaceholder,
      errorWidget: (context, url, error) {
        // Add to failed URLs list for future reference
        _failedUrls.add(imageUrl);
        return _buildPlaceholderWidget(width, height, errorWidget);
      },
      memCacheWidth: width != null ? (width * devicePixelRatio).toInt() : null,
      memCacheHeight: height != null ? (height * devicePixelRatio).toInt() : null,
      // Other optimization options
      fadeOutDuration: const Duration(milliseconds: 300),
      fadeInDuration: const Duration(milliseconds: 300),
      // More robust error handling
      maxWidthDiskCache: 800,
      maxHeightDiskCache: 800,
      useOldImageOnUrlChange: true,
    );
    
    // Preload image if requested
    if (preload) {
      _safePreloadImage(optimizedUrl);
    }
    
    // Add hero animation if requested
    if (heroTag != null) {
      imageWidget = Hero(
        tag: heroTag,
        child: imageWidget,
      );
    }
    
    // Add border radius if requested
    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius,
        child: imageWidget,
      );
    }
    
    return imageWidget;
  }
  
  /// Safely preload an image with error handling
  void _safePreloadImage(String url) {
    try {
      if (NavigationService.navigatorKey.currentContext != null) {
        precacheImage(
          CachedNetworkImageProvider(url),
          NavigationService.navigatorKey.currentContext!,
        );
      }
    } catch (e) {
      // Silently handle preloading errors
      _failedUrls.add(url);
    }
  }
  
  /// Create a placeholder or error widget with consistent dimensions
  Widget _buildPlaceholderWidget(double? width, double? height, Widget? customErrorWidget) {
    final defaultErrorWidget = Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Center(
        child: Icon(Icons.image_not_supported, color: Colors.grey[400], size: 24),
      ),
    );
    
    return customErrorWidget ?? defaultErrorWidget;
  }
  
  /// Clear the failed URLs cache, useful if you want to retry loading previously failed images
  void clearFailedUrlsCache() {
    _failedUrls.clear();
  }
  
  /// Check if image URL is valid and accessible
  Future<bool> isImageUrlValid(String url) async {
    if (url.isEmpty || _failedUrls.contains(url)) return false;
    
    try {
      final uri = Uri.parse(url);
      if (!uri.isAbsolute) return false;
      
      final client = HttpClient();
      final request = await client.headUrl(uri);
      final response = await request.close();
      await response.drain();
      client.close();
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

/// Global singleton instance for easy access
final imageService = ImageService();

/// Navigation service to provide global context
/// This is a simple implementation and might need to be expanded based on your app
class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
} 