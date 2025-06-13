# Unified App Bar System

This document provides comprehensive guidance on using the new unified app bar system in the Dayliz App.

## Overview

The Unified App Bar System provides a consistent, modern app bar design across all screens including the home screen. It replaces multiple inconsistent app bar implementations with a single, cohesive system that preserves the unique home screen features while maintaining consistency.

## Design Specifications

### Visual Design
- **Background**: Pure white (`Colors.white`)
- **Shadow**: Subtle shadow effect (10% black opacity, 2px offset, 4px blur)
- **Text Color**: Dark grey (`#374151` - Tailwind gray-700)
- **Font**: 18px, semi-bold (FontWeight.w600)
- **Title Position**: Centered by default

### Back Button Types
1. **Previous Page Navigation**: Standard back to previous screen with fallback
2. **Direct Home Navigation**: Direct navigation to home screen

## Usage

### Basic Implementation

```dart
import '../../widgets/common/unified_app_bar.dart';

// Simple app bar with back button
appBar: UnifiedAppBars.withBackButton(
  title: 'Screen Title',
  fallbackRoute: '/home',
)
```

### Factory Methods

#### 1. Simple App Bar (No Back Button)
```dart
appBar: UnifiedAppBars.simple(
  title: 'Title Only',
  actions: [/* optional actions */],
)
```

#### 2. Standard Back Navigation
```dart
appBar: UnifiedAppBars.withBackButton(
  title: 'Product Details',
  fallbackRoute: '/home',
  onBackPressed: () => customBackLogic(), // optional
)
```

#### 3. Direct Home Navigation
```dart
appBar: UnifiedAppBars.withHomeButton(
  title: 'Order Summary',
  onBackPressed: () => customHomeLogic(), // optional
)
```

#### 4. With Search Action
```dart
appBar: UnifiedAppBars.withSearch(
  title: 'Products',
  onSearchPressed: () => openSearch(),
  backButtonType: BackButtonType.previousPage,
)
```

#### 5. With Cart Action
```dart
appBar: UnifiedAppBars.withCart(
  title: 'Categories',
  onCartPressed: () => openCart(),
  cartItemCount: 3, // shows badge
)
```

#### 6. With Search and Cart
```dart
appBar: UnifiedAppBars.withSearchAndCart(
  title: 'Products',
  onSearchPressed: () => openSearch(),
  onCartPressed: () => openCart(),
  cartItemCount: 5,
)
```

#### 7. Home Screen (Special)
```dart
appBar: UnifiedAppBars.homeScreen(
  onSearchTap: () => openSearch(),
  onProfileTap: () => openProfile(),
  searchHint: 'Search for products...',
  enableCloudAnimation: false,
  cloudType: CloudAnimationType.peaceful,
  cloudOpacity: 0.45,
  cloudColor: Colors.white,
)
```

### Custom Implementation

For advanced use cases, use the base `UnifiedAppBar` widget:

```dart
appBar: UnifiedAppBar(
  title: 'Custom Screen',
  showBackButton: true,
  backButtonType: BackButtonType.directHome,
  actions: [
    SvgIconButtons.search(onPressed: () => {}),
    SvgIconButtons.cart(onPressed: () => {}, badgeCount: 2),
  ],
  bottom: TabBar(tabs: [...]), // optional bottom widget
)
```

## Migration Guide

### Before (Inconsistent Implementations)

```dart
// Categories Screen - Direct AppBar
appBar: AppBar(
  title: const Text('Categories'),
  backgroundColor: AppColors.appBarSecondary,
  elevation: 4,
  // ... more styling
)

// Profile Screen - CommonAppBar
appBar: CommonAppBars.withBackButton(
  title: 'Profile',
  backgroundColor: Colors.white,
)

// Cart Screen - Custom implementation
appBar: _buildAppBar()
```

### After (Unified System)

```dart
// All screens use unified system
appBar: UnifiedAppBars.withBackButton(
  title: 'Categories', // or 'Profile', 'Cart', etc.
  fallbackRoute: '/home',
)
```

## Screen-Specific Implementations

### 1. Categories Screen
```dart
appBar: UnifiedAppBars.withBackButton(
  title: 'Categories',
  fallbackRoute: '/home',
)
```

### 2. Product Details Screen
```dart
appBar: UnifiedAppBars.withCart(
  title: 'Product Details',
  onCartPressed: () => context.go('/cart'),
  cartItemCount: cartItems.length,
)
```

### 3. Product Listing Screen
```dart
appBar: UnifiedAppBars.withSearchAndCart(
  title: subcategoryName ?? 'Products',
  onSearchPressed: () => _openSearch(),
  onCartPressed: () => context.go('/cart'),
  cartItemCount: cartItems.length,
)
```

### 4. Profile Screen
```dart
appBar: UnifiedAppBars.withBackButton(
  title: 'Profile',
  fallbackRoute: '/home',
)
```

### 5. Cart Screen
```dart
appBar: UnifiedAppBars.withBackButton(
  title: 'Shopping Cart',
  fallbackRoute: '/home',
)
```

### 6. Orders Screen
```dart
appBar: UnifiedAppBars.withHomeButton(
  title: 'My Orders',
)
```

### 7. Order Details Screen
```dart
appBar: UnifiedAppBars.withHomeButton(
  title: 'Order Details',
)
```

### 8. Wishlist Screen
```dart
appBar: UnifiedAppBars.withBackButton(
  title: 'Wishlist',
  fallbackRoute: '/home',
)
```

### 9. Search Screen
```dart
appBar: UnifiedAppBars.withBackButton(
  title: 'Search',
  fallbackRoute: '/home',
)
```

### 10. Auth Screens
```dart
// Login/Register screens
appBar: UnifiedAppBars.withBackButton(
  title: 'Sign In', // or 'Create Account'
  fallbackRoute: '/home',
)
```

### 11. Home Screen (Special Features)
```dart
appBar: UnifiedAppBars.homeScreen(
  onSearchTap: () => context.push('/search'),
  onProfileTap: () => context.push('/profile'),
  searchHint: 'Search for products...',
  enableCloudAnimation: false, // Optional cloud animations
  cloudType: CloudAnimationType.peaceful, // Peaceful clouds for home
  cloudOpacity: 0.45, // Subtle but visible
  cloudColor: Colors.white, // Pure white clouds
)
```

**Home Screen Features:**
- **Enhanced Profile Icon**: Animated profile icon with sophisticated design
- **Integrated Search Bar**: Custom search bar with premium styling
- **Gradient Background**: Fresh green to sunny yellow gradient
- **Cloud Animations**: Optional peaceful cloud animations
- **"Dayliz" Branding**: Custom typography and brand identity
- **Responsive Design**: Dynamic spacing based on device status bar

## Back Button Behavior

### Previous Page Navigation (`BackButtonType.previousPage`)
- **Primary**: Uses `Navigator.pop()` to go back
- **Fallback**: If can't pop, navigates to specified fallback route
- **Use Cases**: Most screens, forms, detail views

### Direct Home Navigation (`BackButtonType.directHome`)
- **Behavior**: Always navigates directly to `/home`
- **Use Cases**: Order summaries, payment confirmations, deep-linked screens

## Best Practices

### 1. Consistency
- Use the same factory method for similar screen types
- Maintain consistent fallback routes
- Use appropriate back button types

### 2. Actions
- Limit actions to 2-3 items for mobile screens
- Use SVG icons for all actions
- Provide meaningful tooltips

### 3. Titles
- Keep titles concise and descriptive
- Use sentence case (e.g., "Product details" not "Product Details")
- Avoid generic titles like "Screen" or "Page"

### 4. Navigation
- Use `previousPage` for most screens
- Use `directHome` for completion screens (orders, payments)
- Always provide fallback routes

## Accessibility

### Features
- **Semantic Labels**: All icons have proper semantic labels
- **Tooltips**: Interactive elements include helpful tooltips
- **Color Contrast**: Dark grey text meets WCAG guidelines
- **Focus Indicators**: Proper keyboard navigation support

### Implementation
```dart
// Automatic accessibility support
appBar: UnifiedAppBars.withBackButton(
  title: 'Accessible Screen', // Used by screen readers
  fallbackRoute: '/home',
)
```

## Testing

### Demo Screen
Use the `UnifiedAppBarDemoScreen` to test different app bar configurations:

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const UnifiedAppBarDemoScreen(),
  ),
);
```

### Manual Testing Checklist
- [ ] White background displays correctly
- [ ] Shadow effect is visible
- [ ] Dark grey text is readable
- [ ] Back button navigates correctly
- [ ] Actions work as expected
- [ ] Badge counts display properly
- [ ] Tooltips appear on long press
- [ ] Accessibility features work with screen readers

## Troubleshooting

### Common Issues

#### 1. Import Error
```dart
// Ensure correct import
import '../../widgets/common/unified_app_bar.dart';
```

#### 2. Back Navigation Not Working
```dart
// Provide fallback route
appBar: UnifiedAppBars.withBackButton(
  title: 'Screen',
  fallbackRoute: '/home', // Important!
)
```

#### 3. Actions Not Displaying
```dart
// Check SVG icon imports
import '../../widgets/common/svg_icon_button.dart';
```

## Future Enhancements

### Planned Features
- [ ] Animated transitions between app bars
- [ ] Theme-based color variations
- [ ] Advanced search integration
- [ ] Notification badges
- [ ] Context-aware actions

### Customization Options
- [ ] Custom shadow configurations
- [ ] Alternative color schemes
- [ ] Dynamic title animations
- [ ] Responsive design for tablets
