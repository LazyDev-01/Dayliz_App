import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:dayliz_app/domain/usecases/get_wishlist_products_usecase.dart';
import 'package:dayliz_app/domain/usecases/add_to_wishlist_usecase.dart';
import 'package:dayliz_app/domain/usecases/remove_from_wishlist_usecase.dart';
import 'package:dayliz_app/domain/usecases/is_in_wishlist_usecase.dart';
import 'package:dayliz_app/domain/usecases/clear_wishlist_usecase.dart';
import 'package:dayliz_app/presentation/providers/wishlist_providers.dart';

// Simple mock classes
class MockGetWishlistProductsUseCase extends Mock implements GetWishlistProductsUseCase {}
class MockAddToWishlistUseCase extends Mock implements AddToWishlistUseCase {}
class MockRemoveFromWishlistUseCase extends Mock implements RemoveFromWishlistUseCase {}
class MockIsInWishlistUseCase extends Mock implements IsInWishlistUseCase {}
class MockClearWishlistUseCase extends Mock implements ClearWishlistUseCase {}

void main() {
  late MockGetWishlistProductsUseCase mockGetWishlistProductsUseCase;
  late MockAddToWishlistUseCase mockAddToWishlistUseCase;
  late MockRemoveFromWishlistUseCase mockRemoveFromWishlistUseCase;
  late MockIsInWishlistUseCase mockIsInWishlistUseCase;
  late MockClearWishlistUseCase mockClearWishlistUseCase;

  setUp(() {
    mockGetWishlistProductsUseCase = MockGetWishlistProductsUseCase();
    mockAddToWishlistUseCase = MockAddToWishlistUseCase();
    mockRemoveFromWishlistUseCase = MockRemoveFromWishlistUseCase();
    mockIsInWishlistUseCase = MockIsInWishlistUseCase();
    mockClearWishlistUseCase = MockClearWishlistUseCase();
  });

  group('WishlistNotifier', () {
    late WishlistNotifier notifier;

    setUp(() {
      notifier = WishlistNotifier(
        getWishlistProductsUseCase: mockGetWishlistProductsUseCase,
        addToWishlistUseCase: mockAddToWishlistUseCase,
        removeFromWishlistUseCase: mockRemoveFromWishlistUseCase,
        isInWishlistUseCase: mockIsInWishlistUseCase,
        clearWishlistUseCase: mockClearWishlistUseCase,
      );
    });

    test('initial state should have empty products', () {
      expect(notifier.state.products, isEmpty);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.errorMessage, isNull);
    });






  });
}
