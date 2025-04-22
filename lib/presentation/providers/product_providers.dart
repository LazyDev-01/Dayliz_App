import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

import '../../core/errors/failures.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/usecases/get_products_usecase.dart';
import '../../domain/usecases/get_product_by_id_usecase.dart';
import '../../domain/usecases/get_products_by_subcategory_usecase.dart';
import '../../domain/usecases/get_related_products_usecase.dart';

// Get the service locator instance
final sl = GetIt.instance;

// Product filters provider (manages pagination, category, subcategory, etc.)
final productFiltersProvider = StateProvider.autoDispose<Map<String, dynamic>>((ref) {
  return {
    'page': 1,
    'limit': 10,
    'categoryId': null,
    'subcategoryId': null,
    'searchQuery': null,
    'sortBy': 'popularity',
    'ascending': true,
    'minPrice': null,
    'maxPrice': null,
  };
});

// Product state class
class ProductState {
  final bool isLoading;
  final String? errorMessage;
  final Product? product;

  ProductState({
    this.isLoading = false,
    this.errorMessage,
    this.product,
  });

  ProductState copyWith({
    bool? isLoading,
    String? errorMessage,
    Product? product,
  }) {
    return ProductState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      product: product ?? this.product,
    );
  }
}

// ProductByIdNotifier
class ProductByIdNotifier extends StateNotifier<ProductState> {
  final String productId;
  final GetProductByIdUseCase getProductByIdUseCase;

  ProductByIdNotifier({
    required this.productId,
    required this.getProductByIdUseCase,
  }) : super(ProductState(isLoading: true)) {
    getProduct();
  }

  Future<void> getProduct() async {
    state = ProductState(isLoading: true);
    
    final result = await getProductByIdUseCase(GetProductByIdParams(id: productId));
    
    result.fold(
      (failure) => state = ProductState(
        isLoading: false,
        errorMessage: _mapFailureToMessage(failure),
      ),
      (product) => state = ProductState(
        isLoading: false,
        product: product,
      ),
    );
  }
}

// ProductByIdNotifierProvider
final productByIdNotifierProvider = StateNotifierProvider.family<ProductByIdNotifier, ProductState, String>(
  (ref, productId) => ProductByIdNotifier(
    productId: productId,
    getProductByIdUseCase: sl<GetProductByIdUseCase>(),
  ),
);

// Products state class
class ProductsState {
  final bool isLoading;
  final String? errorMessage;
  final List<Product> products;
  final Map<String, dynamic> filters;

  ProductsState({
    this.isLoading = false,
    this.errorMessage,
    this.products = const [],
    this.filters = const {},
  });

  ProductsState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<Product>? products,
    Map<String, dynamic>? filters,
  }) {
    return ProductsState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      products: products ?? this.products,
      filters: filters ?? this.filters,
    );
  }
}

// ProductsNotifier
class ProductsNotifier extends StateNotifier<ProductsState> {
  final GetProductsUseCase getProductsUseCase;

  ProductsNotifier({
    required this.getProductsUseCase,
  }) : super(ProductsState(isLoading: true)) {
    getProducts();
  }

  Future<void> getProducts() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    final params = GetProductsParams(
      categoryId: state.filters['categoryId'],
      subcategoryId: state.filters['subcategoryId'],
      searchQuery: state.filters['searchQuery'],
      sortBy: state.filters['sortBy'],
      ascending: state.filters['ascending'],
      minPrice: state.filters['minPrice'],
      maxPrice: state.filters['maxPrice'],
    );
    
    final result = await getProductsUseCase(params);
    
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: _mapFailureToMessage(failure),
      ),
      (products) => state = state.copyWith(
        isLoading: false,
        products: products,
      ),
    );
  }
  
  void updateFilters(Map<String, dynamic> newFilters) {
    state = state.copyWith(filters: {...state.filters, ...newFilters});
    getProducts();
  }
}

// ProductsNotifierProvider
final productsNotifierProvider = StateNotifierProvider<ProductsNotifier, ProductsState>(
  (ref) => ProductsNotifier(
    getProductsUseCase: sl<GetProductsUseCase>(),
  ),
);

// Related products state class
class RelatedProductsState {
  final bool isLoading;
  final String? errorMessage;
  final List<Product> products;

  RelatedProductsState({
    this.isLoading = false,
    this.errorMessage,
    this.products = const [],
  });

  RelatedProductsState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<Product>? products,
  }) {
    return RelatedProductsState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      products: products ?? this.products,
    );
  }
}

// RelatedProductsNotifier
class RelatedProductsNotifier extends StateNotifier<RelatedProductsState> {
  final String productId;
  final GetRelatedProductsUseCase getRelatedProductsUseCase;

  RelatedProductsNotifier({
    required this.productId,
    required this.getRelatedProductsUseCase,
  }) : super(RelatedProductsState(isLoading: true)) {
    getRelatedProducts();
  }

  Future<void> getRelatedProducts() async {
    state = RelatedProductsState(isLoading: true);
    
    final result = await getRelatedProductsUseCase(GetRelatedProductsParams(productId: productId));
    
    result.fold(
      (failure) => state = RelatedProductsState(
        isLoading: false,
        errorMessage: _mapFailureToMessage(failure),
      ),
      (products) => state = RelatedProductsState(
        isLoading: false,
        products: products,
      ),
    );
  }
}

// RelatedProductsNotifierProvider
final relatedProductsNotifierProvider = StateNotifierProvider.family<RelatedProductsNotifier, RelatedProductsState, String>(
  (ref, productId) => RelatedProductsNotifier(
    productId: productId,
    getRelatedProductsUseCase: sl<GetRelatedProductsUseCase>(),
  ),
);

// Providers for specific product lists

// Featured products state class
class FeaturedProductsState {
  final List<Product> products;
  final bool isLoading;
  final String? errorMessage;

  const FeaturedProductsState({
    required this.products,
    required this.isLoading,
    this.errorMessage,
  });

  FeaturedProductsState copyWith({
    List<Product>? products,
    bool? isLoading,
    String? errorMessage,
  }) {
    return FeaturedProductsState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

// Featured products notifier
class FeaturedProductsNotifier extends StateNotifier<FeaturedProductsState> {
  final ProductRepository repository;
  
  FeaturedProductsNotifier(this.repository) 
      : super(const FeaturedProductsState(products: [], isLoading: true));
  
  Future<void> getFeaturedProducts({int? limit}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    final result = await repository.getFeaturedProducts(limit: limit);
    
    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: _mapFailureToMessage(failure),
        );
      },
      (products) {
        state = state.copyWith(
          products: products,
          isLoading: false,
        );
      },
    );
  }
}

// Featured products provider
final featuredProductsProvider = StateNotifierProvider.autoDispose<FeaturedProductsNotifier, FeaturedProductsState>((ref) {
  final repository = sl<ProductRepository>();
  final notifier = FeaturedProductsNotifier(repository);
  
  // Schedule the operation after initialization
  Future.microtask(() => notifier.getFeaturedProducts(limit: 5));
  
  return notifier;
});

// Sale products state class
class SaleProductsState {
  final List<Product> products;
  final bool isLoading;
  final String? errorMessage;

  const SaleProductsState({
    required this.products,
    required this.isLoading,
    this.errorMessage,
  });

  SaleProductsState copyWith({
    List<Product>? products,
    bool? isLoading,
    String? errorMessage,
  }) {
    return SaleProductsState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

// Sale products notifier
class SaleProductsNotifier extends StateNotifier<SaleProductsState> {
  final ProductRepository repository;
  
  SaleProductsNotifier(this.repository) 
      : super(const SaleProductsState(products: [], isLoading: true));
  
  Future<void> getProductsOnSale({int? limit}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    final result = await repository.getProductsOnSale(limit: limit);
    
    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: _mapFailureToMessage(failure),
        );
      },
      (products) {
        state = state.copyWith(
          products: products,
          isLoading: false,
        );
      },
    );
  }
}

// Sale products provider
final saleProductsProvider = StateNotifierProvider.autoDispose<SaleProductsNotifier, SaleProductsState>((ref) {
  final repository = sl<ProductRepository>();
  final notifier = SaleProductsNotifier(repository);
  
  // Schedule the operation after initialization
  Future.microtask(() => notifier.getProductsOnSale(limit: 5));
  
  return notifier;
});

// Subcategory products notifier
class SubcategoryProductsNotifier extends StateNotifier<ProductsState> {
  final GetProductsBySubcategoryUseCase getProductsBySubcategoryUseCase;
  
  SubcategoryProductsNotifier(this.getProductsBySubcategoryUseCase) 
      : super(ProductsState(products: const [], isLoading: true));
  
  Future<void> getProductsBySubcategory({
    required String subcategoryId,
    int? page,
    int? limit,
    String? sortBy,
    bool? ascending,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    final result = await getProductsBySubcategoryUseCase(
      GetProductsBySubcategoryParams(
        subcategoryId: subcategoryId,
        page: page ?? 1,
        limit: limit ?? 10,
        sortBy: sortBy ?? 'createdAt',
        ascending: ascending ?? false,
      ),
    );
    
    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: _mapFailureToMessage(failure),
        );
      },
      (products) {
        state = state.copyWith(
          products: products,
          isLoading: false,
        );
      },
    );
  }
}

// Subcategory products provider
final productsBySubcategoryProvider = StateNotifierProvider.family.autoDispose<SubcategoryProductsNotifier, ProductsState, Map<String, dynamic>>(
  (ref, params) {
    final getProductsBySubcategoryUseCase = sl<GetProductsBySubcategoryUseCase>();
    final notifier = SubcategoryProductsNotifier(getProductsBySubcategoryUseCase);
    
    final subcategoryId = params['subcategoryId'] as String;
    final page = params['page'] as int?;
    final limit = params['limit'] as int?;
    final sortBy = params['sortBy'] as String?;
    final ascending = params['ascending'] as bool?;
    
    // Schedule the operation after initialization
    Future.microtask(() => notifier.getProductsBySubcategory(
      subcategoryId: subcategoryId,
      page: page,
      limit: limit,
      sortBy: sortBy,
      ascending: ascending,
    ));
    
    return notifier;
  },
);

// Helper function to map failures to user-friendly messages
String _mapFailureToMessage(Failure failure) {
  switch (failure.runtimeType) {
    case ServerFailure:
      return 'Server error occurred. Please try again later.';
    case NetworkFailure:
      return 'Network error. Please check your internet connection.';
    case CacheFailure:
      return 'Cache error. Please restart the app.';
    default:
      return 'An unexpected error occurred.';
  }
} 