# Back Button Widget Usage Guide

This document provides guidance on using the `BackButtonWidget` for consistent navigation throughout the Dayliz App.

## Overview

The `BackButtonWidget` is a reusable component that provides consistent back navigation behavior across the app. It handles common navigation patterns and edge cases, making it easy to implement reliable back navigation.

## Basic Usage

### 1. As a Leading Widget in AppBar

```dart
appBar: AppBar(
  title: const Text('Screen Title'),
  leading: const BackButtonWidget(
    fallbackRoute: '/home',
    tooltip: 'Back to Home',
  ),
),
```

### 2. Using the AppBar Extension (Recommended)

```dart
appBar: AppBarBackButton.withBackButton(
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

## Customization Options

The `BackButtonWidget` supports several customization options:

### Icon Customization

```dart
BackButtonWidget(
  icon: Icons.arrow_back_ios, // Use iOS-style back arrow
  color: Colors.blue, // Custom color
)
```

### Navigation Behavior

```dart
BackButtonWidget(
  fallbackRoute: '/profile', // Where to go if can't pop
  onPressed: () {
    // Custom navigation logic
    context.go('/custom-route');
  },
)
```

### Feedback

```dart
BackButtonWidget(
  enableHapticFeedback: false, // Disable haptic feedback
)
```

## Best Practices

1. **Consistent Fallback Routes**: Use consistent fallback routes for similar screens to create predictable navigation patterns.

2. **Descriptive Tooltips**: Provide descriptive tooltips to improve accessibility.

3. **Use AppBar Extension**: The `AppBarBackButton.withBackButton()` extension method provides a clean way to create AppBars with back buttons.

4. **Custom Navigation**: Override the default behavior only when necessary, to maintain consistency.

## Example Implementations

### Profile Screen

```dart
appBar: AppBarBackButton.withBackButton(
  title: 'Profile',
  fallbackRoute: '/home',
),
```

### Address List Screen

```dart
appBar: AppBarBackButton.withBackButton(
  title: 'My Addresses',
  fallbackRoute: '/profile',
  tooltip: 'Back to Profile',
),
```

### Product Details Screen

```dart
appBar: AppBarBackButton.withBackButton(
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
  ],
),
```

## Handling Special Cases

### Deep Linking

When handling deep links, you might need custom navigation logic:

```dart
BackButtonWidget(
  onPressed: () {
    // Check if we came from a deep link
    if (fromDeepLink) {
      context.go('/home');
    } else {
      Navigator.of(context).pop();
    }
  },
)
```

### Nested Navigation

For screens with nested navigation:

```dart
BackButtonWidget(
  onPressed: () {
    // Check if inner navigator can pop
    if (innerNavigatorKey.currentState?.canPop() ?? false) {
      innerNavigatorKey.currentState?.pop();
    } else {
      Navigator.of(context).pop();
    }
  },
)
```

## Migration Guide

To migrate existing screens to use the `BackButtonWidget`:

1. Import the widget: `import '../../widgets/common/back_button_widget.dart';`
2. Replace existing back button implementations with `BackButtonWidget`
3. Set appropriate fallback routes based on the screen's place in the navigation hierarchy
