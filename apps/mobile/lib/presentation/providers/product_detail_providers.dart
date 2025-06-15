import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dartz/dartz.dart';

import '../../domain/entities/product.dart';
import '../../core/errors/failures.dart';
import '../../di/dependency_injection.dart' show sl;
import '../../domain/usecases/get_product_by_id_usecase.dart';
import '../../domain/usecases/get_related_products_usecase.dart';

/// Product state for individual product details
class ProductState {
  final Product? product;
  final bool isLoading;
  final String? errorMessage;

  const ProductState({
    this.product,
    this.isLoading = false,
    this.errorMessage,
  });

  ProductState copyWith({
    Product? product,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ProductState(
      product: product ?? this.product,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Related products state
class RelatedProductsState {
  final List<Product> products;
  final bool isLoading;
  final String? errorMessage;

  const RelatedProductsState({
    this.products = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  RelatedProductsState copyWith({
    List<Product>? products,
    bool? isLoading,
    String? errorMessage,
  }) {
    return RelatedProductsState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Product detail notifier
class ProductDetailNotifier extends StateNotifier<ProductState> {
  final GetProductByIdUseCase _getProductByIdUseCase;

  ProductDetailNotifier(this._getProductByIdUseCase) : super(const ProductState());

  Future<void> getProduct(String productId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _getProductByIdUseCase.call(GetProductByIdParams(id: productId));

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      ),
      (product) => state = state.copyWith(
        isLoading: false,
        product: product,
        errorMessage: null,
      ),
    );
  }
}

/// Related products notifier
class RelatedProductsNotifier extends StateNotifier<RelatedProductsState> {
  final GetRelatedProductsUseCase _getRelatedProductsUseCase;

  RelatedProductsNotifier(this._getRelatedProductsUseCase)
      : super(const RelatedProductsState());

  Future<void> getRelatedProducts(String productId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _getRelatedProductsUseCase.call(
      GetRelatedProductsParams(
        productId: productId,
        limit: 5, // Limit related products
      ),
    );

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      ),
      (products) => state = state.copyWith(
        isLoading: false,
        products: products,
        errorMessage: null,
      ),
    );
  }
}

/// Product by ID provider family
final productByIdNotifierProvider = StateNotifierProvider.family<
    ProductDetailNotifier, 
    ProductState, 
    String
>((ref, productId) {
  final getProductByIdUseCase = sl<GetProductByIdUseCase>();
  final notifier = ProductDetailNotifier(getProductByIdUseCase);
  
  // Auto-load product when provider is created
  Future.microtask(() => notifier.getProduct(productId));
  
  return notifier;
});

/// Related products provider family
final relatedProductsNotifierProvider = StateNotifierProvider.family<
    RelatedProductsNotifier, 
    RelatedProductsState, 
    String
>((ref, productId) {
  final getRelatedProductsUseCase = sl<GetRelatedProductsUseCase>();
  final notifier = RelatedProductsNotifier(getRelatedProductsUseCase);

  // Auto-load related products when the main product is loaded
  ref.listen(productByIdNotifierProvider(productId), (previous, next) {
    if (next.product != null) {
      notifier.getRelatedProducts(productId);
    }
  });
  
  return notifier;
});

/// Simple product provider for quick access
final productProvider = Provider.family<Product?, String>((ref, productId) {
  final productState = ref.watch(productByIdNotifierProvider(productId));
  return productState.product;
});

/// Product loading state provider
final productLoadingProvider = Provider.family<bool, String>((ref, productId) {
  final productState = ref.watch(productByIdNotifierProvider(productId));
  return productState.isLoading;
});

/// Product error provider
final productErrorProvider = Provider.family<String?, String>((ref, productId) {
  final productState = ref.watch(productByIdNotifierProvider(productId));
  return productState.errorMessage;
});
