import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:dayliz_app/core/errors/failures.dart';
import 'package:dayliz_app/core/network/network_info.dart';
import 'package:dayliz_app/data/datasources/cart_local_data_source.dart';
import 'package:dayliz_app/data/datasources/cart_remote_data_source.dart';
import 'package:dayliz_app/data/repositories/cart_repository_impl.dart';
import 'package:dayliz_app/data/models/cart_item_model.dart';
import 'package:dayliz_app/data/models/product_model.dart';

// Generate mocks
@GenerateMocks([
  CartRemoteDataSource,
  CartLocalDataSource,
  NetworkInfo,
])
import 'cart_repository_impl_test.mocks.dart';

void main() {
  late CartRepositoryImpl repository;
  late MockCartRemoteDataSource mockRemoteDataSource;
  late MockCartLocalDataSource mockLocalDataSource;
  late MockNetworkInfo mockNetworkInfo;

  setUp(() {
    mockRemoteDataSource = MockCartRemoteDataSource();
    mockLocalDataSource = MockCartLocalDataSource();
    mockNetworkInfo = MockNetworkInfo();
    repository = CartRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
      networkInfo: mockNetworkInfo,
    );
  });

  const tProduct = ProductModel(
    id: 'test-product-id',
    name: 'Test Product',
    description: 'Test Description',
    price: 99.99,
    discountPercentage: 10.0,
    rating: 4.5,
    reviewCount: 100,
    mainImageUrl: 'https://example.com/image.jpg',
    inStock: true,
    stockQuantity: 50,
    categoryId: 'test-category-id',
    brand: 'Test Brand',
  );

  final tCartItemModel = CartItemModel(
    id: 'test-cart-item-id',
    product: tProduct,
    quantity: 2,
    addedAt: DateTime.now(),
  );

  final tCartItemModels = [tCartItemModel];
  const tQuantity = 2;
  const tCartItemId = 'test-cart-item-id';
  const tProductId = 'test-product-id';

  group('getCartItems', () {
    test('should return local cart items directly (local-first strategy)', () async {
      // arrange
      when(mockLocalDataSource.getCachedCartItems()).thenAnswer((_) async => tCartItemModels);

      // act
      final result = await repository.getCartItems();

      // assert
      verify(mockLocalDataSource.getCachedCartItems());
      verifyZeroInteractions(mockRemoteDataSource);
      verifyZeroInteractions(mockNetworkInfo);
      expect(result, equals(Right(tCartItemModels)));
    });

    test('should return CacheFailure when local data source fails', () async {
      // arrange
      when(mockLocalDataSource.getCachedCartItems())
          .thenThrow(CartLocalException('No cached data'));

      // act
      final result = await repository.getCartItems();

      // assert
      verify(mockLocalDataSource.getCachedCartItems());
      verifyZeroInteractions(mockRemoteDataSource);
      verifyZeroInteractions(mockNetworkInfo);
      expect(result, equals(const Left(CacheFailure(message: 'No cached data'))));
    });
  });

  group('addToCart', () {
    test('should add to local cart directly (local-first strategy)', () async {
      // arrange
      when(mockLocalDataSource.addToLocalCart(product: tProduct, quantity: tQuantity))
          .thenAnswer((_) async => tCartItemModel);

      // act
      final result = await repository.addToCart(product: tProduct, quantity: tQuantity);

      // assert
      verify(mockLocalDataSource.addToLocalCart(product: tProduct, quantity: tQuantity));
      verifyZeroInteractions(mockRemoteDataSource);
      verifyZeroInteractions(mockNetworkInfo);
      expect(result, equals(Right(tCartItemModel)));
    });

    test('should return CacheFailure when local data source fails', () async {
      // arrange
      when(mockLocalDataSource.addToLocalCart(product: tProduct, quantity: tQuantity))
          .thenThrow(CartLocalException('Local error'));

      // act
      final result = await repository.addToCart(product: tProduct, quantity: tQuantity);

      // assert
      verify(mockLocalDataSource.addToLocalCart(product: tProduct, quantity: tQuantity));
      verifyZeroInteractions(mockRemoteDataSource);
      verifyZeroInteractions(mockNetworkInfo);
      expect(result, equals(const Left(CacheFailure(message: 'Local error'))));
    });
  });

  group('removeFromCart', () {
    test('should remove from local cart directly (local-first strategy)', () async {
      // arrange
      when(mockLocalDataSource.removeFromLocalCart(cartItemId: tCartItemId))
          .thenAnswer((_) async => true);

      // act
      final result = await repository.removeFromCart(cartItemId: tCartItemId);

      // assert
      verify(mockLocalDataSource.removeFromLocalCart(cartItemId: tCartItemId));
      verifyZeroInteractions(mockRemoteDataSource);
      verifyZeroInteractions(mockNetworkInfo);
      expect(result, equals(const Right(true)));
    });

    test('should return CacheFailure when local data source fails', () async {
      // arrange
      when(mockLocalDataSource.removeFromLocalCart(cartItemId: tCartItemId))
          .thenThrow(CartLocalException('Local error'));

      // act
      final result = await repository.removeFromCart(cartItemId: tCartItemId);

      // assert
      verify(mockLocalDataSource.removeFromLocalCart(cartItemId: tCartItemId));
      verifyZeroInteractions(mockRemoteDataSource);
      verifyZeroInteractions(mockNetworkInfo);
      expect(result, equals(const Left(CacheFailure(message: 'Local error'))));
    });
  });

  group('updateQuantity', () {
    test('should update quantity in local cart directly (local-first strategy)', () async {
      // arrange
      when(mockLocalDataSource.updateLocalQuantity(
        cartItemId: tCartItemId,
        quantity: tQuantity,
      )).thenAnswer((_) async => tCartItemModel);

      // act
      final result = await repository.updateQuantity(cartItemId: tCartItemId, quantity: tQuantity);

      // assert
      verify(mockLocalDataSource.updateLocalQuantity(cartItemId: tCartItemId, quantity: tQuantity));
      verifyZeroInteractions(mockRemoteDataSource);
      verifyZeroInteractions(mockNetworkInfo);
      expect(result, equals(Right(tCartItemModel)));
    });

    test('should return ServerFailure when local data source fails', () async {
      // arrange
      when(mockLocalDataSource.updateLocalQuantity(
        cartItemId: tCartItemId,
        quantity: tQuantity,
      )).thenThrow(CartLocalException('Local error'));

      // act
      final result = await repository.updateQuantity(cartItemId: tCartItemId, quantity: tQuantity);

      // assert
      verify(mockLocalDataSource.updateLocalQuantity(cartItemId: tCartItemId, quantity: tQuantity));
      verifyZeroInteractions(mockRemoteDataSource);
      verifyZeroInteractions(mockNetworkInfo);
      expect(result, equals(const Left(ServerFailure(message: 'CartLocalException: Local error'))));
    });
  });

  group('getTotalPrice', () {
    const tTotalPrice = 199.98;

    test('should return total price from local storage directly (local-first strategy)', () async {
      // arrange
      when(mockLocalDataSource.getLocalTotalPrice()).thenAnswer((_) async => tTotalPrice);

      // act
      final result = await repository.getTotalPrice();

      // assert
      verify(mockLocalDataSource.getLocalTotalPrice());
      verifyZeroInteractions(mockRemoteDataSource);
      verifyZeroInteractions(mockNetworkInfo);
      expect(result, equals(const Right(tTotalPrice)));
    });

    test('should return CacheFailure when local data source fails', () async {
      // arrange
      when(mockLocalDataSource.getLocalTotalPrice())
          .thenThrow(CartLocalException('Local error'));

      // act
      final result = await repository.getTotalPrice();

      // assert
      verify(mockLocalDataSource.getLocalTotalPrice());
      verifyZeroInteractions(mockRemoteDataSource);
      verifyZeroInteractions(mockNetworkInfo);
      expect(result, equals(const Left(CacheFailure(message: 'Local error'))));
    });
  });

  group('isInCart', () {
    test('should return true when product is in cart (online)', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemoteDataSource.isInCart(productId: tProductId))
          .thenAnswer((_) async => true);

      // act
      final result = await repository.isInCart(productId: tProductId);

      // assert
      verify(mockNetworkInfo.isConnected);
      verify(mockRemoteDataSource.isInCart(productId: tProductId));
      expect(result, equals(const Right(true)));
    });

    test('should return false when product is not in cart (online)', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemoteDataSource.isInCart(productId: tProductId))
          .thenAnswer((_) async => false);

      // act
      final result = await repository.isInCart(productId: tProductId);

      // assert
      verify(mockNetworkInfo.isConnected);
      verify(mockRemoteDataSource.isInCart(productId: tProductId));
      expect(result, equals(const Right(false)));
    });

    test('should fallback to local when remote fails', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemoteDataSource.isInCart(productId: tProductId))
          .thenThrow(CartException('Server error'));
      when(mockLocalDataSource.isInLocalCart(productId: tProductId))
          .thenAnswer((_) async => true);

      // act
      final result = await repository.isInCart(productId: tProductId);

      // assert
      verify(mockNetworkInfo.isConnected);
      verify(mockRemoteDataSource.isInCart(productId: tProductId));
      verify(mockLocalDataSource.isInLocalCart(productId: tProductId));
      expect(result, equals(const Right(true)));
    });

    test('should use local when offline', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      when(mockLocalDataSource.isInLocalCart(productId: tProductId))
          .thenAnswer((_) async => true);

      // act
      final result = await repository.isInCart(productId: tProductId);

      // assert
      verify(mockNetworkInfo.isConnected);
      verifyZeroInteractions(mockRemoteDataSource);
      verify(mockLocalDataSource.isInLocalCart(productId: tProductId));
      expect(result, equals(const Right(true)));
    });
  });
}
