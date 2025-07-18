import 'package:equatable/equatable.dart';

/// Sort options for products
enum SortOption {
  relevance('relevance', 'Relevance'),
  priceLowToHigh('price_asc', 'Price (Low To High)'),
  priceHighToLow('price_desc', 'Price (High To Low)'),
  discounts('discount_desc', 'Discounts');

  const SortOption(this.value, this.label);

  final String value;
  final String label;

  static SortOption fromValue(String value) {
    return SortOption.values.firstWhere(
      (option) => option.value == value,
      orElse: () => SortOption.relevance,
    );
  }
}

/// Individual filter criteria
class FilterCriteria extends Equatable {
  final String type;
  final Map<String, dynamic> parameters;

  const FilterCriteria({
    required this.type,
    required this.parameters,
  });

  /// Create price range filter
  factory FilterCriteria.priceRange({
    double? minPrice,
    double? maxPrice,
  }) {
    return FilterCriteria(
      type: 'price_range',
      parameters: {
        if (minPrice != null) 'min_price': minPrice,
        if (maxPrice != null) 'max_price': maxPrice,
      },
    );
  }

  /// Create category filter
  factory FilterCriteria.category({
    String? categoryId,
    String? subcategoryId,
  }) {
    return FilterCriteria(
      type: 'category',
      parameters: {
        if (categoryId != null) 'category_id': categoryId,
        if (subcategoryId != null) 'subcategory_id': subcategoryId,
      },
    );
  }

  /// Create stock filter
  factory FilterCriteria.stock({
    required bool inStockOnly,
  }) {
    return FilterCriteria(
      type: 'stock',
      parameters: {
        'in_stock_only': inStockOnly,
      },
    );
  }

  /// Create brand filter
  factory FilterCriteria.brand({
    required List<String> brands,
  }) {
    return FilterCriteria(
      type: 'brand',
      parameters: {
        'brands': brands,
      },
    );
  }

  /// Create rating filter
  factory FilterCriteria.rating({
    required double minRating,
  }) {
    return FilterCriteria(
      type: 'rating',
      parameters: {
        'min_rating': minRating,
      },
    );
  }

  /// Convert to JSON for API calls
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'parameters': parameters,
    };
  }

  /// Create from JSON
  factory FilterCriteria.fromJson(Map<String, dynamic> json) {
    return FilterCriteria(
      type: json['type'] as String,
      parameters: Map<String, dynamic>.from(json['parameters'] as Map),
    );
  }

  /// Get human-readable label for this filter
  String get label {
    switch (type) {
      case 'price_range':
        final minPrice = parameters['min_price'] as double?;
        final maxPrice = parameters['max_price'] as double?;
        if (minPrice != null && maxPrice != null) {
          return '₹${minPrice.toInt()} - ₹${maxPrice.toInt()}';
        } else if (minPrice != null) {
          return 'Above ₹${minPrice.toInt()}';
        } else if (maxPrice != null) {
          return 'Under ₹${maxPrice.toInt()}';
        }
        return 'Price Range';
      case 'category':
        // This would need category name lookup in real implementation
        return 'Category';
      case 'stock':
        return 'In Stock Only';
      case 'brand':
        final brands = parameters['brands'] as List<String>?;
        if (brands != null && brands.isNotEmpty) {
          return brands.length == 1 ? brands.first : '${brands.length} Brands';
        }
        return 'Brand';
      case 'rating':
        final minRating = parameters['min_rating'] as double?;
        if (minRating != null) {
          return '${minRating.toInt()}+ Stars';
        }
        return 'Rating';
      default:
        return type;
    }
  }

  @override
  List<Object?> get props => [type, parameters];
}

/// Complete product filter state
class ProductFilter extends Equatable {
  final List<FilterCriteria> filters;
  final SortOption sortOption;
  final String? searchQuery;

  const ProductFilter({
    this.filters = const [],
    this.sortOption = SortOption.relevance,
    this.searchQuery,
  });

  /// Create empty filter
  const ProductFilter.empty()
      : filters = const [],
        sortOption = SortOption.relevance,
        searchQuery = null;

  /// Check if any filters are active
  bool get hasActiveFilters => filters.isNotEmpty || searchQuery != null;

  /// Get count of active filters
  int get activeFilterCount => filters.length + (searchQuery != null ? 1 : 0);

  /// Add a filter
  ProductFilter addFilter(FilterCriteria filter) {
    // Remove existing filter of the same type
    final updatedFilters = filters.where((f) => f.type != filter.type).toList();
    updatedFilters.add(filter);
    
    return copyWith(filters: updatedFilters);
  }

  /// Remove a filter by type
  ProductFilter removeFilter(String filterType) {
    final updatedFilters = filters.where((f) => f.type != filterType).toList();
    return copyWith(filters: updatedFilters);
  }

  /// Clear all filters
  ProductFilter clearAll() {
    return const ProductFilter.empty();
  }

  /// Update sort option
  ProductFilter updateSort(SortOption newSortOption) {
    return copyWith(sortOption: newSortOption);
  }

  /// Update search query
  ProductFilter updateSearch(String? query) {
    return copyWith(searchQuery: query);
  }

  /// Convert to JSON for API calls
  Map<String, dynamic> toJson() {
    return {
      'filters': filters.map((f) => f.toJson()).toList(),
      'sort': sortOption.value,
      if (searchQuery != null) 'search_query': searchQuery,
    };
  }

  /// Create from JSON
  factory ProductFilter.fromJson(Map<String, dynamic> json) {
    return ProductFilter(
      filters: (json['filters'] as List<dynamic>?)
              ?.map((f) => FilterCriteria.fromJson(f as Map<String, dynamic>))
              .toList() ??
          [],
      sortOption: SortOption.fromValue(json['sort'] as String? ?? 'created_at_desc'),
      searchQuery: json['search_query'] as String?,
    );
  }

  /// Create copy with updated fields
  ProductFilter copyWith({
    List<FilterCriteria>? filters,
    SortOption? sortOption,
    String? searchQuery,
  }) {
    return ProductFilter(
      filters: filters ?? this.filters,
      sortOption: sortOption ?? this.sortOption,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [filters, sortOption, searchQuery];
}

/// Filter suggestion from backend
class FilterSuggestion extends Equatable {
  final String type;
  final String label;
  final Map<String, dynamic> value;
  final int? count;

  const FilterSuggestion({
    required this.type,
    required this.label,
    required this.value,
    this.count,
  });

  /// Convert to FilterCriteria
  FilterCriteria toCriteria() {
    return FilterCriteria(
      type: type,
      parameters: value,
    );
  }

  /// Create from JSON
  factory FilterSuggestion.fromJson(Map<String, dynamic> json) {
    return FilterSuggestion(
      type: json['type'] as String,
      label: json['label'] as String,
      value: Map<String, dynamic>.from(json['value'] as Map),
      count: json['count'] as int?,
    );
  }

  @override
  List<Object?> get props => [type, label, value, count];
}
