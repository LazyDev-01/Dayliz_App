import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:get_it/get_it.dart';

import '../../domain/usecases/is_authenticated_usecase.dart';

/// Clean architecture implementation of the database seeder
/// This class is responsible for seeding the database with sample data
class CleanDatabaseSeeder {
  static final CleanDatabaseSeeder _instance = CleanDatabaseSeeder._internal();
  static CleanDatabaseSeeder get instance => _instance;

  final SupabaseClient _client = Supabase.instance.client;
  final IsAuthenticatedUseCase _isAuthenticatedUseCase = GetIt.instance<IsAuthenticatedUseCase>();
  final Uuid _uuid = const Uuid();

  CleanDatabaseSeeder._internal();

  /// Check if the user is authenticated before seeding
  Future<bool> _checkAuthentication() async {
    try {
      final isAuthenticated = await _isAuthenticatedUseCase.call();
      return isAuthenticated;
    } catch (e) {
      debugPrint('Error checking authentication: $e');
      return false;
    }
  }

  /// Clear existing data before seeding
  Future<void> clearExistingData({
    void Function(String message)? onLog,
    void Function(double progress)? onProgress,
  }) async {
    final logFn = onLog ?? log;
    final progressFn = onProgress ?? ((_) {});

    // Check authentication
    final isAuthenticated = await _checkAuthentication();
    if (!isAuthenticated) {
      logFn('Not authenticated. Cannot clear data.');
      return;
    }

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
    // Check authentication
    final isAuthenticated = await _checkAuthentication();
    if (!isAuthenticated) {
      final logFn = onLog ?? log;
      logFn('Not authenticated. Cannot seed database.');
      return;
    }

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

    try {
      log('Testing database connection to categories table...');
      final categories = await _client.from('categories').select().limit(1);
      log('✅ Categories table connected: ${categories.length} records found');
    } catch (e) {
      log('❌ Error accessing categories table: $e');
    }

    try {
      log('Testing database connection to products table...');
      final products = await _client.from('products').select().limit(1);
      log('✅ Products table connected: ${products.length} records found');
    } catch (e) {
      log('❌ Error accessing products table: $e');
    }

    try {
      log('Testing database connection to subcategories table...');
      final subcategories = await _client.from('subcategories').select().limit(1);
      log('✅ Subcategories table connected: ${subcategories.length} records found');
    } catch (e) {
      log('❌ Error accessing subcategories table: $e');
      log('Will attempt to create subcategories table if needed during seeding');
    }

    log('Database connection tests completed');
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

      log('Seeding categories table with sample data...');

      // Check if subcategories table exists
      bool subcategoriesTableExists = false;
      try {
        await _client.from('subcategories').select('id').limit(1);
        subcategoriesTableExists = true;
        log('Subcategories table exists, will use it for subcategories');
      } catch (e) {
        log('Subcategories table does not exist, will create it');
        subcategoriesTableExists = await _createSubcategoriesTable(logFn: log);
      }

      // Create top-level categories
      final List<Map<String, dynamic>> topLevelCategories = [
        {
          'id': _uuid.v4(),
          'name': 'Fruits & Vegetables',
          'icon_name': 'eco',
          'image_url': 'https://placehold.co/200/4CAF50/FFFFFF?text=Fruits',
          'is_active': true,
          'display_order': 0,
        },
        {
          'id': _uuid.v4(),
          'name': 'Dairy & Eggs',
          'icon_name': 'egg',
          'image_url': 'https://placehold.co/200/2196F3/FFFFFF?text=Dairy',
          'is_active': true,
          'display_order': 1,
        },
        // Add more categories as needed
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

      // Add subcategories for each top-level category
      if (categoryIds.containsKey('Fruits & Vegetables')) {
        final parentId = categoryIds['Fruits & Vegetables']!;
        subcategories.addAll([
          {
            'id': _uuid.v4(),
            'name': 'Fresh Fruits',
            'category_id': parentId,
            'image_url': 'https://placehold.co/200/4CAF50/FFFFFF?text=Fruits',
            'icon_name': 'apple',
            'is_active': true,
            'display_order': 0,
          },
          {
            'id': _uuid.v4(),
            'name': 'Fresh Vegetables',
            'category_id': parentId,
            'image_url': 'https://placehold.co/200/4CAF50/FFFFFF?text=Vegetables',
            'icon_name': 'broccoli',
            'is_active': true,
            'display_order': 1,
          },
          // Add more subcategories as needed
        ]);
      }

      // Add more subcategories for other top-level categories

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

      // Create sample products
      final List<Map<String, dynamic>> products = [];

      // Add sample products here

      // Insert products
      int successCount = 0;
      for (var product in products) {
        try {
          final result = await _client.from('products').insert(product).select('id, name');

          if (result.isNotEmpty) {
            final productId = result[0]['id'];
            final productName = result[0]['name'];

            // Add product images
            await _addProductImages(productId, productName, product['category_id']);

            successCount++;
            log('✅ Added product: $productName with images');
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

  /// Add product images to a product
  Future<void> _addProductImages(String productId, String productName, String categoryId) async {
    // Get a color based on category ID
    final String colorHex = categoryId.hashCode.toString().substring(0, 6).padLeft(6, '0');

    // Add primary image
    await _client.from('product_images').insert({
      'id': _uuid.v4(),
      'product_id': productId,
      'image_url': 'https://placehold.co/600x400/$colorHex/FFFFFF?text=${Uri.encodeComponent(productName)}',
      'is_primary': true,
      'alt_text': productName,
      'display_order': 0
    });
  }
}
