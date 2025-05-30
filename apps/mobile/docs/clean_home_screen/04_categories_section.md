# Clean Home Screen: Categories Section Implementation

## 1. Categories Section Overview

The categories section provides users with quick access to product categories, helping them navigate to specific product groups. It should be visually appealing, intuitive, and efficient.

### 1.1 Design Goals

- **Visual Appeal**: Clear icons or images representing each category
- **Efficient Navigation**: Quick access to category products
- **Compact Layout**: Display multiple categories without overwhelming the screen
- **Loading States**: Elegant handling of loading and error states
- **Accessibility**: Clear labels and adequate touch targets

## 2. Category Entity and Model

### 2.1 Domain Entity

```dart
// lib/domain/entities/category.dart
class Category {
  final String id;
  final String name;
  final String? imageUrl;
  final String? iconName;
  final String? parentId;
  final int productCount;
  final bool isActive;
  final int sortOrder;

  const Category({
    required this.id,
    required this.name,
    this.imageUrl,
    this.iconName,
    this.parentId,
    this.productCount = 0,
    this.isActive = true,
    this.sortOrder = 0,
  });
}
```

### 2.2 Data Model

```dart
// lib/data/models/category_model.dart
class CategoryModel extends Category {
  const CategoryModel({
    required String id,
    required String name,
    String? imageUrl,
    String? iconName,
    String? parentId,
    int productCount = 0,
    bool isActive = true,
    int sortOrder = 0,
  }) : super(
          id: id,
          name: name,
          imageUrl: imageUrl,
          iconName: iconName,
          parentId: parentId,
          productCount: productCount,
          isActive: isActive,
          sortOrder: sortOrder,
        );

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'],
      imageUrl: json['image_url'],
      iconName: json['icon_name'],
      parentId: json['parent_id'],
      productCount: json['product_count'] ?? 0,
      isActive: json['is_active'] ?? true,
      sortOrder: json['sort_order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image_url': imageUrl,
      'icon_name': iconName,
      'parent_id': parentId,
      'product_count': productCount,
      'is_active': isActive,
      'sort_order': sortOrder,
    };
  }
}
```

## 3. Category Repository

### 3.1 Repository Interface

```dart
// lib/domain/repositories/category_repository.dart
abstract class CategoryRepository {
  Future<Either<Failure, List<Category>>> getCategories();
  Future<Either<Failure, List<Category>>> getSubcategories(String parentId);
}
```

### 3.2 Repository Implementation

```dart
// lib/data/repositories/category_repository_impl.dart
class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryRemoteDataSource remoteDataSource;
  final CategoryLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  CategoryRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Category>>> getCategories() async {
    if (await networkInfo.isConnected) {
      try {
        final remoteCategories = await remoteDataSource.getCategories();
        await localDataSource.cacheCategories(remoteCategories);
        return Right(remoteCategories);
      } on ServerException {
        return Left(ServerFailure());
      }
    } else {
      try {
        final localCategories = await localDataSource.getCachedCategories();
        return Right(localCategories);
      } on CacheException {
        return Left(CacheFailure());
      }
    }
  }

  @override
  Future<Either<Failure, List<Category>>> getSubcategories(String parentId) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteSubcategories = await remoteDataSource.getSubcategories(parentId);
        return Right(remoteSubcategories);
      } on ServerException {
        return Left(ServerFailure());
      }
    } else {
      try {
        final localCategories = await localDataSource.getCachedCategories();
        final subcategories = localCategories
            .where((category) => category.parentId == parentId)
            .toList();
        return Right(subcategories);
      } on CacheException {
        return Left(CacheFailure());
      }
    }
  }
}
```

## 4. Category Use Cases

### 4.1 Get Categories Use Case

```dart
// lib/domain/usecases/get_categories_usecase.dart
class GetCategoriesUseCase implements UseCase<List<Category>, NoParams> {
  final CategoryRepository repository;

  GetCategoriesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Category>>> call(NoParams params) async {
    return await repository.getCategories();
  }
}
```

### 4.2 Get Subcategories Use Case

```dart
// lib/domain/usecases/get_subcategories_usecase.dart
class GetSubcategoriesUseCase implements UseCase<List<Category>, String> {
  final CategoryRepository repository;

  GetSubcategoriesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Category>>> call(String parentId) async {
    return await repository.getSubcategories(parentId);
  }
}
```

## 5. Category State Management

### 5.1 Category State

```dart
// lib/presentation/providers/category_state.dart
class CategoryState {
  final List<Category> categories;
  final bool isLoading;
  final String? errorMessage;

  const CategoryState({
    this.categories = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  CategoryState copyWith({
    List<Category>? categories,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CategoryState(
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}
```

### 5.2 Category Notifier

```dart
// lib/presentation/providers/category_notifier.dart
class CategoryNotifier extends StateNotifier<CategoryState> {
  final GetCategoriesUseCase getCategoriesUseCase;

  CategoryNotifier({
    required this.getCategoriesUseCase,
  }) : super(const CategoryState());

  Future<void> loadCategories() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await getCategoriesUseCase(NoParams());

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: _mapFailureToMessage(failure),
      ),
      (categories) {
        // Filter out inactive categories and sort by sortOrder
        final activeCategories = categories
            .where((category) => category.isActive && category.parentId == null)
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        
        state = state.copyWith(
          isLoading: false,
          categories: activeCategories,
        );
      },
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

### 5.3 Category Providers

```dart
// lib/presentation/providers/category_providers.dart
final categoryNotifierProvider =
    StateNotifierProvider<CategoryNotifier, CategoryState>((ref) {
  return CategoryNotifier(
    getCategoriesUseCase: ref.watch(getCategoriesUseCaseProvider),
  );
});

final categoriesProvider = Provider<List<Category>>((ref) {
  return ref.watch(categoryNotifierProvider).categories;
});

final categoriesLoadingProvider = Provider<bool>((ref) {
  return ref.watch(categoryNotifierProvider).isLoading;
});

final categoriesErrorProvider = Provider<String?>((ref) {
  return ref.watch(categoryNotifierProvider).errorMessage;
});
```

## 6. Categories Section Widget

### 6.1 Categories Grid Implementation

```dart
// lib/presentation/widgets/home/categories_grid.dart
class CategoriesGrid extends ConsumerWidget {
  const CategoriesGrid({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final isLoading = ref.watch(categoriesLoadingProvider);
    final errorMessage = ref.watch(categoriesErrorProvider);
    
    if (isLoading) {
      return _buildLoadingState();
    }
    
    if (errorMessage != null) {
      return _buildErrorState(context, errorMessage, ref);
    }
    
    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Categories',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => context.push('/categories'),
                child: const Text('See All'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              return _buildCategoryItem(context, categories[index]);
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildLoadingState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 100,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Container(
                width: 60,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            itemBuilder: (context, index) {
              return Container(
                width: 80,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 60,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildErrorState(BuildContext context, String message, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red[700]),
              const SizedBox(width: 8),
              Text(
                'Categories Error',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: Colors.red[700]),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              ref.read(categoryNotifierProvider.notifier).loadCategories();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCategoryItem(BuildContext context, Category category) {
    return GestureDetector(
      onTap: () => context.push('/category/${category.id}'),
      child: Container(
        width: 80,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: category.imageUrl != null
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: category.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        errorWidget: (context, url, error) => Icon(
                          _getCategoryIcon(category.iconName),
                          color: Theme.of(context).primaryColor,
                          size: 32,
                        ),
                      ),
                    )
                  : Icon(
                      _getCategoryIcon(category.iconName),
                      color: Theme.of(context).primaryColor,
                      size: 32,
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              category.name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
  
  IconData _getCategoryIcon(String? iconName) {
    switch (iconName) {
      case 'fruits':
        return Icons.apple;
      case 'vegetables':
        return Icons.eco;
      case 'dairy':
        return Icons.egg;
      case 'meat':
        return Icons.restaurant;
      case 'bakery':
        return Icons.bakery_dining;
      case 'beverages':
        return Icons.local_drink;
      case 'snacks':
        return Icons.cookie;
      case 'household':
        return Icons.cleaning_services;
      case 'personal_care':
        return Icons.spa;
      case 'baby':
        return Icons.child_care;
      case 'pets':
        return Icons.pets;
      default:
        return Icons.category;
    }
  }
}
```

### 6.2 Alternative Grid Layout Implementation

```dart
// lib/presentation/widgets/home/categories_grid_alternative.dart
class CategoriesGridAlternative extends ConsumerWidget {
  const CategoriesGridAlternative({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final isLoading = ref.watch(categoriesLoadingProvider);
    final errorMessage = ref.watch(categoriesErrorProvider);
    
    if (isLoading) {
      return _buildLoadingState();
    }
    
    if (errorMessage != null) {
      return _buildErrorState(context, errorMessage, ref);
    }
    
    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Limit to 8 categories for the grid
    final displayCategories = categories.length > 8
        ? categories.sublist(0, 8)
        : categories;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Categories',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => context.push('/categories'),
                child: const Text('See All'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 0.8,
            crossAxisSpacing: 8,
            mainAxisSpacing: 16,
          ),
          itemCount: displayCategories.length,
          itemBuilder: (context, index) {
            return _buildCategoryItem(context, displayCategories[index]);
          },
        ),
      ],
    );
  }
  
  // Loading, error, and item building methods would be similar to the previous implementation
}
```

### 6.3 Integration in Home Screen

```dart
Widget _buildCategoriesSection() {
  return SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: const CategoriesGrid(),
    ),
  );
}
```

## 7. Accessibility Considerations

- **Text Size**: Ensure category names are readable at different text sizes
- **Touch Targets**: Make category items large enough for easy tapping (minimum 48x48dp)
- **Screen Reader Support**: Add meaningful descriptions for category icons/images
- **Color Contrast**: Ensure text has sufficient contrast against backgrounds
- **Focus Navigation**: Support keyboard navigation for accessibility

## 8. Performance Optimization

- **Image Caching**: Use CachedNetworkImage for efficient image loading
- **Lazy Loading**: Load images only when they're about to be displayed
- **Image Optimization**: Use appropriately sized images for category icons
- **List Recycling**: Use ListView.builder for efficient item recycling
- **Pagination**: If there are many categories, consider pagination or "See All" navigation

## 9. Testing Strategy

### 9.1 Unit Tests

- Test category entity and model
- Test category repository
- Test category use cases
- Test category notifier

### 9.2 Widget Tests

- Test categories grid rendering
- Test category item rendering
- Test loading and error states

### 9.3 Integration Tests

- Test categories grid in the context of the home screen
- Test navigation to category detail screens
