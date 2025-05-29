import 'dart:developer';
import 'package:dayliz_app/data/mock_products.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  final SupabaseClient _supabase;
  
  DatabaseService(this._supabase);
  
  Future<void> seedProducts() async {
    try {
      final mockProducts = getMockProducts();
      
      for (var product in mockProducts) {
        final productData = product.toJson();
        
        // Extract images before inserting product
        final List<String> additionalImages = productData['additional_images'] ?? [];
        final String? mainImageUrl = productData['image_url'];
        
        // Remove image fields from product data
        productData.remove('additional_images');
        
        log('Inserting product: ${productData['name']}');
        
        // First insert the product
        final result = await _supabase.from('products').upsert(productData).select();
        
        if (result.isEmpty) {
          log('Warning: Failed to insert product ${productData['name']}');
          continue;
        }
        
        final productId = result[0]['id'];
        log('Product inserted with ID: $productId');
        
        // Then insert main image as primary
        if (mainImageUrl != null) {
          await _supabase.from('product_images').insert({
            'product_id': productId,
            'image_url': mainImageUrl,
            'is_primary': true,
            'alt_text': productData['name'],
            'display_order': 0
          });
        }
        
        // Insert additional images
        int displayOrder = 1;
        for (var imageUrl in additionalImages) {
          await _supabase.from('product_images').insert({
            'product_id': productId,
            'image_url': imageUrl,
            'is_primary': false,
            'alt_text': '${productData['name']} - alternate view',
            'display_order': displayOrder++
          });
        }
      }
      
      log('Products seeded successfully');
    } catch (e) {
      log('Error seeding products: $e');
    }
  }
} 