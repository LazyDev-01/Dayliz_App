# Banner Carousel Backend Integration Guide

## 🎯 Overview

This guide documents the complete backend integration for the banner carousel system, including database setup, clean architecture implementation, and how to manage banners in production.

## 📊 Database Schema

### Banners Table Structure

```sql
CREATE TABLE banners (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title VARCHAR(255) NOT NULL,
  subtitle TEXT,
  image_url TEXT NOT NULL,
  action_url TEXT,
  action_type VARCHAR(50) DEFAULT 'none' CHECK (action_type IN ('product', 'category', 'collection', 'url', 'none')),
  start_date TIMESTAMPTZ,
  end_date TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT true,
  display_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Key Features
- **UUID Primary Key**: Secure, non-sequential identifiers
- **Flexible Action Types**: Support for different navigation targets
- **Date Range Support**: Schedule banners for specific periods
- **Display Ordering**: Control banner sequence
- **Automatic Timestamps**: Track creation and updates

### Row Level Security (RLS)
- **Public Read**: Anyone can view active banners
- **Authenticated Read**: Logged-in users can view all banners
- **Service Role**: Full CRUD operations for admin functions

## 🏗️ Architecture Overview

### Clean Architecture Layers

```
📱 Presentation Layer
├── widgets/home/enhanced_banner_carousel.dart
├── providers/banner_providers.dart
├── providers/banner_notifier.dart
└── providers/banner_state.dart

🎯 Domain Layer
├── entities/banner.dart
├── repositories/banner_repository.dart
└── usecases/banner/
    ├── get_active_banners.dart
    └── get_banner_by_id.dart

💾 Data Layer
├── models/banner_model.dart
├── datasources/banner_remote_data_source.dart
└── repositories/banner_repository_impl.dart
```

## 🚀 Implementation Details

### 1. Domain Entity

The `Banner` entity includes:
- **Validation Logic**: `isValid`, `isExpired`, `isCurrentlyActive`
- **Status Management**: Dynamic status based on dates and activity
- **Type Safety**: Strongly typed action types

### 2. Data Source

Supabase integration with:
- **Error Handling**: Comprehensive exception mapping
- **Type Conversion**: JSON serialization/deserialization
- **Query Optimization**: Efficient filtering and ordering

### 3. State Management

Riverpod-based state management:
- **Reactive Updates**: Automatic UI updates on data changes
- **Error States**: User-friendly error handling
- **Loading States**: Smooth loading experiences

## 📝 How to Add Real Banners

### Method 1: Direct Database Insert

```sql
INSERT INTO banners (
  title, 
  subtitle, 
  image_url, 
  action_url, 
  action_type, 
  display_order, 
  is_active
) VALUES (
  'Your Banner Title',
  'Your banner description',
  'https://your-cdn.com/banner-image.jpg',
  '/your-target-route',
  'category',
  1,
  true
);
```

### Method 2: Using Supabase Dashboard

1. **Navigate to Supabase Dashboard**
2. **Go to Table Editor → banners**
3. **Click "Insert row"**
4. **Fill in the required fields:**
   - `title`: Banner headline
   - `subtitle`: Banner description
   - `image_url`: URL to your banner image
   - `action_url`: Where to navigate when tapped
   - `action_type`: Type of action (category, product, etc.)
   - `display_order`: Order in carousel (1, 2, 3...)
   - `is_active`: true to show, false to hide

### Method 3: Programmatic Creation

```dart
// Using the repository
final banner = Banner(
  id: '', // Will be generated
  title: 'New Promotion',
  subtitle: 'Limited time offer',
  imageUrl: 'https://example.com/banner.jpg',
  actionUrl: '/promotions',
  actionType: BannerActionType.url,
  isActive: true,
  displayOrder: 1,
);

final result = await bannerRepository.createBanner(banner);
```

## 🖼️ Image Management

### Recommended Image Specifications
- **Dimensions**: 800x400px (2:1 aspect ratio)
- **Format**: JPEG or PNG
- **Size**: Under 500KB for optimal loading
- **Quality**: 80-90% compression

### Image Hosting Options

1. **Supabase Storage**
   ```dart
   final file = File('path/to/banner.jpg');
   final response = await supabase.storage
       .from('banners')
       .upload('banner-${DateTime.now().millisecondsSinceEpoch}.jpg', file);
   ```

2. **CDN Services**
   - Cloudinary
   - AWS S3 + CloudFront
   - Google Cloud Storage

3. **External URLs**
   - Unsplash (for testing)
   - Your existing image hosting

## 🎛️ Banner Management

### Action Types Explained

| Type | Description | Example URL |
|------|-------------|-------------|
| `category` | Navigate to category page | `/categories/groceries` |
| `product` | Navigate to specific product | `/products/abc123` |
| `collection` | Navigate to product collection | `/collections/featured` |
| `url` | Custom navigation | `/promotions/summer-sale` |
| `none` | Display only, no action | `null` |

### Scheduling Banners

```sql
-- Schedule a banner for a specific period
UPDATE banners SET
  start_date = '2024-01-01 00:00:00+00',
  end_date = '2024-01-31 23:59:59+00'
WHERE id = 'your-banner-id';
```

### Banner Ordering

```sql
-- Reorder banners
UPDATE banners SET display_order = 1 WHERE id = 'banner-1';
UPDATE banners SET display_order = 2 WHERE id = 'banner-2';
UPDATE banners SET display_order = 3 WHERE id = 'banner-3';
```

## 🔧 Configuration

### Environment Setup

Ensure your Supabase configuration is properly set up:

```dart
// In your main.dart or app initialization
await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',
  anonKey: 'YOUR_SUPABASE_ANON_KEY',
);
```

### Provider Integration

The banner carousel automatically loads data when initialized. No additional setup required in your screens.

## 🧪 Testing

### Test the Integration

1. **Add a test banner** to the database
2. **Run the app** and navigate to the home screen
3. **Verify the banner appears** in the carousel
4. **Test banner tap** functionality
5. **Check error states** by temporarily disabling network

### Sample Test Banner

```sql
INSERT INTO banners (title, subtitle, image_url, action_url, action_type, display_order, is_active) 
VALUES (
  'Test Banner', 
  'This is a test banner', 
  'https://images.unsplash.com/photo-1542838132-92c53300491e?w=800&h=400&fit=crop',
  '/test',
  'url',
  1,
  true
);
```

## 🚨 Troubleshooting

### Common Issues

1. **Banners not loading**
   - Check Supabase connection
   - Verify RLS policies
   - Check network connectivity

2. **Images not displaying**
   - Verify image URLs are accessible
   - Check CORS settings for external images
   - Ensure proper image formats

3. **Navigation not working**
   - Verify action URLs are valid routes
   - Check GoRouter configuration
   - Ensure proper action types

### Debug Commands

```sql
-- Check active banners
SELECT * FROM banners WHERE is_active = true ORDER BY display_order;

-- Check banner validity
SELECT *, 
  CASE 
    WHEN start_date IS NOT NULL AND NOW() < start_date THEN 'Not Started'
    WHEN end_date IS NOT NULL AND NOW() > end_date THEN 'Expired'
    WHEN is_active = false THEN 'Inactive'
    ELSE 'Active'
  END as status
FROM banners;
```

## ✅ Next Steps

1. **Add your first real banner** using the database
2. **Upload banner images** to your preferred hosting
3. **Test the complete flow** from database to UI
4. **Set up banner management** workflow for your team
5. **Monitor performance** and optimize as needed

The banner carousel is now fully integrated with your backend and ready for production use! 🎉
