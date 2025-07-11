import 'package:flutter/material.dart';
import 'lottie_animation_widget.dart';
import '../../../core/constants/animation_constants.dart';

/// An animated loading state widget that displays Lottie animations
/// for various loading scenarios in the app
class AnimatedLoadingState extends StatelessWidget {
  /// Type of loading state to display
  final LoadingStateType type;
  
  /// Custom loading message
  final String? message;
  
  /// Custom animation path (overrides the default for the type)
  final String? customAnimationPath;
  
  /// Animation size
  final double? animationSize;
  
  /// Whether to show the loading message
  final bool showMessage;
  
  /// Custom text style for the message
  final TextStyle? messageStyle;
  
  /// Background color for the loading overlay
  final Color? backgroundColor;
  
  /// Whether this is a full-screen overlay
  final bool isOverlay;

  const AnimatedLoadingState({
    Key? key,
    required this.type,
    this.message,
    this.customAnimationPath,
    this.animationSize,
    this.showMessage = true,
    this.messageStyle,
    this.backgroundColor,
    this.isOverlay = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final config = _getLoadingStateConfig(type);
    final theme = Theme.of(context);
    
    Widget content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Lottie Animation
        LottieAnimationWidget(
          animationPath: customAnimationPath ?? config.animationPath,
          width: animationSize ?? config.defaultSize,
          height: animationSize ?? config.defaultSize,
          repeat: true,
          autoStart: true,
          speed: config.speed,
          fallback: SizedBox(
            width: animationSize ?? config.defaultSize,
            height: animationSize ?? config.defaultSize,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.primaryColor,
              ),
            ),
          ),
        ),
        
        if (showMessage) ...[
          const SizedBox(height: 16),
          Text(
            message ?? config.defaultMessage,
            style: messageStyle ?? theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
    
    if (isOverlay) {
      return Container(
        color: backgroundColor ?? Colors.black.withOpacity(0.5),
        child: Center(child: content),
      );
    }
    
    return Center(child: content);
  }

  LoadingStateConfig _getLoadingStateConfig(LoadingStateType type) {
    switch (type) {
      case LoadingStateType.general:
        return LoadingStateConfig(
          animationPath: AnimationConstants.searchLoading,
          defaultMessage: 'Loading...',
          defaultSize: 60,
          speed: 1.0,
        );
        
      case LoadingStateType.search:
        return LoadingStateConfig(
          animationPath: AnimationConstants.searchLoading,
          defaultMessage: 'Searching products...',
          defaultSize: 80,
          speed: 1.2,
        );
        
      case LoadingStateType.addingToCart:
        return LoadingStateConfig(
          animationPath: AnimationConstants.addToCart,
          defaultMessage: 'Adding to cart...',
          defaultSize: 50,
          speed: 1.5,
        );
        
      case LoadingStateType.processingPayment:
        return LoadingStateConfig(
          animationPath: AnimationConstants.searchLoading,
          defaultMessage: 'Processing payment...',
          defaultSize: 80,
          speed: 0.8,
        );
        
      case LoadingStateType.placingOrder:
        return LoadingStateConfig(
          animationPath: AnimationConstants.searchLoading,
          defaultMessage: 'Placing your order...',
          defaultSize: 80,
          speed: 0.8,
        );
        
      case LoadingStateType.loadingProducts:
        return LoadingStateConfig(
          animationPath: AnimationConstants.skeletonLoading,
          defaultMessage: 'Loading products...',
          defaultSize: 60,
          speed: 1.0,
        );
        
      case LoadingStateType.refreshing:
        return LoadingStateConfig(
          animationPath: AnimationConstants.searchLoading,
          defaultMessage: 'Refreshing...',
          defaultSize: 40,
          speed: 1.5,
        );
    }
  }
}

/// Types of loading states supported by the widget
enum LoadingStateType {
  general,
  search,
  addingToCart,
  processingPayment,
  placingOrder,
  loadingProducts,
  refreshing,
}

/// Configuration for each loading state type
class LoadingStateConfig {
  final String animationPath;
  final String defaultMessage;
  final double defaultSize;
  final double speed;

  const LoadingStateConfig({
    required this.animationPath,
    required this.defaultMessage,
    required this.defaultSize,
    required this.speed,
  });
}

/// A shimmer loading widget with Lottie animation enhancement
class AnimatedShimmerLoading extends StatelessWidget {
  /// Number of shimmer items to display
  final int itemCount;
  
  /// Height of each shimmer item
  final double itemHeight;
  
  /// Whether to show a Lottie loading animation at the top
  final bool showTopAnimation;
  
  /// Custom loading message
  final String? message;

  const AnimatedShimmerLoading({
    Key? key,
    this.itemCount = 5,
    this.itemHeight = 80,
    this.showTopAnimation = true,
    this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showTopAnimation) ...[
          const SizedBox(height: 20),
          AnimatedLoadingState(
            type: LoadingStateType.loadingProducts,
            message: message,
            animationSize: 60,
          ),
          const SizedBox(height: 20),
        ],
        
        Expanded(
          child: ListView.builder(
            itemCount: itemCount,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                height: itemHeight,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    // Image placeholder
                    Container(
                      width: itemHeight,
                      height: itemHeight,
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    
                    // Content placeholder
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              height: 16,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 12,
                              width: 150,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Quick factory methods for common loading states
class DaylizLoadingStates {
  static Widget general({
    String? message,
    double? size,
  }) {
    return AnimatedLoadingState(
      type: LoadingStateType.general,
      message: message,
      animationSize: size,
    );
  }

  static Widget search({
    String? searchTerm,
  }) {
    return AnimatedLoadingState(
      type: LoadingStateType.search,
      message: searchTerm != null 
        ? 'Searching for "$searchTerm"...'
        : 'Searching products...',
    );
  }

  static Widget addingToCart() {
    return AnimatedLoadingState(
      type: LoadingStateType.addingToCart,
      animationSize: 40,
    );
  }

  static Widget processingPayment() {
    return AnimatedLoadingState(
      type: LoadingStateType.processingPayment,
      isOverlay: true,
    );
  }

  static Widget placingOrder() {
    return AnimatedLoadingState(
      type: LoadingStateType.placingOrder,
      isOverlay: true,
    );
  }

  static Widget loadingProducts() {
    return AnimatedLoadingState(
      type: LoadingStateType.loadingProducts,
    );
  }

  static Widget refreshing() {
    return AnimatedLoadingState(
      type: LoadingStateType.refreshing,
      showMessage: false,
      animationSize: 30,
    );
  }

  static Widget shimmerList({
    int itemCount = 5,
    double itemHeight = 80,
    String? message,
  }) {
    return AnimatedShimmerLoading(
      itemCount: itemCount,
      itemHeight: itemHeight,
      message: message,
    );
  }
}
