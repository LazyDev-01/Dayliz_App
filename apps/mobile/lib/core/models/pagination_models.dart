import 'package:equatable/equatable.dart';

/// Pagination request parameters
class PaginationParams extends Equatable {
  final int page;
  final int limit;
  final int offset;

  const PaginationParams({
    required this.page,
    required this.limit,
  }) : offset = (page - 1) * limit;

  /// Default pagination for product listings
  const PaginationParams.defaultProducts()
      : page = 1,
        limit = 50,
        offset = 0;

  /// Pagination for search results
  const PaginationParams.search()
      : page = 1,
        limit = 30,
        offset = 0;

  /// Pagination for featured products
  const PaginationParams.featured()
      : page = 1,
        limit = 20,
        offset = 0;

  /// No pagination - get all items
  const PaginationParams.all()
      : page = 1,
        limit = 1000,
        offset = 0;

  /// Create next page
  PaginationParams nextPage() {
    return PaginationParams(
      page: page + 1,
      limit: limit,
    );
  }

  /// Create previous page
  PaginationParams previousPage() {
    return PaginationParams(
      page: page > 1 ? page - 1 : 1,
      limit: limit,
    );
  }

  /// Create with different limit
  PaginationParams withLimit(int newLimit) {
    return PaginationParams(
      page: page,
      limit: newLimit,
    );
  }

  @override
  List<Object?> get props => [page, limit, offset];

  @override
  String toString() => 'PaginationParams(page: $page, limit: $limit, offset: $offset)';
}

/// Pagination response metadata
class PaginationMeta extends Equatable {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;
  final bool hasNextPage;
  final bool hasPreviousPage;

  const PaginationMeta({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory PaginationMeta.fromParams({
    required PaginationParams params,
    required int totalItems,
  }) {
    final totalPages = (totalItems / params.limit).ceil();
    return PaginationMeta(
      currentPage: params.page,
      totalPages: totalPages,
      totalItems: totalItems,
      itemsPerPage: params.limit,
      hasNextPage: params.page < totalPages,
      hasPreviousPage: params.page > 1,
    );
  }

  @override
  List<Object?> get props => [
        currentPage,
        totalPages,
        totalItems,
        itemsPerPage,
        hasNextPage,
        hasPreviousPage,
      ];

  @override
  String toString() => 'PaginationMeta(page: $currentPage/$totalPages, items: $totalItems)';
}

/// Paginated response wrapper
class PaginatedResponse<T> extends Equatable {
  final List<T> data;
  final PaginationMeta meta;

  const PaginatedResponse({
    required this.data,
    required this.meta,
  });

  /// Create empty response
  const PaginatedResponse.empty()
      : data = const [],
        meta = const PaginationMeta(
          currentPage: 1,
          totalPages: 0,
          totalItems: 0,
          itemsPerPage: 0,
          hasNextPage: false,
          hasPreviousPage: false,
        );

  /// Check if response is empty
  bool get isEmpty => data.isEmpty;

  /// Check if response has data
  bool get isNotEmpty => data.isNotEmpty;

  /// Get item count
  int get length => data.length;

  @override
  List<Object?> get props => [data, meta];

  @override
  String toString() => 'PaginatedResponse(${data.length} items, $meta)';
}

/// Pagination configuration for different use cases
class PaginationConfig {
  static const int defaultProductLimit = 50;
  static const int searchLimit = 30;
  static const int featuredLimit = 20;
  static const int relatedLimit = 8;
  static const int maxLimit = 100;
  static const int minLimit = 10;

  /// Get appropriate limit for use case
  static int getLimitForUseCase(ProductListingType type) {
    switch (type) {
      case ProductListingType.category:
      case ProductListingType.subcategory:
        return defaultProductLimit;
      case ProductListingType.search:
        return searchLimit;
      case ProductListingType.featured:
        return featuredLimit;
      case ProductListingType.related:
        return relatedLimit;
      case ProductListingType.sale:
        return defaultProductLimit;
      case ProductListingType.all:
        return maxLimit;
    }
  }
}

/// Product listing types for pagination configuration
enum ProductListingType {
  category,
  subcategory,
  search,
  featured,
  related,
  sale,
  all,
}
