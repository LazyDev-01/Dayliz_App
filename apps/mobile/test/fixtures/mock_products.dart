import '../../lib/domain/entities/product.dart';

/// Mock products data for testing and development
class MockProducts {
  /// Get a list of mock products for testing
  static List<Product> getMockProducts() {
    return [
      const Product(
        id: 'prod_001',
        name: 'Fresh Bananas',
        description: 'Fresh organic bananas from local farms. Rich in potassium and perfect for a healthy snack.',
        price: 2.99,
        retailPrice: 3.49,
        discountPercentage: 14.3,
        rating: 4.5,
        reviewCount: 128,
        mainImageUrl: 'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e',
        additionalImages: [
          'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e',
          'https://images.unsplash.com/photo-1528825871115-3581a5387919'
        ],
        inStock: true,
        stockQuantity: 150,
        categoryId: 'cat_fruits',
        subcategoryId: 'subcat_tropical',
        brand: 'Fresh Farm',
        weight: '1 kg',
        attributes: {
          'origin': 'Local Farm',
          'organic': true,
          'shelf_life': '5-7 days',
          'storage': 'Room temperature',
        },
        nutritionalInfo: {
          'calories': '89 per 100g',
          'carbohydrates': '23g',
          'fiber': '2.6g',
          'potassium': '358mg',
          'vitamin_c': '8.7mg',
        },
      ),
      const Product(
        id: 'prod_002',
        name: 'Organic Apples',
        description: 'Crisp and sweet organic apples. Perfect for snacking or baking.',
        price: 4.99,
        retailPrice: 5.99,
        discountPercentage: 16.7,
        rating: 4.7,
        reviewCount: 89,
        mainImageUrl: 'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6',
        additionalImages: [
          'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6',
          'https://images.unsplash.com/photo-1619546813926-a78fa6372cd2'
        ],
        inStock: true,
        stockQuantity: 75,
        categoryId: 'cat_fruits',
        subcategoryId: 'subcat_temperate',
        brand: 'Organic Valley',
        weight: '1 kg',
        attributes: {
          'origin': 'Kashmir',
          'organic': true,
          'variety': 'Red Delicious',
          'shelf_life': '2-3 weeks',
          'storage': 'Refrigerate',
        },
        nutritionalInfo: {
          'calories': '52 per 100g',
          'carbohydrates': '14g',
          'fiber': '2.4g',
          'vitamin_c': '4.6mg',
          'potassium': '107mg',
        },
      ),
      const Product(
        id: 'prod_003',
        name: 'Fresh Milk',
        description: 'Pure and fresh full-fat milk from local dairy farms.',
        price: 1.99,
        retailPrice: 2.29,
        discountPercentage: 13.1,
        rating: 4.3,
        reviewCount: 156,
        mainImageUrl: 'https://images.unsplash.com/photo-1550583724-b2692b85b150',
        additionalImages: [
          'https://images.unsplash.com/photo-1550583724-b2692b85b150',
          'https://images.unsplash.com/photo-1563636619-e9143da7973b'
        ],
        inStock: true,
        stockQuantity: 200,
        categoryId: 'cat_dairy',
        subcategoryId: 'subcat_milk',
        brand: 'Farm Fresh',
        weight: '1 liter',
        attributes: {
          'fat_content': '3.5%',
          'pasteurized': true,
          'source': 'Local Dairy',
          'shelf_life': '3-4 days',
          'storage': 'Refrigerate',
        },
        nutritionalInfo: {
          'calories': '42 per 100ml',
          'protein': '3.4g',
          'fat': '3.25g',
          'calcium': '113mg',
          'vitamin_d': '1.2mcg',
        },
      ),
      const Product(
        id: 'prod_004',
        name: 'Whole Wheat Bread',
        description: 'Freshly baked whole wheat bread with no preservatives.',
        price: 2.49,
        retailPrice: 2.99,
        discountPercentage: 16.7,
        rating: 4.4,
        reviewCount: 67,
        mainImageUrl: 'https://images.unsplash.com/photo-1509440159596-0249088772ff',
        additionalImages: [
          'https://images.unsplash.com/photo-1509440159596-0249088772ff',
          'https://images.unsplash.com/photo-1586444248902-2f64eddc13df'
        ],
        inStock: true,
        stockQuantity: 45,
        categoryId: 'cat_bakery',
        subcategoryId: 'subcat_bread',
        brand: 'Artisan Bakery',
        weight: '400g',
        attributes: {
          'whole_grain': true,
          'preservative_free': true,
          'fiber_rich': true,
          'shelf_life': '3-5 days',
          'storage': 'Room temperature',
        },
        nutritionalInfo: {
          'calories': '247 per 100g',
          'protein': '13g',
          'carbohydrates': '41g',
          'fiber': '7g',
          'iron': '3.6mg',
        },
      ),
      const Product(
        id: 'prod_005',
        name: 'Greek Yogurt',
        description: 'Thick and creamy Greek yogurt with live cultures.',
        price: 3.99,
        retailPrice: 4.49,
        discountPercentage: 11.1,
        rating: 4.6,
        reviewCount: 134,
        mainImageUrl: 'https://images.unsplash.com/photo-1488477181946-6428a0291777',
        additionalImages: [
          'https://images.unsplash.com/photo-1488477181946-6428a0291777',
          'https://images.unsplash.com/photo-1571212515416-fef01fc43637'
        ],
        inStock: true,
        stockQuantity: 88,
        categoryId: 'cat_dairy',
        subcategoryId: 'subcat_yogurt',
        brand: 'Mediterranean',
        weight: '500g',
        attributes: {
          'fat_content': '0%',
          'live_cultures': true,
          'protein_rich': true,
          'shelf_life': '7-10 days',
          'storage': 'Refrigerate',
        },
        nutritionalInfo: {
          'calories': '59 per 100g',
          'protein': '10g',
          'carbohydrates': '3.6g',
          'calcium': '110mg',
          'probiotics': 'Live cultures',
        },
      ),
    ];
  }

  /// Get mock products by category
  static List<Product> getMockProductsByCategory(String categoryId) {
    return getMockProducts().where((product) => product.categoryId == categoryId).toList();
  }

  /// Get a single mock product by ID
  static Product? getMockProductById(String productId) {
    try {
      return getMockProducts().firstWhere((product) => product.id == productId);
    } catch (e) {
      return null;
    }
  }

  /// Get mock featured products
  static List<Product> getMockFeaturedProducts() {
    return getMockProducts().take(3).toList();
  }

  /// Get mock products with low stock (for testing low stock scenarios)
  static List<Product> getMockLowStockProducts() {
    return [
      const Product(
        id: 'prod_low_001',
        name: 'Limited Edition Honey',
        description: 'Rare wildflower honey with limited availability.',
        price: 12.99,
        retailPrice: 15.99,
        discountPercentage: 18.8,
        rating: 4.8,
        reviewCount: 23,
        mainImageUrl: 'https://images.unsplash.com/photo-1587049352846-4a222e784d38',
        additionalImages: [
          'https://images.unsplash.com/photo-1587049352846-4a222e784d38'
        ],
        inStock: true,
        stockQuantity: 3, // Low stock
        categoryId: 'cat_pantry',
        subcategoryId: 'subcat_sweeteners',
        brand: 'Wild Harvest',
        weight: '250g',
        attributes: {
          'raw': true,
          'unfiltered': true,
          'limited_edition': true,
          'shelf_life': '2 years',
          'storage': 'Room temperature',
        },
        nutritionalInfo: {
          'calories': '304 per 100g',
          'carbohydrates': '82g',
          'sugars': '82g',
          'antioxidants': 'High',
        },
      ),
    ];
  }

  /// Get mock out of stock products (for testing out of stock scenarios)
  static List<Product> getMockOutOfStockProducts() {
    return [
      const Product(
        id: 'prod_oos_001',
        name: 'Premium Olive Oil',
        description: 'Extra virgin olive oil from Mediterranean olives.',
        price: 8.99,
        retailPrice: 10.99,
        discountPercentage: 18.2,
        rating: 4.9,
        reviewCount: 45,
        mainImageUrl: 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5',
        additionalImages: [
          'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5'
        ],
        inStock: false, // Out of stock
        stockQuantity: 0,
        categoryId: 'cat_pantry',
        subcategoryId: 'subcat_oils',
        brand: 'Mediterranean Gold',
        weight: '500ml',
        attributes: {
          'extra_virgin': true,
          'cold_pressed': true,
          'imported': true,
          'shelf_life': '18 months',
          'storage': 'Cool, dark place',
        },
        nutritionalInfo: {
          'calories': '884 per 100ml',
          'fat': '100g',
          'vitamin_e': '14.35mg',
          'antioxidants': 'High',
        },
      ),
    ];
  }
}
