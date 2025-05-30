# Clean Architecture Product Card Design

## Overview

This document outlines the design and implementation of the new product card for the Dayliz App, following clean architecture principles and q-commerce industry standards.

## Design Principles

The product card design follows these key principles:

1. **Space Efficiency**: Maximizes the number of products visible on screen
2. **Visual Clarity**: Makes key information instantly recognizable
3. **Action Simplicity**: Minimizes steps required to add products to cart
4. **Performance**: Optimizes for fast scrolling and rendering
5. **Consistency**: Maintains visual harmony with the rest of the app

## Layout Structure

### Card Dimensions and Shape
- **Aspect Ratio**: 1:1.8 (width:height)
- **Image Ratio**: 1:1 (square)
- **Corner Radius**: 8px
- **Border**: None (borderless design)
- **Background**: White

### Content Sections (Top to Bottom)
1. **Image Section** (50% of card height)
2. **Information Section** (50% of card height)

## Content Order and Details

### 1. Image Section
- **Product Image**: Takes full width of the card in a square format
- **Discount Badge**: Top-left corner, small pill shape with percentage
- **Out of Stock Overlay**: Semi-transparent gray overlay with "Out of Stock" text (when applicable)

### 2. Information Section
The information section follows this order (top to bottom):

1. **Weight/Quantity** (e.g., "500g", "1L") - Small gray text
2. **Product Name** - 1-2 lines with ellipsis, slightly bold
3. **Price Information** - Horizontal layout:
   - Discounted price (bold)
   - Original price (strikethrough, gray, smaller)
4. **Add Button** - Right-aligned rectangular button with "ADD" text

## Interactive Elements

### Add Button
- **Default State**: Rectangular "ADD" button
- **Added State**: Quantity selector with "-" and "+" buttons
- **Tap Behavior**: Direct add to cart (no confirmation needed)

### Card Tap
- **Behavior**: Navigate to product details page

## Responsive Design

The product card is designed to be responsive across different screen sizes:

- **Small Phones**: 2 columns
- **Large Phones**: 2-3 columns
- **Tablets (Portrait)**: 3-4 columns
- **Tablets (Landscape)**: 4-5 columns

## Implementation Details

### Files
- `lib/presentation/widgets/product/clean_product_card.dart`: The main product card widget
- `lib/presentation/widgets/product/clean_product_grid.dart`: A reusable grid of product cards

### Key Components

1. **CleanProductCard**
   - Accepts a Product entity from the domain layer
   - Handles add to cart functionality
   - Displays product information in a clean, efficient layout
   - Adapts to different screen sizes

2. **CleanProductGrid**
   - Displays a grid of product cards
   - Handles loading, error, and empty states
   - Dynamically adjusts column count based on screen width
   - Provides shimmer placeholders during loading

### Integration

The product card has been integrated with:
- Product listing screen
- Wishlist screen

## Comparison with Industry Standards

This design closely follows what you see in popular q-commerce apps:

- **Blinkit Similarity**: Compact design, prominent discount badge, clean information hierarchy
- **Zepto Similarity**: Minimalist approach, efficient space usage
- **Difference**: Uses rectangular ADD button instead of circular for better usability

## Future Improvements

1. **Performance Optimization**:
   - Implement virtualized lists for very long product lists
   - Further optimize image loading and caching

2. **Personalization**:
   - Add "Frequently Bought" indicators
   - Add "New" badges for recently added products

3. **Accessibility**:
   - Enhance screen reader support
   - Add high contrast mode
