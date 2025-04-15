import 'package:dayliz_app/models/product.dart';

/// Mock products for testing and development
final List<Product> mockProducts = [
  Product(
    id: '1',
    name: 'Organic Bananas',
    description: 'Fresh organic bananas, perfect for smoothies or a quick snack. Farm-fresh and sustainably grown.',
    price: 2.99,
    discountedPrice: 2.49,
    imageUrl: 'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e',
    isInStock: true,
    stockQuantity: 100,
    categories: ['Fruits', 'Organic'],
    rating: 4.5,
    reviewCount: 128,
    brand: 'Organic Farms',
    dateAdded: DateTime.now().subtract(const Duration(days: 10)),
    attributes: {
      'weight': '1kg',
      'origin': 'Ecuador',
      'organic': true,
    },
  ),
  Product(
    id: '2',
    name: 'Fresh Avocados',
    description: 'Perfectly ripe avocados ready to eat. Rich in healthy fats and perfect for guacamole or toast.',
    price: 3.99,
    imageUrl: 'https://images.unsplash.com/photo-1601039641847-7857b994d704',
    isInStock: true,
    stockQuantity: 50,
    categories: ['Fruits', 'Organic'],
    rating: 4.2,
    reviewCount: 95,
    brand: 'Green Valley',
    dateAdded: DateTime.now().subtract(const Duration(days: 5)),
    attributes: {
      'weight': '300g each',
      'origin': 'Mexico',
      'organic': true,
    },
  ),
  Product(
    id: '3',
    name: 'Whole Grain Bread',
    description: 'Freshly baked whole grain bread made with organic flour and seeds. No preservatives added.',
    price: 4.49,
    discountedPrice: 3.99,
    imageUrl: 'https://images.unsplash.com/photo-1598373182133-52452f7691ef',
    isInStock: true,
    stockQuantity: 20,
    categories: ['Bakery', 'Organic', 'Bread'],
    rating: 4.8,
    reviewCount: 213,
    brand: 'Artisan Bakery',
    dateAdded: DateTime.now().subtract(const Duration(days: 2)),
    attributes: {
      'weight': '500g',
      'ingredients': 'Whole grain flour, water, yeast, seeds, salt',
      'gluten-free': false,
    },
  ),
  Product(
    id: '4',
    name: 'Organic Milk',
    description: 'Fresh organic whole milk from grass-fed cows. Rich in calcium and vitamins.',
    price: 3.29,
    imageUrl: 'https://images.unsplash.com/photo-1550583724-b2692b85b150',
    isInStock: true,
    stockQuantity: 30,
    categories: ['Dairy', 'Organic', 'Beverages'],
    rating: 4.4,
    reviewCount: 167,
    brand: 'Happy Cow',
    dateAdded: DateTime.now().subtract(const Duration(days: 3)),
    attributes: {
      'volume': '1L',
      'fat-content': '3.5%',
      'pasteurized': true,
    },
  ),
  Product(
    id: '5',
    name: 'Free-Range Eggs',
    description: 'Farm-fresh free-range eggs from hens raised in open spaces with organic feed.',
    price: 5.99,
    discountedPrice: 4.99,
    imageUrl: 'https://images.unsplash.com/photo-1598965675045-45c5e72c7d05',
    isInStock: true,
    stockQuantity: 40,
    categories: ['Dairy', 'Organic', 'Protein'],
    rating: 4.9,
    reviewCount: 302,
    brand: 'Happy Hen',
    dateAdded: DateTime.now().subtract(const Duration(days: 7)),
    attributes: {
      'quantity': '12 eggs',
      'size': 'Large',
      'free-range': true,
    },
  ),
  Product(
    id: '6',
    name: 'Organic Spinach',
    description: 'Fresh organic spinach leaves, washed and ready to eat. Perfect for salads and cooking.',
    price: 2.49,
    imageUrl: 'https://images.unsplash.com/photo-1576045057995-568f588f82fb',
    isInStock: true,
    stockQuantity: 25,
    categories: ['Vegetables', 'Organic', 'Leafy Greens'],
    rating: 4.3,
    reviewCount: 87,
    brand: 'Green Earth',
    dateAdded: DateTime.now().subtract(const Duration(days: 4)),
    attributes: {
      'weight': '250g',
      'pre-washed': true,
      'organic': true,
    },
  ),
  Product(
    id: '7',
    name: 'Grass-Fed Beef',
    description: 'Premium grass-fed beef from pasture-raised cattle. No hormones or antibiotics used.',
    price: 15.99,
    discountedPrice: 14.49,
    imageUrl: 'https://images.unsplash.com/photo-1588168333986-5078d3ae3976',
    isInStock: true,
    stockQuantity: 15,
    categories: ['Meat', 'Protein', 'Organic'],
    rating: 4.7,
    reviewCount: 156,
    brand: 'Green Pastures',
    dateAdded: DateTime.now().subtract(const Duration(days: 6)),
    attributes: {
      'weight': '500g',
      'grass-fed': true,
      'cuts': 'Variety',
    },
  ),
  Product(
    id: '8',
    name: 'Organic Quinoa',
    description: 'Organic white quinoa, a complete protein source rich in nutrients and fiber.',
    price: 6.99,
    imageUrl: 'https://images.unsplash.com/photo-1586201375761-83865001e8ac',
    isInStock: true,
    stockQuantity: 60,
    categories: ['Grains', 'Organic', 'Protein'],
    rating: 4.6,
    reviewCount: 124,
    brand: 'Earth Harvest',
    dateAdded: DateTime.now().subtract(const Duration(days: 8)),
    attributes: {
      'weight': '500g',
      'gluten-free': true,
      'cooking-time': '15-20 minutes',
    },
  ),
  Product(
    id: '9',
    name: 'Wild Caught Salmon',
    description: 'Premium wild-caught salmon fillets, rich in omega-3 fatty acids and protein.',
    price: 19.99,
    discountedPrice: 17.99,
    imageUrl: 'https://images.unsplash.com/photo-1599084993091-1cb5c0721cc6',
    isInStock: true,
    stockQuantity: 10,
    categories: ['Seafood', 'Protein', 'Fresh'],
    rating: 4.8,
    reviewCount: 215,
    brand: 'Ocean Fresh',
    dateAdded: DateTime.now().subtract(const Duration(days: 5)),
    attributes: {
      'weight': '300g',
      'wild-caught': true,
      'origin': 'Alaska',
    },
  ),
  Product(
    id: '10',
    name: 'Organic Honey',
    description: 'Pure organic raw honey, unpasteurized and unfiltered. Locally sourced from sustainable apiaries.',
    price: 8.99,
    imageUrl: 'https://images.unsplash.com/photo-1587049352851-8d4e89133924',
    isInStock: true,
    stockQuantity: 35,
    categories: ['Pantry', 'Organic', 'Sweeteners'],
    rating: 4.9,
    reviewCount: 278,
    brand: 'Bee Happy',
    dateAdded: DateTime.now().subtract(const Duration(days: 9)),
    attributes: {
      'weight': '500g',
      'raw': true,
      'flavor': 'Wildflower',
    },
  ),
];

/// Get all unique product categories
List<String> get productCategories {
  final Set<String> categories = {};
  for (final product in mockProducts) {
    if (product.categories != null) {
      categories.addAll(product.categories!);
    }
  }
  return categories.toList()..sort();
}

/// Get products by category
List<Product> getProductsByCategory(String category) {
  return mockProducts.where((product) => 
    product.categories != null && 
    product.categories!.contains(category)
  ).toList();
}

/// Get featured products (e.g., highest rated)
List<Product> get featuredProducts {
  return List.from(mockProducts)
    ..sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
}

/// Get discounted products
List<Product> get discountedProducts {
  return mockProducts.where((product) => product.hasDiscount).toList();
}

/// Get new arrivals (most recently added)
List<Product> get newArrivals {
  return List.from(mockProducts)
    ..sort((a, b) => (b.dateAdded ?? DateTime.now())
        .compareTo(a.dateAdded ?? DateTime.now()));
} 