# Clean Home Screen: Banner Carousel Implementation

## 1. Banner Carousel Overview

The banner carousel is a prominent feature of the home screen, showcasing promotions, new arrivals, and special offers. It should be visually striking, interactive, and provide clear calls to action.

### 1.1 Design Goals

- **Visual Impact**: Eye-catching, high-quality images with clear messaging
- **Interactivity**: Smooth auto-scrolling with manual navigation
- **Call to Action**: Clear buttons or tap areas for user engagement
- **Loading States**: Elegant handling of loading and error states
- **Accessibility**: Proper contrast for text and pause functionality

## 2. Banner Entity and Model

### 2.1 Domain Entity

```dart
// lib/domain/entities/banner.dart
class Banner {
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String actionUrl;
  final BannerActionType actionType;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;

  const Banner({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.actionUrl,
    required this.actionType,
    this.startDate,
    this.endDate,
    this.isActive = true,
  });
  
  bool get isValid {
    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    return isActive;
  }
}

enum BannerActionType {
  product,
  category,
  collection,
  url,
  none,
}
```

### 2.2 Data Model

```dart
// lib/data/models/banner_model.dart
class BannerModel extends Banner {
  const BannerModel({
    required String id,
    required String title,
    required String subtitle,
    required String imageUrl,
    required String actionUrl,
    required BannerActionType actionType,
    DateTime? startDate,
    DateTime? endDate,
    bool isActive = true,
  }) : super(
          id: id,
          title: title,
          subtitle: subtitle,
          imageUrl: imageUrl,
          actionUrl: actionUrl,
          actionType: actionType,
          startDate: startDate,
          endDate: endDate,
          isActive: isActive,
        );

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'],
      title: json['title'],
      subtitle: json['subtitle'] ?? '',
      imageUrl: json['image_url'],
      actionUrl: json['action_url'] ?? '',
      actionType: _parseActionType(json['action_type']),
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'])
          : null,
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'image_url': imageUrl,
      'action_url': actionUrl,
      'action_type': actionType.toString().split('.').last,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'is_active': isActive,
    };
  }

  static BannerActionType _parseActionType(String? type) {
    switch (type) {
      case 'product':
        return BannerActionType.product;
      case 'category':
        return BannerActionType.category;
      case 'collection':
        return BannerActionType.collection;
      case 'url':
        return BannerActionType.url;
      default:
        return BannerActionType.none;
    }
  }
}
```

## 3. Banner Repository

### 3.1 Repository Interface

```dart
// lib/domain/repositories/banner_repository.dart
abstract class BannerRepository {
  Future<Either<Failure, List<Banner>>> getBanners();
}
```

### 3.2 Repository Implementation

```dart
// lib/data/repositories/banner_repository_impl.dart
class BannerRepositoryImpl implements BannerRepository {
  final BannerRemoteDataSource remoteDataSource;
  final BannerLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  BannerRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Banner>>> getBanners() async {
    if (await networkInfo.isConnected) {
      try {
        final remoteBanners = await remoteDataSource.getBanners();
        await localDataSource.cacheBanners(remoteBanners);
        return Right(remoteBanners);
      } on ServerException {
        return Left(ServerFailure());
      }
    } else {
      try {
        final localBanners = await localDataSource.getCachedBanners();
        return Right(localBanners);
      } on CacheException {
        return Left(CacheFailure());
      }
    }
  }
}
```

## 4. Banner Use Case

```dart
// lib/domain/usecases/get_banners_usecase.dart
class GetBannersUseCase implements UseCase<List<Banner>, NoParams> {
  final BannerRepository repository;

  GetBannersUseCase(this.repository);

  @override
  Future<Either<Failure, List<Banner>>> call(NoParams params) async {
    return await repository.getBanners();
  }
}
```

## 5. Banner State Management

### 5.1 Banner State

```dart
// lib/presentation/providers/banner_state.dart
class BannerState {
  final List<Banner> banners;
  final bool isLoading;
  final String? errorMessage;
  final int currentIndex;

  const BannerState({
    this.banners = const [],
    this.isLoading = false,
    this.errorMessage,
    this.currentIndex = 0,
  });

  BannerState copyWith({
    List<Banner>? banners,
    bool? isLoading,
    String? errorMessage,
    int? currentIndex,
  }) {
    return BannerState(
      banners: banners ?? this.banners,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }
}
```

### 5.2 Banner Notifier

```dart
// lib/presentation/providers/banner_notifier.dart
class BannerNotifier extends StateNotifier<BannerState> {
  final GetBannersUseCase getBannersUseCase;

  BannerNotifier({
    required this.getBannersUseCase,
  }) : super(const BannerState());

  Future<void> loadBanners() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await getBannersUseCase(NoParams());

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: _mapFailureToMessage(failure),
      ),
      (banners) => state = state.copyWith(
        isLoading: false,
        banners: banners.where((banner) => banner.isValid).toList(),
      ),
    );
  }

  void setCurrentIndex(int index) {
    state = state.copyWith(currentIndex: index);
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

### 5.3 Banner Providers

```dart
// lib/presentation/providers/banner_providers.dart
final bannerNotifierProvider =
    StateNotifierProvider<BannerNotifier, BannerState>((ref) {
  return BannerNotifier(
    getBannersUseCase: ref.watch(getBannersUseCaseProvider),
  );
});

final bannersProvider = Provider<List<Banner>>((ref) {
  return ref.watch(bannerNotifierProvider).banners;
});

final bannersLoadingProvider = Provider<bool>((ref) {
  return ref.watch(bannerNotifierProvider).isLoading;
});

final bannersErrorProvider = Provider<String?>((ref) {
  return ref.watch(bannerNotifierProvider).errorMessage;
});

final currentBannerIndexProvider = Provider<int>((ref) {
  return ref.watch(bannerNotifierProvider).currentIndex;
});
```

## 6. Banner Carousel Widget

### 6.1 Banner Carousel Implementation

```dart
// lib/presentation/widgets/home/banner_carousel.dart
class BannerCarousel extends ConsumerStatefulWidget {
  const BannerCarousel({Key? key}) : super(key: key);

  @override
  ConsumerState<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends ConsumerState<BannerCarousel> {
  late PageController _pageController;
  Timer? _autoScrollTimer;
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9);
    _startAutoScroll();
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    _autoScrollTimer?.cancel();
    super.dispose();
  }
  
  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      final banners = ref.read(bannersProvider);
      if (banners.isEmpty) return;
      
      final currentIndex = ref.read(currentBannerIndexProvider);
      final nextIndex = (currentIndex + 1) % banners.length;
      
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final banners = ref.watch(bannersProvider);
    final isLoading = ref.watch(bannersLoadingProvider);
    final errorMessage = ref.watch(bannersErrorProvider);
    final currentIndex = ref.watch(currentBannerIndexProvider);
    
    if (isLoading) {
      return _buildLoadingState();
    }
    
    if (errorMessage != null) {
      return _buildErrorState(errorMessage);
    }
    
    if (banners.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _pageController,
            itemCount: banners.length,
            onPageChanged: (index) {
              ref.read(bannerNotifierProvider.notifier).setCurrentIndex(index);
            },
            itemBuilder: (context, index) {
              return _buildBannerItem(context, banners[index]);
            },
          ),
        ),
        const SizedBox(height: 12),
        _buildPageIndicator(banners.length, currentIndex),
      ],
    );
  }
  
  Widget _buildLoadingState() {
    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
  
  Widget _buildErrorState(String message) {
    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 40, color: Colors.red),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                ref.read(bannerNotifierProvider.notifier).loadBanners();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBannerItem(BuildContext context, Banner banner) {
    return GestureDetector(
      onTap: () => _handleBannerTap(context, banner),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Banner image
            CachedNetworkImage(
              imageUrl: banner.imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              placeholder: (context, url) => Container(
                color: Colors.grey[300],
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(Icons.error_outline, size: 40),
                ),
              ),
            ),
            
            // Gradient overlay for text readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            
            // Banner content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    banner.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: Offset(1, 1),
                          blurRadius: 2,
                          color: Colors.black45,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    banner.subtitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      shadows: [
                        Shadow(
                          offset: Offset(1, 1),
                          blurRadius: 2,
                          color: Colors.black45,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _handleBannerTap(context, banner),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('Shop Now'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPageIndicator(int count, int currentIndex) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (index) => Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: currentIndex == index
                ? Theme.of(context).primaryColor
                : Colors.grey[300],
          ),
        ),
      ),
    );
  }
  
  void _handleBannerTap(BuildContext context, Banner banner) {
    switch (banner.actionType) {
      case BannerActionType.product:
        context.push('/product/${banner.actionUrl}');
        break;
      case BannerActionType.category:
        context.push('/category/${banner.actionUrl}');
        break;
      case BannerActionType.collection:
        context.push('/collection/${banner.actionUrl}');
        break;
      case BannerActionType.url:
        // Handle external URL
        launchUrl(Uri.parse(banner.actionUrl));
        break;
      case BannerActionType.none:
        // Do nothing
        break;
    }
  }
}
```

### 6.2 Integration in Home Screen

```dart
Widget _buildBannerSection() {
  return SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 24),
      child: const BannerCarousel(),
    ),
  );
}
```

## 7. Accessibility Considerations

- **Auto-scrolling**: Pause auto-scrolling when the user interacts with the carousel
- **Text Contrast**: Ensure text has sufficient contrast against background images
- **Touch Targets**: Make buttons large enough for easy tapping
- **Screen Reader Support**: Add meaningful descriptions for banner images
- **Reduced Motion**: Consider disabling animations for users with reduced motion preference

## 8. Performance Optimization

- **Image Caching**: Use CachedNetworkImage for efficient image loading
- **Lazy Loading**: Load images only when they're about to be displayed
- **Image Optimization**: Use appropriately sized images for different screen sizes
- **Memory Management**: Dispose of controllers and timers properly
- **Viewport Fraction**: Use viewportFraction to reduce the number of items rendered

## 9. Testing Strategy

### 9.1 Unit Tests

- Test banner entity and model
- Test banner repository
- Test banner use case
- Test banner notifier

### 9.2 Widget Tests

- Test banner carousel rendering
- Test banner carousel navigation
- Test loading and error states

### 9.3 Integration Tests

- Test banner carousel in the context of the home screen
- Test banner navigation to other screens
