import 'dart:io';

/// Script to set up app icon directory structure for Android and iOS
/// Run with: dart run generate_app_icons.dart
///
/// Note: This script creates the directory structure and provides instructions.
/// For actual icon generation, use flutter_launcher_icons package or manual tools.
void main() async {
  print('🎨 Setting up app icon directories for Android and iOS...');

  // Source icon path
  final sourceIconPath = 'apps/mobile/assets/icons/appIcon.png';
  final sourceFile = File(sourceIconPath);

  if (!sourceFile.existsSync()) {
    print('❌ Source icon not found: $sourceIconPath');
    print('Please make sure appIcon.png exists in apps/mobile/assets/icons/');
    print('');
    print('💡 To create a source icon:');
    print('1. Create a 1024x1024 PNG icon');
    print('2. Save it as apps/mobile/assets/icons/appIcon.png');
    print('3. Run this script again');
    return;
  }

  print('✅ Source image found: $sourceIconPath');
  
  // Android icon sizes (mipmap directories)
  final androidSizes = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
  };
  
  // iOS icon sizes
  final iosSizes = {
    'Icon-App-20x20@1x.png': 20,
    'Icon-App-20x20@2x.png': 40,
    'Icon-App-20x20@3x.png': 60,
    'Icon-App-29x29@1x.png': 29,
    'Icon-App-29x29@2x.png': 58,
    'Icon-App-29x29@3x.png': 87,
    'Icon-App-40x40@1x.png': 40,
    'Icon-App-40x40@2x.png': 80,
    'Icon-App-40x40@3x.png': 120,
    'Icon-App-60x60@2x.png': 120,
    'Icon-App-60x60@3x.png': 180,
    'Icon-App-76x76@1x.png': 76,
    'Icon-App-76x76@2x.png': 152,
    'Icon-App-83.5x83.5@2x.png': 167,
    'Icon-App-1024x1024@1x.png': 1024,
  };
  
  // Create Android icon directories
  print('\n📱 Setting up Android icon directories...');
  for (final entry in androidSizes.entries) {
    final directory = entry.key;
    final size = entry.value;

    // Create directory
    final androidDir = Directory('apps/mobile/android/app/src/main/res/$directory');
    if (!androidDir.existsSync()) {
      androidDir.createSync(recursive: true);
      print('✅ Created directory: $directory/');
    } else {
      print('📁 Directory exists: $directory/');
    }

    // Check if icon already exists
    final iconFile = File('${androidDir.path}/ic_launcher.png');
    if (iconFile.existsSync()) {
      print('   📄 Icon exists: ic_launcher.png (${size}x${size})');
    } else {
      print('   ⚠️  Missing: ic_launcher.png (${size}x${size}) - needs manual creation');
    }
  }
  
  // Set up iOS icons directory
  print('\n🍎 Setting up iOS icon directory...');
  final iosDir = Directory('apps/mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset');
  if (!iosDir.existsSync()) {
    iosDir.createSync(recursive: true);
    print('✅ Created iOS AppIcon directory');
  } else {
    print('📁 iOS AppIcon directory exists');
  }

  print('\n📋 Required iOS icon files:');
  for (final entry in iosSizes.entries) {
    final filename = entry.key;
    final size = entry.value;

    final iconFile = File('${iosDir.path}/$filename');
    if (iconFile.existsSync()) {
      print('   ✅ $filename (${size}x${size})');
    } else {
      print('   ⚠️  Missing: $filename (${size}x${size})');
    }
  }
  
  // Create iOS Contents.json
  await createiOSContentsJson(iosDir.path);

  print('\n🎉 Directory setup completed!');
  print('\n📋 Next steps to generate actual icons:');
  print('');
  print('🔧 Option 1: Use flutter_launcher_icons package (Recommended)');
  print('1. Add to pubspec.yaml:');
  print('   dev_dependencies:');
  print('     flutter_launcher_icons: ^0.13.1');
  print('2. Add configuration and run: flutter packages pub run flutter_launcher_icons');
  print('');
  print('🔧 Option 2: Manual icon generation');
  print('1. Use online tools like appicon.co or iconkitchen.com');
  print('2. Upload your 1024x1024 source icon');
  print('3. Download generated icons and place them in the created directories');
  print('');
  print('🔧 Option 3: Use image editing software');
  print('1. Resize your source icon to each required size');
  print('2. Save as PNG files with the exact names shown above');
  print('');
  print('✅ After adding icons:');
  print('1. Run: flutter clean && flutter build apk');
  print('2. Test on device to see the new app icon');
  print('3. For iOS: Open Xcode and verify icons are properly set');
}

Future<void> createiOSContentsJson(String dirPath) async {
  final contentsJson = '''
{
  "images" : [
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "20x20",
      "filename" : "Icon-App-20x20@2x.png"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "20x20",
      "filename" : "Icon-App-20x20@3x.png"
    },
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "29x29",
      "filename" : "Icon-App-29x29@2x.png"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "29x29",
      "filename" : "Icon-App-29x29@3x.png"
    },
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "40x40",
      "filename" : "Icon-App-40x40@2x.png"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "40x40",
      "filename" : "Icon-App-40x40@3x.png"
    },
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "60x60",
      "filename" : "Icon-App-60x60@2x.png"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "60x60",
      "filename" : "Icon-App-60x60@3x.png"
    },
    {
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "20x20",
      "filename" : "Icon-App-20x20@1x.png"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "20x20",
      "filename" : "Icon-App-20x20@2x.png"
    },
    {
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "29x29",
      "filename" : "Icon-App-29x29@1x.png"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "29x29",
      "filename" : "Icon-App-29x29@2x.png"
    },
    {
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "40x40",
      "filename" : "Icon-App-40x40@1x.png"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "40x40",
      "filename" : "Icon-App-40x40@2x.png"
    },
    {
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "76x76",
      "filename" : "Icon-App-76x76@1x.png"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "76x76",
      "filename" : "Icon-App-76x76@2x.png"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "83.5x83.5",
      "filename" : "Icon-App-83.5x83.5@2x.png"
    },
    {
      "idiom" : "ios-marketing",
      "scale" : "1x",
      "size" : "1024x1024",
      "filename" : "Icon-App-1024x1024@1x.png"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
''';

  final contentsFile = File('$dirPath/Contents.json');
  await contentsFile.writeAsString(contentsJson);
  print('✅ Created: iOS Contents.json');
}
