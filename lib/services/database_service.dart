import 'dart:developer';
import 'package:dayliz_app/data/mock_products.dart';

class DatabaseService {
  Future<void> seedProducts() async {
    try {
      final mockProducts = getMockProducts();
      
      for (var product in mockProducts) {
        final productData = product.toJson();
        
        // Only include additional_images if it's not null
        if (productData['additional_images'] == null) {
          productData.remove('additional_images');
        }
        
        await _supabase.from('products').upsert(productData);
      }
      
      log('Products seeded successfully');
    } catch (e) {
      log('Error seeding products: $e');
    }
  }
} 