import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:dayliz_app/core/errors/exceptions.dart';
import 'package:dayliz_app/core/errors/failures.dart';
import 'package:dayliz_app/core/network/network_info.dart';
import 'package:dayliz_app/data/datasources/cart_local_data_source.dart';
import 'package:dayliz_app/data/datasources/cart_remote_data_source.dart';
import 'package:dayliz_app/data/repositories/cart_repository_impl.dart';
import 'package:dayliz_app/domain/entities/cart_item.dart';
import 'package:dayliz_app/domain/entities/product.dart';

// Manual mock classes
class MockCartRemoteDataSource extends Mock implements CartRemoteDataSource {}
class MockCartLocalDataSource extends Mock implements CartLocalDataSource {}
class MockNetworkInfo extends Mock implements NetworkInfo {}

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

  const tProduct = Product(
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

  final tCartItem = CartItem(
    id: 'test-cart-item-id',
    product: tProduct,
    quantity: 2,
    addedAt: DateTime.now(),
  );

  final tCartItems = [tCartItem];
  const tQuantity = 2;
  const tCartItemId = 'test-cart-item-id';
  const tProductId = 'test-product-id';

  group('getCartItems', () {
    test('should check if the device is online', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemoteDataSource.getCartItems()).thenAnswer((_) async => tCartItems);
      when(mockLocalDataSource.cacheCartItems(any)).thenAnswer((_) async => {});

      // act
      await repository.getCartItems();

      // assert
      verify(mockNetworkInfo.isConnected);
    });

    group('device is online', () {
      setUp(() {
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      });

      test('should return remote data when the call to remote data source is successful', () async {
        // arrange
        when(mockRemoteDataSource.getCartItems()).thenAnswer((_) async => tCartItems);
        when(mockLocalDataSource.cacheCartItems(any)).thenAnswer((_) async => {});

        // act
        final result = await repository.getCartItems();

        // assert
        verify(mockRemoteDataSource.getCartItems());
        verify(mockLocalDataSource.cacheCartItems(tCartItems));
        expect(result, equals(Right(tCartItems)));
      });

      test('should cache the data locally when the call to remote data source is successful', () async {
        // arrange
        when(mockRemoteDataSource.getCartItems()).thenAnswer((_) async => tCartItems);
        when(mockLocalDataSource.cacheCartItems(any)).thenAnswer((_) async => {});

        // act
        await repository.getCartItems();

        // assert
        verify(mockLocalDataSource.cacheCartItems(tCartItems));
      });

      test('should return local data when the call to remote data source fails', () async {
        // arrange
        when(mockRemoteDataSource.getCartItems()).thenThrow(const CartException(message: 'Server error'));
        when(mockLocalDataSource.getCachedCartItems()).thenAnswer((_) async => tCartItems);

        // act
        final result = await repository.getCartItems();

        // assert
        verify(mockRemoteDataSource.getCartItems());
        verify(mockLocalDataSource.getCachedCartItems());
        expect(result, equals(Right(tCartItems)));
      });
    });

    group('device is offline', () {
      setUp(() {
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      });

      test('should return last locally cached data when cached data is present', () async {
        // arrange
        when(mockLocalDataSource.getCachedCartItems()).thenAnswer((_) async => tCartItems);

        // act
        final result = await repository.getCartItems();

        // assert
        verifyZeroInteractions(mockRemoteDataSource);
        verify(mockLocalDataSource.getCachedCartItems());
        expect(result, equals(Right(tCartItems)));
      });

      test('should return CacheFailure when there is no cached data present', () async {
        // arrange
        when(mockLocalDataSource.getCachedCartItems())
            .thenThrow(const CartLocalException(message: 'No cached data'));

        // act
        final result = await repository.getCartItems();

        // assert
        verifyZeroInteractions(mockRemoteDataSource);
        verify(mockLocalDataSource.getCachedCartItems());
        expect(result, equals(const Left(CacheFailure(message: 'No cached data'))));
      });
    });
  });

  group('addToCart', () {
    test('should return cart item when the call to remote data source is successful', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemoteDataSource.addToCart(product: anyNamed('product'), quantity: anyNamed('quantity')))
          .thenAnswer((_) async => tCartItem);
      when(mockLocalDataSource.addToLocalCart(product: anyNamed('product'), quantity: anyNamed('quantity')))
          .thenAnswer((_) async => tCartItem);

      // act
      final result = await repository.addToCart(product: tProduct, quantity: tQuantity);

      // assert
      verify(mockRemoteDataSource.addToCart(product: tProduct, quantity: tQuantity));
      verify(mockLocalDataSource.addToLocalCart(product: tProduct, quantity: tQuantity));
      expect(result, equals(Right(tCartItem)));
    });

    test('should add to local cart when remote data source fails', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemoteDataSource.addToCart(product: anyNamed('product'), quantity: anyNamed('quantity')))
          .thenThrow(const CartException(message: 'Server error'));
      when(mockLocalDataSource.addToLocalCart(product: anyNamed('product'), quantity: anyNamed('quantity')))
          .thenAnswer((_) async => tCartItem);

      // act
      final result = await repository.addToCart(product: tProduct, quantity: tQuantity);

      // assert
      verify(mockRemoteDataSource.addToCart(product: tProduct, quantity: tQuantity));
      verify(mockLocalDataSource.addToLocalCart(product: tProduct, quantity: tQuantity));
      expect(result, equals(Right(tCartItem)));
    });

    test('should return failure when both remote and local data sources fail', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemoteDataSource.addToCart(product: anyNamed('product'), quantity: anyNamed('quantity')))
          .thenThrow(const CartException(message: 'Server error'));
      when(mockLocalDataSource.addToLocalCart(product: anyNamed('product'), quantity: anyNamed('quantity')))
          .thenThrow(const CartLocalException(message: 'Local error'));

      // act
      final result = await repository.addToCart(product: tProduct, quantity: tQuantity);

      // assert
      expect(result, equals(const Left(CacheFailure(message: 'Local error'))));
    });
  });

  group('removeFromCart', () {
    test('should return true when the call to remote data source is successful', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemoteDataSource.removeFromCart(cartItemId: anyNamed('cartItemId')))
          .thenAnswer((_) async => true);
      when(mockLocalDataSource.removeFromLocalCart(cartItemId: anyNamed('cartItemId')))
          .thenAnswer((_) async => true);

      // act
      final result = await repository.removeFromCart(cartItemId: tCartItemId);

      // assert
      verify(mockRemoteDataSource.removeFromCart(cartItemId: tCartItemId));
      verify(mockLocalDataSource.removeFromLocalCart(cartItemId: tCartItemId));
      expect(result, equals(const Right(true)));
    });

    test('should remove from local cart when remote data source fails', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemoteDataSource.removeFromCart(cartItemId: anyNamed('cartItemId')))
          .thenThrow(const CartException(message: 'Server error'));
      when(mockLocalDataSource.removeFromLocalCart(cartItemId: anyNamed('cartItemId')))
          .thenAnswer((_) async => true);

      // act
      final result = await repository.removeFromCart(cartItemId: tCartItemId);

      // assert
      verify(mockRemoteDataSource.removeFromCart(cartItemId: tCartItemId));
      verify(mockLocalDataSource.removeFromLocalCart(cartItemId: tCartItemId));
      expect(result, equals(const Right(true)));
    });
  });

  group('updateQuantity', () {
    test('should return updated cart item when the call to remote data source is successful', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemoteDataSource.updateQuantity(
        cartItemId: anyNamed('cartItemId'),
        quantity: anyNamed('quantity'),
      )).thenAnswer((_) async => tCartItem);
      when(mockLocalDataSource.updateLocalQuantity(
        cartItemId: anyNamed('cartItemId'),
        quantity: anyNamed('quantity'),
      )).thenAnswer((_) async => tCartItem);

      // act
      final result = await repository.updateQuantity(cartItemId: tCartItemId, quantity: tQuantity);

      // assert
      verify(mockRemoteDataSource.updateQuantity(cartItemId: tCartItemId, quantity: tQuantity));
      verify(mockLocalDataSource.updateLocalQuantity(cartItemId: tCartItemId, quantity: tQuantity));
      expect(result, equals(Right(tCartItem)));
    });
  });

  group('getTotalPrice', () {
    const tTotalPrice = 199.98;

    test('should return total price when the call to remote data source is successful', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemoteDataSource.getTotalPrice()).thenAnswer((_) async => tTotalPrice);

      // act
      final result = await repository.getTotalPrice();

      // assert
      verify(mockRemoteDataSource.getTotalPrice());
      expect(result, equals(const Right(tTotalPrice)));
    });

    test('should return local total price when remote data source fails', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemoteDataSource.getTotalPrice()).thenThrow(const CartException(message: 'Server error'));
      when(mockLocalDataSource.getLocalTotalPrice()).thenAnswer((_) async => tTotalPrice);

      // act
      final result = await repository.getTotalPrice();

      // assert
      verify(mockRemoteDataSource.getTotalPrice());
      verify(mockLocalDataSource.getLocalTotalPrice());
      expect(result, equals(const Right(tTotalPrice)));
    });
  });

  group('isInCart', () {
    test('should return true when product is in cart', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemoteDataSource.isInCart(productId: anyNamed('productId')))
          .thenAnswer((_) async => true);

      // act
      final result = await repository.isInCart(productId: tProductId);

      // assert
      verify(mockRemoteDataSource.isInCart(productId: tProductId));
      expect(result, equals(const Right(true)));
    });

    test('should return false when product is not in cart', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemoteDataSource.isInCart(productId: anyNamed('productId')))
          .thenAnswer((_) async => false);

      // act
      final result = await repository.isInCart(productId: tProductId);

      // assert
      verify(mockRemoteDataSource.isInCart(productId: tProductId));
      expect(result, equals(const Right(false)));
    });
  });
}
