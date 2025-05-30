import 'package:dayliz_app/domain/entities/product.dart';

/// A collection of mock products for testing the product card implementation
class MockProducts {
  /// Get a list of 5 mock products
  static List<Product> getMockProducts() {
    return [
      // 1. Fresh Milk with discount
      Product(
        id: 'milk-001',
        name: 'Fresh Farm Milk',
        description: 'Pure and fresh cow milk from local farms',
        price: 60.0,
        discountPercentage: 15,
        rating: 4.5,
        reviewCount: 128,
        mainImageUrl: 'https://images.unsplash.com/photo-1563636619-e9143da7973b?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTJ8fG1pbGt8ZW58MHx8MHx8fDA%3D&auto=format&fit=crop&w=500&q=60',
        additionalImages: [],
        inStock: true,
        stockQuantity: 50,
        categoryId: 'dairy',
        subcategoryId: 'milk',
        brand: 'Farm Fresh',
        attributes: {
          'volume': '500ml',
          'fat': '3.5%',
          'organic': true,
        },
        tags: ['dairy', 'fresh', 'organic'],
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        updatedAt: DateTime.now(),
        onSale: true,
      ),
      
      // 2. Organic Bananas (no discount)
      Product(
        id: 'banana-001',
        name: 'Organic Bananas',
        description: 'Sweet and ripe organic bananas',
        price: 40.0,
        discountPercentage: null,
        rating: 4.2,
        reviewCount: 95,
        mainImageUrl: 'https://images.unsplash.com/photo-1603833665858-e61d17a86224?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8YmFuYW5hfGVufDB8fDB8fHww&auto=format&fit=crop&w=500&q=60',
        additionalImages: [],
        inStock: true,
        stockQuantity: 100,
        categoryId: 'fruits',
        subcategoryId: 'tropical-fruits',
        brand: 'Organic Farms',
        attributes: {
          'weight': '500g',
          'organic': true,
          'origin': 'Kerala',
        },
        tags: ['fruits', 'organic', 'fresh'],
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now(),
        onSale: false,
      ),
      
      // 3. Basmati Rice with high discount
      Product(
        id: 'rice-001',
        name: 'Premium Basmati Rice',
        description: 'Aromatic long-grain basmati rice from the foothills of Himalayas',
        price: 250.0,
        discountPercentage: 25,
        rating: 4.8,
        reviewCount: 210,
        mainImageUrl: 'https://images.unsplash.com/photo-1586201375761-83865001e31c?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8NHx8cmljZXxlbnwwfHwwfHx8MA%3D%3D&auto=format&fit=crop&w=500&q=60',
        additionalImages: [],
        inStock: true,
        stockQuantity: 75,
        categoryId: 'grains',
        subcategoryId: 'rice',
        brand: 'Himalayan Harvest',
        attributes: {
          'weight': '1kg',
          'type': 'Basmati',
          'aged': '2 years',
        },
        tags: ['grains', 'rice', 'premium'],
        createdAt: DateTime.now().subtract(const Duration(days: 14)),
        updatedAt: DateTime.now(),
        onSale: true,
      ),
      
      // 4. Olive Oil (premium product)
      Product(
        id: 'oil-001',
        name: 'Extra Virgin Olive Oil',
        description: 'Cold-pressed extra virgin olive oil from Mediterranean olives',
        price: 450.0,
        discountPercentage: 10,
        rating: 4.9,
        reviewCount: 156,
        mainImageUrl: 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8b2xpdmUlMjBvaWx8ZW58MHx8MHx8fDA%3D&auto=format&fit=crop&w=500&q=60',
        additionalImages: [],
        inStock: true,
        stockQuantity: 30,
        categoryId: 'cooking-essentials',
        subcategoryId: 'oils',
        brand: 'Mediterranean Gold',
        attributes: {
          'volume': '1L',
          'type': 'Extra Virgin',
          'acidity': '0.3%',
        },
        tags: ['oil', 'premium', 'cooking'],
        createdAt: DateTime.now().subtract(const Duration(days: 21)),
        updatedAt: DateTime.now(),
        onSale: true,
      ),
      
      // 5. Chocolate Cookies (out of stock)
      Product(
        id: 'cookies-001',
        name: 'Chocolate Chip Cookies',
        description: 'Freshly baked chocolate chip cookies with premium Belgian chocolate',
        price: 120.0,
        discountPercentage: null,
        rating: 4.7,
        reviewCount: 89,
        mainImageUrl: 'https://images.unsplash.com/photo-1499636136210-6f4ee915583e?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8Y2hvY29sYXRlJTIwY29va2llc3xlbnwwfHwwfHx8MA%3D%3D&auto=format&fit=crop&w=500&q=60',
        additionalImages: [],
        inStock: false, // Out of stock
        stockQuantity: 0,
        categoryId: 'bakery',
        subcategoryId: 'cookies',
        brand: 'Sweet Delights',
        attributes: {
          'weight': '250g',
          'contains': 'Wheat, Eggs, Milk',
          'shelf_life': '7 days',
        },
        tags: ['bakery', 'cookies', 'chocolate'],
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now(),
        onSale: false,
      ),
    ];
  }
}
