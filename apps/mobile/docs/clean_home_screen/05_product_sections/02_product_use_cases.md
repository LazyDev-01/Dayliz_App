# Clean Home Screen: Product Use Cases

## 1. Use Case Base Class

First, let's define a base use case class that all our product use cases will extend:

```dart
// lib/domain/usecases/usecase.dart
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

// For use cases that don't require parameters
class NoParams extends Equatable {
  @override
  List<Object> get props => [];
}
```

## 2. Get Products Use Case

This use case retrieves a list of products based on filters, sorting options, and pagination parameters.

```dart
// lib/domain/usecases/get_products_usecase.dart
class GetProductsParams extends Equatable {
  final ProductFilter? filter;
  final ProductSortOption? sortOption;
  final int? limit;
  final int? offset;

  const GetProductsParams({
    this.filter,
    this.sortOption,
    this.limit,
    this.offset,
  });

  @override
  List<Object?> get props => [filter, sortOption, limit, offset];
}

class GetProductsUseCase implements UseCase<List<Product>, GetProductsParams> {
  final ProductRepository repository;

  GetProductsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Product>>> call(GetProductsParams params) async {
    return await repository.getProducts(
      filter: params.filter,
      sortOption: params.sortOption,
      limit: params.limit,
      offset: params.offset,
    );
  }
}
```

## 3. Get Featured Products Use Case

This use case retrieves a list of featured products, which are typically highlighted on the home screen.

```dart
// lib/domain/usecases/get_featured_products_usecase.dart
class GetFeaturedProductsParams extends Equatable {
  final int? limit;

  const GetFeaturedProductsParams({this.limit});

  @override
  List<Object?> get props => [limit];
}

class GetFeaturedProductsUseCase implements UseCase<List<Product>, GetFeaturedProductsParams> {
  final ProductRepository repository;

  GetFeaturedProductsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Product>>> call(GetFeaturedProductsParams params) async {
    return await repository.getFeaturedProducts(limit: params.limit);
  }
}
```

## 4. Get Sale Products Use Case

This use case retrieves a list of products that are on sale or have discounts.

```dart
// lib/domain/usecases/get_sale_products_usecase.dart
class GetSaleProductsParams extends Equatable {
  final int? limit;

  const GetSaleProductsParams({this.limit});

  @override
  List<Object?> get props => [limit];
}

class GetSaleProductsUseCase implements UseCase<List<Product>, GetSaleProductsParams> {
  final ProductRepository repository;

  GetSaleProductsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Product>>> call(GetSaleProductsParams params) async {
    return await repository.getSaleProducts(limit: params.limit);
  }
}
```

## 5. Get New Arrivals Use Case

This use case retrieves a list of recently added products.

```dart
// lib/domain/usecases/get_new_arrivals_usecase.dart
class GetNewArrivalsParams extends Equatable {
  final int? limit;

  const GetNewArrivalsParams({this.limit});

  @override
  List<Object?> get props => [limit];
}

class GetNewArrivalsUseCase implements UseCase<List<Product>, GetNewArrivalsParams> {
  final ProductRepository repository;

  GetNewArrivalsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Product>>> call(GetNewArrivalsParams params) async {
    return await repository.getNewArrivals(limit: params.limit);
  }
}
```

## 6. Get Product By ID Use Case

This use case retrieves a single product by its ID.

```dart
// lib/domain/usecases/get_product_by_id_usecase.dart
class GetProductByIdUseCase implements UseCase<Product, String> {
  final ProductRepository repository;

  GetProductByIdUseCase(this.repository);

  @override
  Future<Either<Failure, Product>> call(String productId) async {
    return await repository.getProductById(productId);
  }
}
```

## 7. Get Related Products Use Case

This use case retrieves a list of products related to a specific product.

```dart
// lib/domain/usecases/get_related_products_usecase.dart
class GetRelatedProductsParams extends Equatable {
  final String productId;
  final int? limit;

  const GetRelatedProductsParams({
    required this.productId,
    this.limit,
  });

  @override
  List<Object?> get props => [productId, limit];
}

class GetRelatedProductsUseCase implements UseCase<List<Product>, GetRelatedProductsParams> {
  final ProductRepository repository;

  GetRelatedProductsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Product>>> call(GetRelatedProductsParams params) async {
    return await repository.getRelatedProducts(
      params.productId,
      limit: params.limit,
    );
  }
}
```

## 8. Use Case Providers

Let's define Riverpod providers for our use cases:

```dart
// lib/presentation/providers/product_use_case_providers.dart
final getProductsUseCaseProvider = Provider<GetProductsUseCase>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  return GetProductsUseCase(repository);
});

final getFeaturedProductsUseCaseProvider = Provider<GetFeaturedProductsUseCase>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  return GetFeaturedProductsUseCase(repository);
});

final getSaleProductsUseCaseProvider = Provider<GetSaleProductsUseCase>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  return GetSaleProductsUseCase(repository);
});

final getNewArrivalsUseCaseProvider = Provider<GetNewArrivalsUseCase>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  return GetNewArrivalsUseCase(repository);
});

final getProductByIdUseCaseProvider = Provider<GetProductByIdUseCase>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  return GetProductByIdUseCase(repository);
});

final getRelatedProductsUseCaseProvider = Provider<GetRelatedProductsUseCase>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  return GetRelatedProductsUseCase(repository);
});
```

## 9. Testing Use Cases

Here's an example of how to test one of our use cases:

```dart
// test/domain/usecases/get_featured_products_usecase_test.dart
void main() {
  late GetFeaturedProductsUseCase useCase;
  late MockProductRepository mockRepository;

  setUp(() {
    mockRepository = MockProductRepository();
    useCase = GetFeaturedProductsUseCase(mockRepository);
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

  test('should get featured products from the repository', () async {
    // arrange
    when(mockRepository.getFeaturedProducts(limit: tLimit))
        .thenAnswer((_) async => Right(tProducts));

    // act
    final result = await useCase(GetFeaturedProductsParams(limit: tLimit));

    // assert
    expect(result, Right(tProducts));
    verify(mockRepository.getFeaturedProducts(limit: tLimit));
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return server failure when repository fails', () async {
    // arrange
    when(mockRepository.getFeaturedProducts(limit: tLimit))
        .thenAnswer((_) async => Left(ServerFailure()));

    // act
    final result = await useCase(GetFeaturedProductsParams(limit: tLimit));

    // assert
    expect(result, Left(ServerFailure()));
    verify(mockRepository.getFeaturedProducts(limit: tLimit));
    verifyNoMoreInteractions(mockRepository);
  });
}
```

## 10. Next Steps

In the next sections, we will cover:

1. **Product State Management**: State management for product data using Riverpod
2. **Product Card Widget**: Reusable product card component for displaying products
3. **Featured Products Section**: Implementation of the featured products section
4. **Sale Products Section**: Implementation of the sale/discount products section
5. **New Arrivals Section**: Implementation of the new arrivals section
