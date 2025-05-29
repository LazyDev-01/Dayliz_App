# Common App Bar Usage Guide

This document provides guidance on using the `CommonAppBar` widget for consistent navigation and UI throughout the Dayliz App.

## Overview

The `CommonAppBar` is a reusable component that provides a consistent app bar appearance and behavior across the app. It builds on the existing `BackButtonWidget` and adds more functionality and customization options.

> **Note**: The sidebar/drawer has been removed from the app. See `docs/sidebar_removal.md` for details on this change.

## Basic Usage

### 1. Simple App Bar (No Back Button)

```dart
appBar: CommonAppBars.simple(
  title: 'Screen Title',
  actions: [
    IconButton(
      icon: const Icon(Icons.notifications_outlined),
      onPressed: () {},
    ),
  ],
),
```

### 2. App Bar with Back Button

```dart
appBar: CommonAppBars.withBackButton(
  title: 'Screen Title',
  fallbackRoute: '/home',
  actions: [
    IconButton(
      icon: const Icon(Icons.settings),
      onPressed: () {},
    ),
  ],
),
```

### 3. App Bar with Search

```dart
appBar: CommonAppBars.withSearch(
  title: 'Products',
  onSearchPressed: () {
    // Navigate to search screen
    context.go('/search');
  },
  showBackButton: true,
  fallbackRoute: '/home',
),
```

### 4. App Bar with Cart and Search

```dart
appBar: CommonAppBars.withCartAndSearch(
  title: 'Products',
  onSearchPressed: () {
    context.go('/search');
  },
  onCartPressed: () {
    context.go('/cart');
  },
  cartItemCount: cartItems.length,
  showBackButton: true,
),
```

## Customization Options

The `CommonAppBar` supports several customization options:

### Visual Customization

```dart
CommonAppBar(
  title: 'Custom App Bar',
  backgroundColor: Colors.blue,
  foregroundColor: Colors.white,
  elevation: 8.0,
  showShadow: true,
  centerTitle: false,
)
```

### Navigation Behavior

```dart
CommonAppBar(
  title: 'Custom Navigation',
  showBackButton: true,
  fallbackRoute: '/profile',
  onBackPressed: () {
    // Custom navigation logic
    context.go('/custom-route');
  },
)
```

### Bottom Widget (e.g., TabBar)

```dart
CommonAppBar(
  title: 'With Tabs',
  bottom: TabBar(
    tabs: [
      Tab(text: 'Tab 1'),
      Tab(text: 'Tab 2'),
    ],
  ),
)
```

## Best Practices

1. **Consistent Appearance**: Use the same app bar style for similar screens to create a cohesive user experience.

2. **Use Factory Methods**: The `CommonAppBars` class provides factory methods for common configurations. Use these when possible for consistency.

3. **Custom Navigation**: Override the default behavior only when necessary, to maintain consistency.

4. **Responsive Design**: Consider how the app bar will appear on different screen sizes.

## Example Implementations

### Home Screen

```dart
appBar: CommonAppBars.withCartAndSearch(
  title: 'Dayliz',
  onSearchPressed: () => context.go('/search'),
  onCartPressed: () => context.go('/cart'),
  cartItemCount: ref.watch(cartItemCountProvider),
),
```

### Profile Screen

```dart
appBar: CommonAppBars.simple(
  title: 'My Profile',
  actions: [
    IconButton(
      icon: const Icon(Icons.settings),
      onPressed: () => context.go('/settings'),
    ),
  ],
),
```

### Product Details Screen

```dart
appBar: CommonAppBars.withBackButton(
  title: product.name,
  fallbackRoute: '/products',
  actions: [
    IconButton(
      icon: Icon(
        isInWishlist ? Icons.favorite : Icons.favorite_border,
        color: isInWishlist ? Colors.red : null,
      ),
      onPressed: () => _toggleWishlist(),
    ),
    IconButton(
      icon: const Icon(Icons.share),
      onPressed: () => _shareProduct(),
    ),
  ],
),
```

## Migration from Existing App Bars

When migrating from existing app bars to the `CommonAppBar`:

1. Replace `AppBar` with the appropriate `CommonAppBars` factory method
2. Move any custom logic to the appropriate callbacks
3. Keep the same actions and functionality, but use the consistent styling

Example migration:

Before:
```dart
appBar: AppBar(
  title: const Text('My Cart'),
  centerTitle: true,
  leading: IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        context.go('/home');
      }
    },
  ),
  actions: [
    IconButton(
      icon: const Icon(Icons.delete_outline),
      onPressed: () => _showClearCartDialog(context),
    ),
  ],
),
```

After:
```dart
appBar: CommonAppBars.withBackButton(
  title: 'My Cart',
  fallbackRoute: '/home',
  actions: [
    IconButton(
      icon: const Icon(Icons.delete_outline),
      onPressed: () => _showClearCartDialog(context),
    ),
  ],
),
```
