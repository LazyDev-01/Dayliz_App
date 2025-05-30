import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dayliz_app/data/mock_products.dart';
import 'package:dayliz_app/models/product.dart';

/// A utility class to seed the database with test data
class DatabaseSeeder {
  final SupabaseClient _supabase;
  
  DatabaseSeeder(this._supabase);
  
  /// Get the Supabase client instance
  static DatabaseSeeder get instance => 
      DatabaseSeeder(Supabase.instance.client);
  
  /// Check if products table exists and has data
  Future<bool> hasProducts() async {
    try {
      final response = await _supabase
          .from('products')
          .select('id')
          .limit(1);
      
      return response.isNotEmpty;
    } catch (e) {
      print('Error checking products: $e');
      return false;
    }
  }
  
  /// Seed the products table with mock data
  Future<void> seedProducts() async {
    try {
      // Check if products already exist
      if (await hasProducts()) {
        print('Products table already has data. Skipping seeding.');
        return;
      }
      
      print('Seeding products table with ${mockProducts.length} products...');
      
      // Convert products to JSON and prepare for batch insert
      final productsJson = mockProducts.map((product) => product.toJson()).toList();
      
      // Insert products in batches to avoid request size limits
      const batchSize = 5;
      for (var i = 0; i < productsJson.length; i += batchSize) {
        final end = (i + batchSize < productsJson.length) 
            ? i + batchSize 
            : productsJson.length;
        final batch = productsJson.sublist(i, end);
        
        await _supabase
            .from('products')
            .insert(batch);
        
        print('Inserted batch ${i ~/ batchSize + 1}');
      }
      
      print('Successfully seeded products table');
    } catch (e) {
      print('Error seeding products: $e');
      rethrow;
    }
  }
  
  /// Seed all tables with mock data
  Future<void> seedAll() async {
    try {
      await seedProducts();
      // Add more seed functions here as needed
      print('Database seeding completed successfully');
    } catch (e) {
      print('Error during database seeding: $e');
      rethrow;
    }
  }
} 