# Clean Home Screen: Product State Management

## 1. Product State Classes

Let's define the state classes for managing product data in our application.

### 1.1 Base Product State

```dart
// lib/presentation/providers/product_state.dart
class ProductState {
  final List<Product> products;
  final bool isLoading;
  final String? errorMessage;

  const ProductState({
    this.products = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  ProductState copyWith({
    List<Product>? products,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ProductState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}
```

### 1.2 Featured Products State

```dart
// lib/presentation/providers/featured_products_state.dart
class FeaturedProductsState extends ProductState {
  const FeaturedProductsState({
    super.products = const [],
    super.isLoading = false,
    super.errorMessage,
  });

  @override
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
```

### 1.3 Sale Products State

```dart
// lib/presentation/providers/sale_products_state.dart
class SaleProductsState extends ProductState {
  const SaleProductsState({
    super.products = const [],
    super.isLoading = false,
    super.errorMessage,
  });

  @override
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
```

### 1.4 New Arrivals State

```dart
// lib/presentation/providers/new_arrivals_state.dart
class NewArrivalsState extends ProductState {
  const NewArrivalsState({
    super.products = const [],
    super.isLoading = false,
    super.errorMessage,
  });

  @override
  NewArrivalsState copyWith({
    List<Product>? products,
    bool? isLoading,
    String? errorMessage,
  }) {
    return NewArrivalsState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}
```

## 2. Product Notifiers

Now, let's implement the notifiers that will manage the state for each type of product section.

### 2.1 Featured Products Notifier

```dart
// lib/presentation/providers/featured_products_notifier.dart
class FeaturedProductsNotifier extends StateNotifier<FeaturedProductsState> {
  final GetFeaturedProductsUseCase getFeaturedProductsUseCase;

  FeaturedProductsNotifier({
    required this.getFeaturedProductsUseCase,
  }) : super(const FeaturedProductsState());

  Future<void> loadFeaturedProducts({int? limit = 10}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await getFeaturedProductsUseCase(
      GetFeaturedProductsParams(limit: limit),
    );

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

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return 'Server error occurred';
      case CacheFailure:
        return 'Cache error occurred';
      default:
        return 'Unexpected error';
    }
  }
}
```

### 2.2 Sale Products Notifier

```dart
// lib/presentation/providers/sale_products_notifier.dart
class SaleProductsNotifier extends StateNotifier<SaleProductsState> {
  final GetSaleProductsUseCase getSaleProductsUseCase;

  SaleProductsNotifier({
    required this.getSaleProductsUseCase,
  }) : super(const SaleProductsState());

  Future<void> loadSaleProducts({int? limit = 10}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await getSaleProductsUseCase(
      GetSaleProductsParams(limit: limit),
    );

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

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return 'Server error occurred';
      case CacheFailure:
        return 'Cache error occurred';
      default:
        return 'Unexpected error';
    }
  }
}
```

### 2.3 New Arrivals Notifier

```dart
// lib/presentation/providers/new_arrivals_notifier.dart
class NewArrivalsNotifier extends StateNotifier<NewArrivalsState> {
  final GetNewArrivalsUseCase getNewArrivalsUseCase;

  NewArrivalsNotifier({
    required this.getNewArrivalsUseCase,
  }) : super(const NewArrivalsState());

  Future<void> loadNewArrivals({int? limit = 10}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await getNewArrivalsUseCase(
      GetNewArrivalsParams(limit: limit),
    );

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

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return 'Server error occurred';
      case CacheFailure:
        return 'Cache error occurred';
      default:
        return 'Unexpected error';
    }
  }
}
```

## 3. Product Providers

Now, let's define the Riverpod providers for our product notifiers and derived states.

```dart
// lib/presentation/providers/product_providers.dart

// Featured Products Providers
final featuredProductsNotifierProvider =
    StateNotifierProvider<FeaturedProductsNotifier, FeaturedProductsState>((ref) {
  return FeaturedProductsNotifier(
    getFeaturedProductsUseCase: ref.watch(getFeaturedProductsUseCaseProvider),
  );
});

final featuredProductsProvider = Provider<List<Product>>((ref) {
  return ref.watch(featuredProductsNotifierProvider).products;
});

final featuredProductsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(featuredProductsNotifierProvider).isLoading;
});

final featuredProductsErrorProvider = Provider<String?>((ref) {
  return ref.watch(featuredProductsNotifierProvider).errorMessage;
});

// Sale Products Providers
final saleProductsNotifierProvider =
    StateNotifierProvider<SaleProductsNotifier, SaleProductsState>((ref) {
  return SaleProductsNotifier(
    getSaleProductsUseCase: ref.watch(getSaleProductsUseCaseProvider),
  );
});

final saleProductsProvider = Provider<List<Product>>((ref) {
  return ref.watch(saleProductsNotifierProvider).products;
});

final saleProductsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(saleProductsNotifierProvider).isLoading;
});

final saleProductsErrorProvider = Provider<String?>((ref) {
  return ref.watch(saleProductsNotifierProvider).errorMessage;
});

// New Arrivals Providers
final newArrivalsNotifierProvider =
    StateNotifierProvider<NewArrivalsNotifier, NewArrivalsState>((ref) {
  return NewArrivalsNotifier(
    getNewArrivalsUseCase: ref.watch(getNewArrivalsUseCaseProvider),
  );
});

final newArrivalsProvider = Provider<List<Product>>((ref) {
  return ref.watch(newArrivalsNotifierProvider).products;
});

final newArrivalsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(newArrivalsNotifierProvider).isLoading;
});

final newArrivalsErrorProvider = Provider<String?>((ref) {
  return ref.watch(newArrivalsNotifierProvider).errorMessage;
});
```

## 4. Product Detail State Management

For completeness, let's also define state management for product details:

### 4.1 Product Detail State

```dart
// lib/presentation/providers/product_detail_state.dart
class ProductDetailState {
  final Product? product;
  final bool isLoading;
  final String? errorMessage;
  final List<Product> relatedProducts;
  final bool isLoadingRelated;
  final String? relatedErrorMessage;

  const ProductDetailState({
    this.product,
    this.isLoading = false,
    this.errorMessage,
    this.relatedProducts = const [],
    this.isLoadingRelated = false,
    this.relatedErrorMessage,
  });

  ProductDetailState copyWith({
    Product? product,
    bool? isLoading,
    String? errorMessage,
    List<Product>? relatedProducts,
    bool? isLoadingRelated,
    String? relatedErrorMessage,
  }) {
    return ProductDetailState(
      product: product ?? this.product,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      relatedProducts: relatedProducts ?? this.relatedProducts,
      isLoadingRelated: isLoadingRelated ?? this.isLoadingRelated,
      relatedErrorMessage: relatedErrorMessage,
    );
  }
}
```

### 4.2 Product Detail Notifier

```dart
// lib/presentation/providers/product_detail_notifier.dart
class ProductDetailNotifier extends StateNotifier<ProductDetailState> {
  final GetProductByIdUseCase getProductByIdUseCase;
  final GetRelatedProductsUseCase getRelatedProductsUseCase;

  ProductDetailNotifier({
    required this.getProductByIdUseCase,
    required this.getRelatedProductsUseCase,
  }) : super(const ProductDetailState());

  Future<void> loadProduct(String productId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await getProductByIdUseCase(productId);

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: _mapFailureToMessage(failure),
      ),
      (product) => state = state.copyWith(
        isLoading: false,
        product: product,
      ),
    );

    // Load related products after loading the main product
    if (result.isRight()) {
      loadRelatedProducts(productId);
    }
  }

  Future<void> loadRelatedProducts(String productId, {int? limit = 10}) async {
    state = state.copyWith(isLoadingRelated: true, relatedErrorMessage: null);

    final result = await getRelatedProductsUseCase(
      GetRelatedProductsParams(productId: productId, limit: limit),
    );

    result.fold(
      (failure) => state = state.copyWith(
        isLoadingRelated: false,
        relatedErrorMessage: _mapFailureToMessage(failure),
      ),
      (products) => state = state.copyWith(
        isLoadingRelated: false,
        relatedProducts: products,
      ),
    );
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return 'Server error occurred';
      case CacheFailure:
        return 'Cache error occurred';
      default:
        return 'Unexpected error';
    }
  }
}
```

### 4.3 Product Detail Providers

```dart
// lib/presentation/providers/product_detail_providers.dart
final productDetailNotifierProvider = StateNotifierProvider.family<
    ProductDetailNotifier, ProductDetailState, String>((ref, productId) {
  return ProductDetailNotifier(
    getProductByIdUseCase: ref.watch(getProductByIdUseCaseProvider),
    getRelatedProductsUseCase: ref.watch(getRelatedProductsUseCaseProvider),
  )..loadProduct(productId);
});

final productProvider = Provider.family<Product?, String>((ref, productId) {
  return ref.watch(productDetailNotifierProvider(productId)).product;
});

final productLoadingProvider = Provider.family<bool, String>((ref, productId) {
  return ref.watch(productDetailNotifierProvider(productId)).isLoading;
});

final productErrorProvider = Provider.family<String?, String>((ref, productId) {
  return ref.watch(productDetailNotifierProvider(productId)).errorMessage;
});

final relatedProductsProvider = Provider.family<List<Product>, String>((ref, productId) {
  return ref.watch(productDetailNotifierProvider(productId)).relatedProducts;
});

final relatedProductsLoadingProvider = Provider.family<bool, String>((ref, productId) {
  return ref.watch(productDetailNotifierProvider(productId)).isLoadingRelated;
});

final relatedProductsErrorProvider = Provider.family<String?, String>((ref, productId) {
  return ref.watch(productDetailNotifierProvider(productId)).relatedErrorMessage;
});
```

## 5. Using Product Providers in the Home Screen

Here's how we can use these providers in the home screen to load product data:

```dart
// lib/presentation/screens/home/clean_home_screen.dart (partial)
@override
void initState() {
  super.initState();
  _loadInitialData();
}

void _loadInitialData() {
  // Load all required data for the home screen
  ref.read(featuredProductsNotifierProvider.notifier).loadFeaturedProducts();
  ref.read(saleProductsNotifierProvider.notifier).loadSaleProducts();
  ref.read(newArrivalsNotifierProvider.notifier).loadNewArrivals();
}

void _onRefresh() async {
  // Refresh all data
  ref.refresh(featuredProductsNotifierProvider);
  ref.refresh(saleProductsNotifierProvider);
  ref.refresh(newArrivalsNotifierProvider);
  
  // Complete the refresh
  _refreshController.refreshCompleted();
}
```

## 6. Testing Product State Management

Here's an example of how to test one of our notifiers:

```dart
// test/presentation/providers/featured_products_notifier_test.dart
void main() {
  late FeaturedProductsNotifier notifier;
  late MockGetFeaturedProductsUseCase mockUseCase;

  setUp(() {
    mockUseCase = MockGetFeaturedProductsUseCase();
    notifier = FeaturedProductsNotifier(getFeaturedProductsUseCase: mockUseCase);
  });

  final tLimit = 10;
  final tProducts = [
    Product(
      id: '1',
      name: 'Test Product 1',
      price: 19.99,
      isFeatured: true,
    ),
    Product(
      id: '2',
      name: 'Test Product 2',
      price: 29.99,
      isFeatured: true,
    ),
  ];

  test('initial state should be empty', () {
    // assert
    expect(notifier.state.products, []);
    expect(notifier.state.isLoading, false);
    expect(notifier.state.errorMessage, null);
  });

  test('should update state to loading when loading featured products', () async {
    // arrange
    when(mockUseCase(any)).thenAnswer((_) async => Right(tProducts));

    // act
    await notifier.loadFeaturedProducts(limit: tLimit);

    // assert
    verify(mockUseCase(GetFeaturedProductsParams(limit: tLimit)));
  });

  test('should update state with products when loading succeeds', () async {
    // arrange
    when(mockUseCase(any)).thenAnswer((_) async => Right(tProducts));

    // act
    await notifier.loadFeaturedProducts(limit: tLimit);

    // assert
    expect(notifier.state.products, tProducts);
    expect(notifier.state.isLoading, false);
    expect(notifier.state.errorMessage, null);
  });

  test('should update state with error when loading fails', () async {
    // arrange
    when(mockUseCase(any)).thenAnswer((_) async => Left(ServerFailure()));

    // act
    await notifier.loadFeaturedProducts(limit: tLimit);

    // assert
    expect(notifier.state.products, []);
    expect(notifier.state.isLoading, false);
    expect(notifier.state.errorMessage, 'Server error occurred');
  });
}
```

## 7. Next Steps

In the next sections, we will cover:

1. **Product Card Widget**: Reusable product card component for displaying products
2. **Featured Products Section**: Implementation of the featured products section
3. **Sale Products Section**: Implementation of the sale/discount products section
4. **New Arrivals Section**: Implementation of the new arrivals section
