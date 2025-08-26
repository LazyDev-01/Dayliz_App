import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

/// Script to create placeholder assets for the Dayliz app
/// Run with: flutter run create_placeholder_assets.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🎨 Creating placeholder assets for Dayliz app...');
  
  // Create assets directory if it doesn't exist
  final assetsDir = Directory('apps/mobile/assets/images');
  if (!assetsDir.existsSync()) {
    assetsDir.createSync(recursive: true);
  }
  
  final iconsDir = Directory('apps/mobile/assets/icons');
  if (!iconsDir.existsSync()) {
    iconsDir.createSync(recursive: true);
  }
  
  // Create placeholder images
  await createPlaceholderImage('apps/mobile/assets/images/app_logo.png', 
      'Dayliz', Colors.green, 200, 200);
  
  await createPlaceholderImage('apps/mobile/assets/images/splash_logo.png', 
      'Dayliz', Colors.green, 300, 300);
  
  await createPlaceholderImage('apps/mobile/assets/images/empty_cart.png', 
      'Empty\nCart', Colors.grey, 150, 150);
  
  await createPlaceholderImage('apps/mobile/assets/images/empty_wishlist.png', 
      'Empty\nWishlist', Colors.grey, 150, 150);
  
  await createPlaceholderImage('apps/mobile/assets/images/empty_orders.png', 
      'No\nOrders', Colors.grey, 150, 150);
  
  await createPlaceholderImage('apps/mobile/assets/images/empty_search.png', 
      'No\nResults', Colors.grey, 150, 150);
  
  await createPlaceholderImage('apps/mobile/assets/images/placeholder_product.png', 
      'Product', Colors.blue, 100, 100);
  
  await createPlaceholderImage('apps/mobile/assets/images/placeholder_profile.png', 
      'Profile', Colors.purple, 100, 100);
  
  // Create category icons
  await createPlaceholderImage('apps/mobile/assets/icons/fruits.png', 
      '🍎', Colors.red, 64, 64);
  
  await createPlaceholderImage('apps/mobile/assets/icons/vegetables.png', 
      '🥕', Colors.orange, 64, 64);
  
  await createPlaceholderImage('apps/mobile/assets/icons/dairy.png', 
      '🥛', Colors.blue, 64, 64);
  
  await createPlaceholderImage('apps/mobile/assets/icons/bakery.png', 
      '🍞', Colors.brown, 64, 64);
  
  await createPlaceholderImage('apps/mobile/assets/icons/meat.png', 
      '🥩', Colors.red, 64, 64);
  
  await createPlaceholderImage('apps/mobile/assets/icons/credit_card.png', 
      '💳', Colors.blue, 64, 64);
  
  print('✅ All placeholder assets created successfully!');
  print('📁 Assets created in:');
  print('   - apps/mobile/assets/images/');
  print('   - apps/mobile/assets/icons/');
  print('');
  print('🚀 You can now run the app without asset loading errors.');
  print('💡 Replace these placeholders with actual assets when available.');
}

Future<void> createPlaceholderImage(String path, String text, Color color, 
    double width, double height) async {
  try {
    // Create a simple colored rectangle with text
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    // Background
    final paint = Paint()..color = color.withOpacity(0.1);
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), paint);
    
    // Border
    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), borderPaint);
    
    // Text
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: width * 0.15,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    final textOffset = Offset(
      (width - textPainter.width) / 2,
      (height - textPainter.height) / 2,
    );
    textPainter.paint(canvas, textOffset);
    
    // Convert to image
    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    
    if (byteData != null) {
      final file = File(path);
      await file.writeAsBytes(byteData.buffer.asUint8List());
      print('✅ Created: $path');
    }
  } catch (e) {
    print('❌ Failed to create $path: $e');
  }
}
