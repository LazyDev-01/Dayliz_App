import 'package:dayliz_app/models/product.dart';

/// Mock products for testing and development
final List<Product> mockProducts = [
  Product(
    id: '1',
    name: 'Fresh Organic Vegetables',
    description: 'A bundle of fresh, organic vegetables including carrots, tomatoes, and lettuce.',
    price: 15.99,
    discountPrice: 12.99,
    imageUrl: '',
    additionalImages: [],
    isInStock: true,
    stockQuantity: 50,
    categories: ['Vegetables', 'Organic'],
    rating: 4.5,
    reviewCount: 128,
    brand: 'Farm Fresh',
    dateAdded: DateTime.now().subtract(const Duration(days: 7)),
    attributes: {
      'organic': true,
      'source': 'Local Farm',
      'packaging': 'Eco-friendly',
    },
  ),
  Product(
    id: '2',
    name: 'Fresh Fruits Basket',
    description: 'Assorted fresh fruits including apples, oranges, and bananas.',
    price: 25.99,
    discountPrice: 22.99,
    imageUrl: '',
    additionalImages: [],
    isInStock: true,
    stockQuantity: 30,
    categories: ['Fruits', 'Fresh'],
    rating: 4.8,
    reviewCount: 95,
    brand: 'Nature\'s Best',
    dateAdded: DateTime.now().subtract(const Duration(days: 5)),
    attributes: {
      'organic': true,
      'source': 'Local Orchard',
      'packaging': 'Recyclable',
    },
  ),
  Product(
    id: '3',
    name: 'Fresh Vegetables Mix',
    description: 'A mix of fresh vegetables including carrots, tomatoes, and lettuce.',
    price: 12.99,
    discountPrice: 10.99,
    imageUrl: '',
    additionalImages: [],
    isInStock: true,
    stockQuantity: 40,
    categories: ['Vegetables', 'Fresh'],
    rating: 4.3,
    reviewCount: 75,
    brand: 'Garden Fresh',
    dateAdded: DateTime.now().subtract(const Duration(days: 3)),
    attributes: {
      'organic': true,
      'source': 'Local Farm',
      'packaging': 'Eco-friendly',
    },
  ),
  Product(
    id: '4',
    name: 'Organic Apples',
    description: 'Sweet and crispy organic apples.',
    price: 8.99,
    discountPrice: 7.99,
    imageUrl: '',
    additionalImages: [],
    isInStock: true,
    stockQuantity: 60,
    categories: ['Fruits', 'Organic'],
    rating: 4.7,
    reviewCount: 110,
    brand: 'Orchard Fresh',
    dateAdded: DateTime.now().subtract(const Duration(days: 2)),
    attributes: {
      'organic': true,
      'source': 'Local Orchard',
      'packaging': 'Recyclable',
    },
  ),
  Product(
    id: '5',
    name: 'Fresh Berries Mix',
    description: 'A mix of fresh berries including strawberries, blueberries, and raspberries.',
    price: 15.99,
    discountPrice: 13.99,
    imageUrl: '',
    additionalImages: [],
    isInStock: true,
    stockQuantity: 25,
    categories: ['Fruits', 'Berries'],
    rating: 4.9,
    reviewCount: 85,
    brand: 'Berry Fresh',
    dateAdded: DateTime.now().subtract(const Duration(days: 1)),
    attributes: {
      'organic': true,
      'source': 'Local Farm',
      'packaging': 'Eco-friendly',
    },
  ),
  Product(
    id: '6',
    name: 'Fresh Herbs Bundle',
    description: 'A bundle of fresh herbs including basil, parsley, and mint.',
    price: 6.99,
    discountPrice: 5.99,
    imageUrl: '',
    additionalImages: [],
    isInStock: true,
    stockQuantity: 35,
    categories: ['Herbs', 'Fresh'],
    rating: 4.4,
    reviewCount: 65,
    brand: 'Herb Garden',
    dateAdded: DateTime.now().subtract(const Duration(days: 4)),
    attributes: {
      'organic': true,
      'source': 'Local Farm',
      'packaging': 'Eco-friendly',
    },
  ),
  Product(
    id: '7',
    name: 'Fresh Citrus Mix',
    description: 'A mix of fresh citrus fruits including oranges, lemons, and limes.',
    price: 10.99,
    discountPrice: 9.99,
    imageUrl: '',
    additionalImages: [],
    isInStock: true,
    stockQuantity: 45,
    categories: ['Fruits', 'Citrus'],
    rating: 4.6,
    reviewCount: 95,
    brand: 'Citrus Fresh',
    dateAdded: DateTime.now().subtract(const Duration(days: 6)),
    attributes: {
      'organic': true,
      'source': 'Local Orchard',
      'packaging': 'Recyclable',
    },
  ),
  Product(
    id: '8',
    name: 'Fresh Mushrooms',
    description: 'A variety of fresh mushrooms.',
    price: 7.99,
    discountPrice: 6.99,
    imageUrl: '',
    additionalImages: [],
    isInStock: true,
    stockQuantity: 30,
    categories: ['Vegetables', 'Mushrooms'],
    rating: 4.2,
    reviewCount: 55,
    brand: 'Mushroom Farm',
    dateAdded: DateTime.now().subtract(const Duration(days: 5)),
    attributes: {
      'organic': true,
      'source': 'Local Farm',
      'packaging': 'Eco-friendly',
    },
  ),
  Product(
    id: '9',
    name: 'Fresh Root Vegetables',
    description: 'A mix of fresh root vegetables including carrots, potatoes, and onions.',
    price: 9.99,
    discountPrice: 8.99,
    imageUrl: '',
    additionalImages: [],
    isInStock: true,
    stockQuantity: 55,
    categories: ['Vegetables', 'Root Vegetables'],
    rating: 4.4,
    reviewCount: 70,
    brand: 'Farm Fresh',
    dateAdded: DateTime.now().subtract(const Duration(days: 8)),
    attributes: {
      'organic': true,
      'source': 'Local Farm',
      'packaging': 'Eco-friendly',
    },
  ),
  Product(
    id: '10',
    name: 'Fresh Leafy Greens',
    description: 'A mix of fresh leafy greens including spinach, kale, and lettuce.',
    price: 7.99,
    discountPrice: 6.99,
    imageUrl: '',
    additionalImages: [],
    isInStock: true,
    stockQuantity: 45,
    categories: ['Vegetables', 'Leafy Greens'],
    rating: 4.5,
    reviewCount: 80,
    brand: 'Garden Fresh',
    dateAdded: DateTime.now().subtract(const Duration(days: 7)),
    attributes: {
      'organic': true,
      'source': 'Local Farm',
      'packaging': 'Eco-friendly',
    },
  ),
];

/// Get all unique product categories
List<String> get productCategories {
  final categories = mockProducts
      .expand((product) => product.categories)
      .toSet()
      .toList();
  categories.sort();
  return categories;
}

/// Get products by category
List<Product> getProductsByCategory(String category) {
  return mockProducts
      .where((product) => product.categories.contains(category))
      .toList();
}

/// Get featured products (e.g., highest rated)
List<Product> get featuredProducts {
  return List<Product>.from(mockProducts)
    ..sort((a, b) => b.rating.compareTo(a.rating));
}

/// Get discounted products
List<Product> get discountedProducts {
  return mockProducts.where((product) => product.isOnSale).toList();
}

/// Get new arrivals (most recently added)
List<Product> get newArrivals {
  return List<Product>.from(mockProducts)
    ..sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
} 