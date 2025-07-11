# Lottie Animation Integration Examples

## 🎯 **Overview**
This document provides practical examples of how to integrate the Lottie animation components into your existing Dayliz app screens.

## 📱 **1. Cart Screen Integration** ✅ **IMPLEMENTED**

### **✅ Current Implementation (Animated)**
```dart
// In modern_cart_screen.dart - ALREADY IMPLEMENTED
import '../../widgets/animations/animated_empty_state.dart';

// Empty cart section with Lottie animation:
if (cartState.items.isEmpty) {
  return DaylizEmptyStates.emptyCart(
    onStartShopping: () {
      context.goToMainHomeWithProvider(ref);
    },
    customTitle: 'Your cart is empty',
    customSubtitle: 'Add some delicious products to get started',
  );
}
```

**Features:**
- ✅ Uses your `empty_cart.json` Lottie animation
- ✅ Smooth fade-in and scale animations
- ✅ Fallback to static icon if animation fails
- ✅ Preserves existing navigation logic

## 🏠 **2. Home Screen Loading Integration**

### **Current Implementation**
```dart
// In clean_home_screen.dart - typical loading state
if (isLoading) {
  return const Center(
    child: CircularProgressIndicator(),
  );
}
```

### **Enhanced Implementation**
```dart
// Add import
import '../../widgets/animations/animated_loading_state.dart';

// Replace loading state with:
if (isLoading) {
  return DaylizLoadingStates.loadingProducts();
}

// For specific loading scenarios:
if (isRefreshing) {
  return DaylizLoadingStates.refreshing();
}
```

## 🔍 **3. Search Screen Integration**

### **Enhanced Search Loading**
```dart
// In enhanced_search_screen.dart
class EnhancedSearchScreen extends ConsumerStatefulWidget {
  // ... existing code

  Widget _buildSearchResults() {
    final searchState = ref.watch(searchNotifierProvider);
    
    if (searchState.isLoading) {
      return DaylizLoadingStates.search(
        searchTerm: _searchController.text,
      );
    }
    
    if (searchState.products.isEmpty && _searchController.text.isNotEmpty) {
      return DaylizEmptyStates.noSearchResults(
        searchTerm: _searchController.text,
        onBrowseCategories: () {
          context.go('/categories');
        },
      );
    }
    
    // ... rest of search results
  }
}
```

## 🛒 **4. Product Card Add-to-Cart Integration**

### **Current Implementation**
```dart
// In product card widgets
ElevatedButton(
  onPressed: () {
    // Add to cart logic
  },
  child: const Text('Add to Cart'),
)
```

### **Enhanced Implementation**
```dart
// Add import
import '../../widgets/animations/animated_add_to_cart.dart';

// Replace with animated button
AnimatedAddToCartButton(
  onAddToCart: () async {
    setState(() => _isAddingToCart = true);
    try {
      await ref.read(cartNotifierProvider.notifier).addItem(product);
      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Added to cart!'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isAddingToCart = false);
    }
  },
  isLoading: _isAddingToCart,
  buttonText: 'Add to Cart',
  showAnimation: true,
)
```

## 📦 **5. Order Success Integration**

### **Enhanced Order Confirmation**
```dart
// In checkout completion or order confirmation
void _showOrderSuccessDialog() {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DaylizLottieAnimations.successCheckmark(
            size: 100,
            onCompleted: () {
              // Auto-close dialog after animation
              Navigator.of(context).pop();
              context.go('/orders');
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'Order Placed Successfully!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Order #${orderNumber}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    ),
  );
}
```

## ❤️ **6. Wishlist Integration**

### **Enhanced Wishlist Button**
```dart
// In product cards or product details
class AnimatedWishlistButton extends StatefulWidget {
  final bool isWishlisted;
  final VoidCallback onToggle;
  
  const AnimatedWishlistButton({
    Key? key,
    required this.isWishlisted,
    required this.onToggle,
  }) : super(key: key);

  @override
  State<AnimatedWishlistButton> createState() => _AnimatedWishlistButtonState();
}

class _AnimatedWishlistButtonState extends State<AnimatedWishlistButton> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onToggle,
      child: DaylizLottieAnimations.heartLike(
        size: 24,
        isLiked: widget.isWishlisted,
        onCompleted: () {
          // Animation completed
        },
      ),
    );
  }
}
```

## 📱 **7. Bottom Navigation Enhancement**

### **Animated Navigation Icons**
```dart
// In common_bottom_nav_bar.dart
import '../animations/lottie_animation_widget.dart';

class AnimatedNavIcon extends StatelessWidget {
  final String animationPath;
  final bool isSelected;
  final double size;
  
  const AnimatedNavIcon({
    Key? key,
    required this.animationPath,
    required this.isSelected,
    this.size = 24,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LottieAnimationWidget(
      animationPath: animationPath,
      width: size,
      height: size,
      autoStart: isSelected,
      repeat: false,
      speed: 1.5,
    );
  }
}

// Usage in bottom navigation
BottomNavigationBarItem(
  icon: AnimatedNavIcon(
    animationPath: AnimationConstants.homeIcon,
    isSelected: currentIndex == 0,
  ),
  label: 'Home',
)
```

## 🚀 **8. Floating Cart Button Integration**

### **Enhanced Floating Cart**
```dart
// In main screen or product listing screens
import '../../widgets/animations/animated_add_to_cart.dart';

class MainScreenWithFloatingCart extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartNotifierProvider);
    
    return Scaffold(
      // ... existing content
      floatingActionButton: FloatingAddToCartButton(
        isVisible: cartState.itemCount > 0,
        itemCount: cartState.itemCount,
        isLoading: cartState.isLoading,
        onPressed: () {
          context.go('/cart');
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
```

## 🌐 **8. Network Error Integration** ✅ **IMPLEMENTED**

### **Enhanced Network Error Handling**
```dart
// Add import
import '../../widgets/animations/animated_network_error.dart';

// For general network errors
DaylizNetworkErrors.connectionError(
  onRetry: () {
    // Retry logic
    ref.read(someProvider.notifier).retry();
  },
)

// For API errors
DaylizNetworkErrors.serverError(
  customMessage: 'Service temporarily unavailable',
  onRetry: () => _retryApiCall(),
)

// Network-aware widget wrapper
NetworkAwareWidget(
  hasNetworkError: networkState.hasError,
  errorMessage: networkState.errorMessage,
  onRetry: () => _handleRetry(),
  child: YourMainContent(),
)
```

## 🎉 **9. Success Feedback Integration** ✅ **IMPLEMENTED**

### **Order Success Dialog**
```dart
// Show order success with animation
SuccessDialog.showOrderSuccess(
  context,
  orderNumber: 'DLZ123456',
  onViewOrder: () => context.go('/orders'),
  onContinueShopping: () => context.go('/home'),
);

// Payment success
SuccessDialog.showPaymentSuccess(
  context,
  amount: '₹299',
  onCompleted: () => context.go('/orders'),
);

// Quick success snackbar
SuccessSnackbar.show(
  context,
  message: 'Item added to cart!',
);
```

## 📋 **Implementation Checklist**

### **Phase 1: Essential Animations** ✅ **COMPLETED**
- [x] Download and add empty cart Lottie animation
- [x] Replace static empty cart with `DaylizEmptyStates.emptyCart()`
- [x] Download and add success checkmark animation
- [x] Implement order success dialog with animation
- [x] Download and add network error animation
- [x] Create network error handling widgets

### **Phase 2: Interactive Animations**
- [ ] Download and add add-to-cart animation
- [ ] Replace product card buttons with `AnimatedAddToCartButton`
- [ ] Download and add heart like animation
- [ ] Implement animated wishlist buttons
- [ ] Add floating cart button with animations

### **Phase 3: Advanced Animations**
- [ ] Download navigation icon animations
- [ ] Implement animated bottom navigation
- [ ] Add search loading animations
- [ ] Implement empty search results animation
- [ ] Add order tracking animations

## 🎨 **Animation Asset Requirements**

Create the following directory structure and add Lottie JSON files:

```
assets/animations/
├── loading/
│   ├── splash_logo.json
│   ├── skeleton_loading.json
│   └── search_loading.json
├── interactions/
│   ├── add_to_cart.json
│   ├── heart_like.json
│   └── success_checkmark.json
├── empty_states/
│   ├── empty_cart.json
│   ├── no_orders.json
│   └── no_search_results.json
└── navigation/
    ├── home_icon.json
    ├── categories_icon.json
    ├── cart_icon.json
    └── orders_icon.json
```

## 🔧 **Testing Guidelines**

1. **Performance Testing**: Test animations on low-end devices
2. **Memory Testing**: Monitor memory usage during animations
3. **Accessibility Testing**: Ensure animations don't interfere with screen readers
4. **User Testing**: Gather feedback on animation timing and feel
5. **Fallback Testing**: Test fallback icons when animations fail to load
