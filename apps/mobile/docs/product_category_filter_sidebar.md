# Product Category Filter Sidebar

## Overview

The Product Category Filter Sidebar is a UI component that provides quick filtering of products by subcategory, similar to the filtering experience in popular q-commerce apps like Zepto and Blinkit.

## Purpose

When browsing products within a main category (e.g., "Dairy, Bread & Eggs"), users often want to quickly filter to see only specific subcategories (e.g., "Milk", "Bread", "Eggs", etc.). The sidebar provides this functionality with a clean, vertical list of filter options.

## Implementation

The sidebar is implemented as a reusable widget called `CategoryFilterSidebar` that can be added to any product listing screen.

### Key Features

1. **Vertical Subcategory List**: Displays all subcategories in a scrollable vertical list
2. **"ALL" Option**: Includes an option to show all products (no filter)
3. **Visual Selection**: Clearly indicates the currently selected subcategory
4. **Compact Design**: Takes minimal horizontal space to maximize product display area
5. **Responsive**: Adapts to different screen sizes

### Usage Example

```dart
CategoryFilterSidebar(
  subcategories: ['Milk', 'Bread', 'Eggs', 'Yoghurt', 'Cheese'],
  selectedSubcategory: _selectedSubcategory,
  onSubcategorySelected: _filterBySubcategory,
  categoryTitle: 'Dairy & Bread',
  showAllOption: true,
  width: 80,
)
```

## Integration with Product Listing

The sidebar is integrated with the product listing screen as follows:

1. The screen extracts unique subcategories from the available products
2. The sidebar displays these subcategories as filter options
3. When a user selects a subcategory, the product list is filtered to show only products in that subcategory
4. The "ALL" option resets the filter to show all products

## Design Considerations

1. **Width**: The sidebar has a default width of 80 logical pixels, which is enough to display short subcategory names while maximizing space for products
2. **Color Scheme**: The selected subcategory is highlighted using the app's primary color
3. **Typography**: Uses the app's text theme for consistency
4. **Scrolling**: The subcategory list scrolls independently from the product grid

## Future Enhancements

1. **Search**: Add a search field at the top of the sidebar for quickly finding subcategories in large lists
2. **Expandable/Collapsible**: Allow users to collapse the sidebar to see more products
3. **Multi-select**: Enable selection of multiple subcategories
4. **Nested Categories**: Support for nested category hierarchies
5. **Filter Counts**: Show the number of products in each subcategory

## Example Screens

The sidebar has been implemented but is temporarily disabled in the `ProductCardTestScreen`. The code remains in place (commented out) for future activation and integration into the main product listing screens.

## Comparison with Competitors

This implementation follows the pattern used by leading q-commerce apps:

- **Zepto**: Vertical subcategory list on the left side of the product grid
- **Blinkit**: Vertical subcategory list with visual indicators for the selected category
- **Swiggy Instamart**: Similar vertical filtering approach

Our implementation combines the best aspects of these approaches while maintaining consistency with our app's design language.
