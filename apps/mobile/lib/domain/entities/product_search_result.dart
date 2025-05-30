import 'package:equatable/equatable.dart';
import 'product.dart';

/// Represents the result of a product search operation
class ProductSearchResult extends Equatable {
  /// The list of products matching the search criteria
  final List<Product> products;
  
  /// The total number of products matching the search criteria
  /// (may be more than the number of products returned if pagination is used)
  final int totalCount;
  
  /// The current page number (1-based)
  final int page;
  
  /// The number of products per page
  final int pageSize;

  /// Creates a new ProductSearchResult
  const ProductSearchResult({
    required this.products,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  /// Returns the total number of pages based on totalCount and pageSize
  int get totalPages => (totalCount / pageSize).ceil();

  /// Returns whether there is a next page
  bool get hasNextPage => page < totalPages;

  /// Returns whether there is a previous page
  bool get hasPreviousPage => page > 1;

  @override
  List<Object?> get props => [products, totalCount, page, pageSize];
}
