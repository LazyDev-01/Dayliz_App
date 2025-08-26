import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProductImageCarousel extends StatefulWidget {
  final String mainImageUrl;
  final List<String>? additionalImages;
  final String productId;
  final double width;
  final double height;
  final int quality;
  
  const ProductImageCarousel({
    Key? key,
    required this.mainImageUrl,
    this.additionalImages,
    required this.productId,
    required this.width,
    required this.height,
    this.quality = 90,
  }) : super(key: key);

  @override
  State<ProductImageCarousel> createState() => _ProductImageCarouselState();
}

class _ProductImageCarouselState extends State<ProductImageCarousel> {
  int _currentImageIndex = 0;
  late final PageController _pageController;
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AspectRatio(
        aspectRatio: widget.width / widget.height,
        child: Stack(
          children: [
            _buildImagePageView(),
            if (_hasMultipleImages())
              _buildPageIndicators(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildImagePageView() {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          _currentImageIndex = index;
        });
      },
      itemCount: _getImageCount(),
      itemBuilder: (context, index) {
        final imageUrl = _getImageUrl(index);
        final heroTag = _getHeroTag(index);
        
        return Hero(
          tag: heroTag,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              width: widget.width,
              height: widget.height,
              fit: BoxFit.cover,
              memCacheWidth: widget.width.toInt(),
              memCacheHeight: widget.height.toInt(),
              fadeInDuration: const Duration(milliseconds: 300),
              fadeOutDuration: const Duration(milliseconds: 100),
              placeholder: (context, url) => Container(
                width: widget.width,
                height: widget.height,
                color: Colors.grey[200],
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                width: widget.width,
                height: widget.height,
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(
                    Icons.image_not_supported,
                    color: Colors.grey,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildPageIndicators() {
    return Positioned(
      bottom: 16,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          _getImageCount(),
          (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: _currentImageIndex == index ? 12 : 8,
            height: _currentImageIndex == index ? 12 : 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _currentImageIndex == index
                ? Theme.of(context).primaryColor
                : Colors.grey.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
  
  bool _hasMultipleImages() {
    return widget.additionalImages != null && widget.additionalImages!.isNotEmpty;
  }
  
  int _getImageCount() {
    return _hasMultipleImages() 
      ? 1 + widget.additionalImages!.length 
      : 1;
  }
  
  String _getImageUrl(int index) {
    return index == 0 
      ? widget.mainImageUrl 
      : widget.additionalImages![index - 1];
  }
  
  String _getHeroTag(int index) {
    return index == 0 
      ? 'product_image_${widget.productId}' 
      : 'product_image_${widget.productId}_$index';
  }
} 