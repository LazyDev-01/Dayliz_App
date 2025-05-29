import 'dart:developer';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:uuid/uuid.dart';

/// A service that handles seeding the database with sample data.
class DatabaseSeeder {
  static final DatabaseSeeder _instance = DatabaseSeeder._internal();
  static DatabaseSeeder get instance => _instance;
  
  late final SupabaseClient _client;
  
  /// Private constructor
  DatabaseSeeder._internal() {
    _client = Supabase.instance.client;
  }
  
  /// Clear existing data before seeding
  Future<void> clearExistingData({
    void Function(String message)? onLog,
    void Function(double progress)? onProgress,
  }) async {
    final logFn = onLog ?? log;
    final progressFn = onProgress ?? ((_) {});
    
    try {
      logFn('Starting data clearing process...');
      progressFn(0.1);
      
      // Delete product images first to prevent foreign key constraint errors
      logFn('Clearing product images...');
      await _client.from('product_images').delete().neq('id', '');
      logFn('✅ Product images cleared');
      progressFn(0.3);
      
      // Delete products
      logFn('Clearing products...');
      await _client.from('products').delete().neq('id', '');
      logFn('✅ Products cleared');
      progressFn(0.6);
      
      // Delete subcategories if table exists
      try {
        logFn('Clearing subcategories...');
        await _client.from('subcategories').delete().neq('id', '');
        logFn('✅ Subcategories cleared');
      } catch (e) {
        logFn('No subcategories table found to clear, skipping...');
      }
      progressFn(0.8);
      
      // Delete categories
      logFn('Clearing categories...');
      await _client.from('categories').delete().neq('id', '');
      logFn('✅ Categories cleared');
      progressFn(1.0);
      
      logFn('All existing data cleared successfully');
    } catch (e) {
      logFn('Error clearing data: $e');
      rethrow;
    }
  }
  
  /// Seed the database with initial data
  Future<void> seedDatabase({void Function(String message)? onLog}) async {
    try {
      final logFn = onLog ?? log;
      
      logFn('Seeding database with sample data...');
      
      // Test database connections
      await _testDatabaseConnections(logFn: logFn);
      
      // Seed categories
      await seedCategories(logFn: logFn);
      
      // Seed products
      await seedProducts(logFn: logFn);
      
      logFn('Database seeding completed successfully.');
    } catch (e) {
      final logFn = onLog ?? log;
      logFn('Error seeding database: $e');
      rethrow;
    }
  }
  
  /// Test database connections to make sure tables exist
  Future<void> _testDatabaseConnections({void Function(String message)? logFn}) async {
    final log = logFn ?? (String msg) => debugPrint(msg);
    
    log('Testing database connections...');
    
    try {
      log('Testing database connection to addresses table...');
      final addresses = await _client.from('addresses').select().limit(1);
      log('✅ Addresses table connected: ${addresses.length} records found');
    } catch (e) {
      log('❌ Error accessing addresses table: $e');
      
      // Try alternative table name (for backwards compatibility)
      try {
        final userAddresses = await _client.from('user_addresses').select().limit(1);
        log('✅ User addresses table connected: ${userAddresses.length} records found');
      } catch (e) {
        log('❌ Alternative address table also not found: $e');
        log('❌ Address table connection failed - check table name and permissions');
      }
    }

    // Check if subcategories table exists
    try {
      log('Testing database connection to subcategories table...');
      final subcategories = await _client.from('subcategories').select().limit(1);
      log('✅ Subcategories table connected: ${subcategories.length} records found');
    } catch (e) {
      log('❌ Error accessing subcategories table: $e');
      log('❌ Will attempt to create subcategories table during seeding');
    }
  }
  
  /// Create subcategories table if it doesn't exist
  Future<bool> _createSubcategoriesTable({void Function(String message)? logFn}) async {
    final log = logFn ?? (String msg) => debugPrint(msg);
    
    try {
      log('Creating subcategories table...');
      
      // Create SQL to create the table
      const sql = '''
      CREATE TABLE IF NOT EXISTS subcategories (
        id UUID PRIMARY KEY,
        name TEXT NOT NULL,
        category_id UUID REFERENCES categories(id) ON DELETE CASCADE,
        image_url TEXT,
        icon_name TEXT,
        is_active BOOLEAN DEFAULT true,
        display_order INTEGER DEFAULT 0,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
      );
      
      -- Enable RLS
      ALTER TABLE subcategories ENABLE ROW LEVEL SECURITY;
      
      -- Add read policy for all
      CREATE POLICY IF NOT EXISTS subcategories_read_all ON subcategories 
          FOR SELECT USING (true);
      ''';
      
      // Execute the SQL directly
      await _client.rpc('exec_sql', params: {'sql': sql});
      
      log('✅ Subcategories table created successfully');
      return true;
    } catch (e) {
      log('❌ Error creating subcategories table: $e');
      return false;
    }
  }
  
  /// Seed categories with sample data
  Future<void> seedCategories({void Function(String message)? logFn}) async {
    final log = logFn ?? (String msg) => debugPrint(msg);
    
    try {
      // Check if categories already exist
      final existingCategories = await _client.from('categories').select('id').limit(1);
      if (existingCategories.isNotEmpty) {
        log('Categories already exist, skipping seeding.');
        return;
      }
      
      // Check if subcategories table exists
      bool subcategoriesTableExists = false;
      try {
        await _client.from('subcategories').select().limit(1);
        subcategoriesTableExists = true;
      } catch (e) {
        log('❌ Subcategories table not found. Attempting to create it...');
        subcategoriesTableExists = await _createSubcategoriesTable(logFn: log);
        
        if (!subcategoriesTableExists) {
          log('❌ Failed to create subcategories table');
          log('Please manually create the subcategories table according to the schema');
          // Continue anyway, we'll add subcategories to categories table with parent_id
        }
      }
      
      log('Seeding categories table with sample data...');
      
      // Define top-level categories
      final topLevelCategories = [
        {
          'id': const Uuid().v4(),
          'name': 'Grocery & Kitchen',
          'icon_name': 'kitchen',
          'image_url': 'https://placehold.co/200/4CAF50/FFFFFF?text=Grocery',
          'is_active': true,
          'display_order': 1,
        },
        {
          'id': const Uuid().v4(),
          'name': 'Snacks & Beverages',
          'icon_name': 'fastfood',
          'image_url': 'https://placehold.co/200/FFC107/FFFFFF?text=Snacks',
          'is_active': true,
          'display_order': 2, 
        },
        {
          'id': const Uuid().v4(),
          'name': 'Beauty & Hygiene',
          'icon_name': 'spa',
          'image_url': 'https://placehold.co/200/E91E63/FFFFFF?text=Beauty',
          'is_active': true,
          'display_order': 3,
        },
        {
          'id': const Uuid().v4(),
          'name': 'Household & Essentials',
          'icon_name': 'home',
          'image_url': 'https://placehold.co/200/9C27B0/FFFFFF?text=Household',
          'is_active': true,
          'display_order': 4,
        },
      ];
      
      // Insert top-level categories
      final topLevelCategoryResults = await _client
          .from('categories')
          .insert(topLevelCategories)
          .select('id, name');
          
      log('✅ Added ${topLevelCategoryResults.length} top-level categories');
      
      // Map of category names to their IDs for subcategory creation
      final Map<String, String> categoryIds = {};
      for (var category in topLevelCategoryResults) {
        categoryIds[category['name']] = category['id'];
      }
      
      // Create subcategories
      final List<Map<String, dynamic>> subcategories = [];
      
      // Grocery & Kitchen subcategories
      if (categoryIds.containsKey('Grocery & Kitchen')) {
        final categoryId = categoryIds['Grocery & Kitchen'];
        subcategories.addAll([
          {
            'id': const Uuid().v4(),
            'name': 'Dairy, Bread & Eggs',
            'category_id': categoryId,
            'image_url': 'https://placehold.co/100/4CAF50/FFFFFF?text=Dairy',
            'icon_name': 'kitchen',
            'is_active': true,
            'display_order': 1,
          },
          {
            'id': const Uuid().v4(),
            'name': 'Atta, Rice & Dal',
            'category_id': categoryId,
            'image_url': 'https://placehold.co/100/4CAF50/FFFFFF?text=Rice',
            'icon_name': 'kitchen',
            'is_active': true,
            'display_order': 2,
          },
          {
            'id': const Uuid().v4(),
            'name': 'Vegetables & Fruits',
            'category_id': categoryId,
            'image_url': 'https://placehold.co/100/4CAF50/FFFFFF?text=Veggies',
            'icon_name': 'kitchen',
            'is_active': true,
            'display_order': 3,
          },
        ]);
      }
      
      // Snacks & Beverages subcategories
      if (categoryIds.containsKey('Snacks & Beverages')) {
        final categoryId = categoryIds['Snacks & Beverages'];
        subcategories.addAll([
          {
            'id': const Uuid().v4(),
            'name': 'Cookies & Biscuits',
            'category_id': categoryId,
            'image_url': 'https://placehold.co/100/FFC107/FFFFFF?text=Cookies',
            'icon_name': 'fastfood',
            'is_active': true,
            'display_order': 1,
          },
          {
            'id': const Uuid().v4(),
            'name': 'Cold Drinks & Juices',
            'category_id': categoryId,
            'image_url': 'https://placehold.co/100/FFC107/FFFFFF?text=Drinks',
            'icon_name': 'fastfood',
            'is_active': true,
            'display_order': 2,
          },
        ]);
      }
      
      // Beauty & Hygiene subcategories
      if (categoryIds.containsKey('Beauty & Hygiene')) {
        final categoryId = categoryIds['Beauty & Hygiene'];
        subcategories.addAll([
          {
            'id': const Uuid().v4(),
            'name': 'Skin & Face Care',
            'category_id': categoryId,
            'image_url': 'https://placehold.co/100/E91E63/FFFFFF?text=Skin',
            'icon_name': 'spa',
            'is_active': true,
            'display_order': 1,
          },
          {
            'id': const Uuid().v4(),
            'name': 'Hair Care',
            'category_id': categoryId,
            'image_url': 'https://placehold.co/100/E91E63/FFFFFF?text=Hair',
            'icon_name': 'spa',
            'is_active': true,
            'display_order': 2,
          },
        ]);
      }
      
      // Household subcategories
      if (categoryIds.containsKey('Household & Essentials')) {
        final categoryId = categoryIds['Household & Essentials'];
        subcategories.addAll([
          {
            'id': const Uuid().v4(),
            'name': 'Cleaning Supplies',
            'category_id': categoryId,
            'image_url': 'https://placehold.co/100/9C27B0/FFFFFF?text=Clean',
            'icon_name': 'home',
            'is_active': true,
            'display_order': 1,
          },
          {
            'id': const Uuid().v4(),
            'name': 'Kitchen Accessories',
            'category_id': categoryId,
            'image_url': 'https://placehold.co/100/9C27B0/FFFFFF?text=Kitchen',
            'icon_name': 'home',
            'is_active': true,
            'display_order': 2,
          },
        ]);
      }
      
      // Insert all subcategories
      if (subcategoriesTableExists) {
        // Insert into subcategories table
        final subcategoryResults = await _client
            .from('subcategories')
            .insert(subcategories)
            .select('id');
            
        log('✅ Added ${subcategoryResults.length} subcategories to subcategories table');
      } else {
        // Fall back to inserting into categories table with parent_id
        // Convert to parent_id format
        final List<Map<String, dynamic>> categoriesWithParent = subcategories.map((sub) {
          return {
            'id': sub['id'],
            'name': sub['name'],
            'parent_id': sub['category_id'],
            'image_url': sub['image_url'],
            'icon': sub['icon_name'],
            'is_active': sub['is_active'],
            'display_order': sub['display_order'],
          };
        }).toList();
        
        final subcategoryResults = await _client
            .from('categories')
            .insert(categoriesWithParent)
            .select('id');
            
        log('✅ Added ${subcategoryResults.length} subcategories to categories table using parent_id');
      }
      
    } catch (e) {
      log('Error seeding categories: $e');
    }
  }
  
  /// Seed products with sample data
  Future<void> seedProducts({void Function(String message)? logFn}) async {
    final log = logFn ?? (String msg) => debugPrint(msg);
    
    try {
      // Check if products already exist
      final existingProducts = await _client.from('products').select('id').limit(1);
      if (existingProducts.isNotEmpty) {
        log('Products already exist, skipping seeding.');
        return;
      }
      
      log('Seeding products table with sample data...');
      
      // Get category IDs
      final categories = await _client.from('categories').select('id, name');
      final Map<String, String> categoryIds = {};
      for (var category in categories) {
        categoryIds[category['name']] = category['id'];
      }
      
      // Get subcategory IDs
      Map<String, String> subcategoryIds = {};
      try {
        final subcategories = await _client.from('subcategories').select('id, name');
        for (var subcategory in subcategories) {
          subcategoryIds[subcategory['name']] = subcategory['id'];
        }
      } catch (e) {
        log('Warning: Could not fetch subcategories: $e');
        log('Continuing with category-only products');
      }
      
      // Check if product_variants table exists
      bool hasVariantsSupport = false;
      try {
        await _client.from('product_variants').select().limit(1);
        hasVariantsSupport = true;
        log('✅ Product variants table detected, will add variant support');
      } catch (e) {
        log('Product variants table not found, skipping variant creation');
      }
      
      // Create enhanced sample products
      final List<Map<String, dynamic>> products = _getEnhancedProductList(
        categoryIds: categoryIds,
        subcategoryIds: subcategoryIds,
      );
      
      // Insert products
      int successCount = 0;
      for (var product in products) {
        try {
          final result = await _client.from('products').insert(product).select('id, name');
          
          if (result.isNotEmpty) {
            final productId = result[0]['id'];
            final productName = result[0]['name'];
            
            // Add multiple product images if applicable
            await _addProductImages(productId, productName, product['category_id']);
            
            // Add variants if supported
            if (hasVariantsSupport && product.containsKey('has_variants') && product['has_variants'] == true) {
              await _addProductVariants(productId, productName);
            }
            
            successCount++;
            log('✅ Added product: $productName with images' + 
                (hasVariantsSupport && product.containsKey('has_variants') && product['has_variants'] ? ' and variants' : ''));
          }
        } catch (e) {
          log('❌ Error adding product ${product['name']}: $e');
        }
      }
      
      log('✅ Product seeding completed: $successCount products added');
      
    } catch (e) {
      log('Error seeding products: $e');
    }
  }
  
  /// Add multiple product images to a product
  Future<void> _addProductImages(String productId, String productName, String categoryId) async {
    // Get a color based on category ID
    final String colorHex = categoryId.hashCode.toString().substring(0, 6).padLeft(6, '0');
    
    // Add primary image
    await _client.from('product_images').insert({
      'id': const Uuid().v4(),
      'product_id': productId,
      'image_url': 'https://placehold.co/600x400/$colorHex/FFFFFF?text=${Uri.encodeComponent(productName)}',
      'is_primary': true,
      'alt_text': productName,
      'display_order': 0
    });
    
    // Add secondary images
    for (int i = 1; i <= 3; i++) {
      await _client.from('product_images').insert({
        'id': const Uuid().v4(),
        'product_id': productId,
        'image_url': 'https://placehold.co/600x400/$colorHex/FFFFFF?text=${Uri.encodeComponent("$productName $i")}',
        'is_primary': false,
        'alt_text': '$productName - Image $i',
        'display_order': i
      });
    }
  }
  
  /// Add variants to a product
  Future<void> _addProductVariants(String productId, String productName) async {
    // Create different variant types based on product name
    List<Map<String, dynamic>> variants = [];
    
    if (productName.toLowerCase().contains('shirt') || 
        productName.toLowerCase().contains('t-shirt') ||
        productName.toLowerCase().contains('clothing')) {
      // Size variants for clothing
      variants = [
        {'name': 'Size', 'value': 'S', 'price_modifier': 0, 'stock': 15},
        {'name': 'Size', 'value': 'M', 'price_modifier': 0, 'stock': 25},
        {'name': 'Size', 'value': 'L', 'price_modifier': 0, 'stock': 20},
        {'name': 'Size', 'value': 'XL', 'price_modifier': 10, 'stock': 10},
      ];
    } else if (productName.toLowerCase().contains('juice') || 
               productName.toLowerCase().contains('beverage') ||
               productName.toLowerCase().contains('drink')) {
      // Size variants for beverages
      variants = [
        {'name': 'Size', 'value': '250ml', 'price_modifier': 0, 'stock': 25},
        {'name': 'Size', 'value': '500ml', 'price_modifier': 30, 'stock': 15},
        {'name': 'Size', 'value': '1L', 'price_modifier': 70, 'stock': 10},
      ];
    } else {
      // Default variants (Color)
      variants = [
        {'name': 'Color', 'value': 'Red', 'price_modifier': 0, 'stock': 10},
        {'name': 'Color', 'value': 'Blue', 'price_modifier': 0, 'stock': 15},
        {'name': 'Color', 'value': 'Green', 'price_modifier': 0, 'stock': 8},
        {'name': 'Color', 'value': 'Black', 'price_modifier': 10, 'stock': 20},
      ];
    }
    
    // Insert the variants
    for (var variant in variants) {
      await _client.from('product_variants').insert({
        'id': const Uuid().v4(),
        'product_id': productId,
        'variant_name': variant['name'],
        'variant_value': variant['value'],
        'price_modifier': variant['price_modifier'],
        'stock_quantity': variant['stock'],
        'is_active': true,
      });
    }
  }
  
  /// Get a list of enhanced products
  List<Map<String, dynamic>> _getEnhancedProductList({
    required Map<String, String> categoryIds,
    required Map<String, String> subcategoryIds,
  }) {
    return [
      // Grocery & Kitchen > Vegetables & Fruits
      {
        'id': const Uuid().v4(),
        'name': 'Organic Bananas',
        'slug': 'organic-bananas',
        'description': 'Sweet and nutritious organic bananas, perfect for a healthy snack. Sourced from organic farms with sustainable farming practices.',
        'short_description': 'Organic bananas for a healthy snack',
        'price': 79.99,
        'discount_price': 64.99,
        'stock_quantity': 100,
        'category_id': categoryIds['Grocery & Kitchen'],
        'subcategory_id': subcategoryIds['Vegetables & Fruits'],
        'is_featured': true,
        'is_active': true,
        'brand': 'OrganicFarms',
        'tags': ['organic', 'fruit', 'healthy'],
        'has_variants': false,
      },
      {
        'id': const Uuid().v4(),
        'name': 'Fresh Red Apples',
        'slug': 'fresh-red-apples',
        'description': 'Crisp, juicy red apples sourced from local orchards. Perfect for snacking, baking, or adding to salads.',
        'short_description': 'Crisp and juicy red apples',
        'price': 149.99,
        'stock_quantity': 80,
        'category_id': categoryIds['Grocery & Kitchen'],
        'subcategory_id': subcategoryIds['Vegetables & Fruits'],
        'is_featured': true,
        'is_active': true,
        'brand': 'FreshHarvest',
        'tags': ['fruit', 'fresh', 'apple'],
        'has_variants': false,
      },
      
      // Grocery & Kitchen > Dairy, Bread & Eggs
      {
        'id': const Uuid().v4(),
        'name': 'Whole Wheat Bread',
        'slug': 'whole-wheat-bread',
        'description': 'Freshly baked whole wheat bread made with premium quality ingredients. Rich in fiber and perfect for healthy sandwiches.',
        'short_description': 'Nutritious whole wheat bread',
        'price': 89.99,
        'stock_quantity': 50,
        'category_id': categoryIds['Grocery & Kitchen'],
        'subcategory_id': subcategoryIds['Dairy, Bread & Eggs'],
        'is_featured': false,
        'is_active': true,
        'brand': 'HealthyBake',
        'tags': ['bread', 'whole wheat', 'bakery'],
        'has_variants': false,
      },
      {
        'id': const Uuid().v4(),
        'name': 'Farm Fresh Eggs',
        'slug': 'farm-fresh-eggs',
        'description': 'Premium quality eggs from free-range chickens. Rich in nutrients and perfect for breakfast or baking.',
        'short_description': 'Free-range chicken eggs',
        'price': 129.99,
        'discount_price': 99.99,
        'stock_quantity': 60,
        'category_id': categoryIds['Grocery & Kitchen'],
        'subcategory_id': subcategoryIds['Dairy, Bread & Eggs'],
        'is_featured': true,
        'is_active': true,
        'brand': 'FarmFresh',
        'tags': ['eggs', 'protein', 'dairy'],
        'has_variants': true,
      },
      
      // Snacks & Beverages > Cookies & Biscuits
      {
        'id': const Uuid().v4(),
        'name': 'Chocolate Chip Cookies',
        'slug': 'chocolate-chip-cookies',
        'description': 'Delicious chocolate chip cookies made with real chocolate chunks and a hint of vanilla. Perfect with milk or coffee.',
        'short_description': 'Classic chocolate chip cookies',
        'price': 149.99,
        'discount_price': 119.99,
        'stock_quantity': 80,
        'category_id': categoryIds['Snacks & Beverages'],
        'subcategory_id': subcategoryIds['Cookies & Biscuits'],
        'is_featured': true,
        'is_active': true,
        'brand': 'SweetTreats',
        'tags': ['snacks', 'cookies', 'chocolate'],
        'has_variants': true,
      },
      {
        'id': const Uuid().v4(),
        'name': 'Butter Cookies Assortment',
        'slug': 'butter-cookies-assortment',
        'description': 'An assortment of premium butter cookies in various shapes and flavors. Made with real butter for a rich taste.',
        'short_description': 'Premium butter cookies assortment',
        'price': 199.99,
        'stock_quantity': 40,
        'category_id': categoryIds['Snacks & Beverages'],
        'subcategory_id': subcategoryIds['Cookies & Biscuits'],
        'is_featured': false,
        'is_active': true,
        'brand': 'DelightBakery',
        'tags': ['snacks', 'cookies', 'butter', 'assortment'],
        'has_variants': false,
      },
      
      // Snacks & Beverages > Cold Drinks & Juices
      {
        'id': const Uuid().v4(),
        'name': 'Fresh Orange Juice',
        'slug': 'fresh-orange-juice',
        'description': 'Pure, freshly squeezed orange juice with no added sugar or preservatives. Rich in vitamin C and perfect for breakfast.',
        'short_description': 'Freshly squeezed orange juice',
        'price': 159.99,
        'stock_quantity': 30,
        'category_id': categoryIds['Snacks & Beverages'],
        'subcategory_id': subcategoryIds['Cold Drinks & Juices'],
        'is_featured': true,
        'is_active': true,
        'brand': 'FreshSqueeze',
        'tags': ['beverages', 'juice', 'healthy', 'orange'],
        'has_variants': true,
      },
      {
        'id': const Uuid().v4(),
        'name': 'Sparkling Water Variety Pack',
        'slug': 'sparkling-water-variety-pack',
        'description': 'Refreshing sparkling water in various natural flavors. Zero calories, zero sugar, and zero artificial ingredients.',
        'short_description': 'Zero-calorie flavored sparkling water',
        'price': 299.99,
        'discount_price': 249.99,
        'stock_quantity': 25,
        'category_id': categoryIds['Snacks & Beverages'],
        'subcategory_id': subcategoryIds['Cold Drinks & Juices'],
        'is_featured': false,
        'is_active': true,
        'brand': 'BubblySip',
        'tags': ['beverages', 'sparkling', 'healthy', 'water'],
        'has_variants': true,
      },
      
      // Beauty & Hygiene > Skin & Face Care
      {
        'id': const Uuid().v4(),
        'name': 'Hydrating Face Moisturizer',
        'slug': 'hydrating-face-moisturizer',
        'description': 'Deeply hydrating face moisturizer with hyaluronic acid and vitamin E. Suitable for all skin types and provides 24-hour hydration.',
        'short_description': 'All-day hydration for all skin types',
        'price': 499.99,
        'discount_price': 399.99,
        'stock_quantity': 35,
        'category_id': categoryIds['Beauty & Hygiene'],
        'subcategory_id': subcategoryIds['Skin & Face Care'],
        'is_featured': true,
        'is_active': true,
        'brand': 'GlowEssentials',
        'tags': ['skincare', 'moisturizer', 'face', 'hydration'],
        'has_variants': false,
      },
      {
        'id': const Uuid().v4(),
        'name': 'Natural Face Wash',
        'slug': 'natural-face-wash',
        'description': 'Gentle face wash made with natural ingredients. Removes impurities without stripping skin of its natural oils.',
        'short_description': 'Gentle, natural face cleanser',
        'price': 349.99,
        'stock_quantity': 45,
        'category_id': categoryIds['Beauty & Hygiene'],
        'subcategory_id': subcategoryIds['Skin & Face Care'],
        'is_featured': false,
        'is_active': true,
        'brand': 'PureNaturals',
        'tags': ['skincare', 'face wash', 'natural', 'cleanser'],
        'has_variants': true,
      },
      
      // Beauty & Hygiene > Hair Care
      {
        'id': const Uuid().v4(),
        'name': 'Anti-Dandruff Shampoo',
        'slug': 'anti-dandruff-shampoo',
        'description': 'Effective anti-dandruff shampoo that soothes the scalp and eliminates flakes. Enriched with tea tree oil and zinc pyrithione.',
        'short_description': 'Soothes scalp and eliminates dandruff',
        'price': 399.99,
        'stock_quantity': 40,
        'category_id': categoryIds['Beauty & Hygiene'],
        'subcategory_id': subcategoryIds['Hair Care'],
        'is_featured': true,
        'is_active': true,
        'brand': 'ScalpCare',
        'tags': ['haircare', 'shampoo', 'anti-dandruff', 'scalp'],
        'has_variants': true,
      },
      
      // Household & Essentials > Cleaning Supplies
      {
        'id': const Uuid().v4(),
        'name': 'All-Purpose Cleaner',
        'slug': 'all-purpose-cleaner',
        'description': 'Powerful all-purpose cleaner that tackles dirt, grease, and grime on multiple surfaces. Pleasant citrus scent.',
        'short_description': 'Multi-surface cleaner with citrus scent',
        'price': 249.99,
        'discount_price': 199.99,
        'stock_quantity': 55,
        'category_id': categoryIds['Household & Essentials'],
        'subcategory_id': subcategoryIds['Cleaning Supplies'],
        'is_featured': false,
        'is_active': true,
        'brand': 'CleanPro',
        'tags': ['cleaning', 'household', 'all-purpose', 'surfaces'],
        'has_variants': false,
      },
      
      // Household & Essentials > Kitchen Accessories
      {
        'id': const Uuid().v4(),
        'name': 'Silicon Cooking Utensil Set',
        'slug': 'silicon-cooking-utensil-set',
        'description': 'Heat-resistant silicon cooking utensil set including spatula, spoon, and whisk. Safe for non-stick cookware and dishwasher safe.',
        'short_description': 'Heat-resistant kitchen utensil set',
        'price': 599.99,
        'discount_price': 499.99,
        'stock_quantity': 25,
        'category_id': categoryIds['Household & Essentials'],
        'subcategory_id': subcategoryIds['Kitchen Accessories'],
        'is_featured': true,
        'is_active': true,
        'brand': 'KitchenEssentials',
        'tags': ['kitchen', 'utensils', 'cooking', 'silicon'],
        'has_variants': true,
      },
    ];
  }
} 