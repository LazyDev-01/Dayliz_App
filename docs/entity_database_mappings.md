# Entity-to-Database Mappings

<!-- 2025-04-22: Initial documentation for entity-to-database mappings -->

This document maps domain entities in the clean architecture to their corresponding database tables and fields in Supabase.

## Address Entity

### Domain Entity (`domain/entities/address.dart`)
```dart
class Address extends Equatable {
  final String id;
  final String userId;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final String? phoneNumber;
  final bool isDefault;
  final String label;
  final String? additionalInfo;
  final Map<String, double>? coordinates;
  
  // ... methods
}
```

### Legacy Model (`models/address.dart`)
```dart
class Address extends Equatable {
  final String id;
  final String userId;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final bool isDefault;
  final String? addressType;
  final String? recipientName;
  final String? recipientPhone;
  final String? landmark;
  final double? latitude;
  final double? longitude;
  final String? zone;
  final String? zoneId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // ... methods
}
```

### Database Table (`addresses`)
```sql
CREATE TABLE addresses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  address_line1 TEXT NOT NULL,
  address_line2 TEXT,
  city TEXT NOT NULL,
  state TEXT NOT NULL,
  postal_code TEXT NOT NULL,
  country TEXT NOT NULL,
  is_default BOOLEAN DEFAULT false,
  address_type TEXT,
  recipient_name TEXT,
  recipient_phone TEXT,
  landmark TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  zone TEXT,
  zone_id TEXT,
  label TEXT DEFAULT 'Home',
  additional_info TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
);
```

### Mapping Discrepancies
| Issue | Description | Resolution Strategy |
|-------|-------------|---------------------|
| Field Naming | Legacy uses camelCase internally but snake_case for JSON; Clean uses consistent camelCase | Standardize on camelCase in code, snake_case in database |
| Coordinates | Legacy has separate latitude/longitude; Clean has coordinates map | Convert between formats in the repository layer |
| Additional Fields | Legacy has more fields (recipientName, landmark, zone) | Include all fields in the database, make optional in clean architecture |
| Timestamps | Legacy has createdAt/updatedAt; Clean architecture omits these | Keep in database, handle in repository layer |
| Address Type vs Label | Legacy uses addressType; Clean uses label | Map between these in repository |

## User Profile Entity

### Domain Entity (`domain/entities/user_profile.dart`)
```dart
class UserProfile extends Equatable {
  final String id;
  final String userId;
  final String? fullName;
  final String? displayName;
  final String? bio;
  final String? profileImageUrl;
  final DateTime? dateOfBirth;
  final String? gender;
  final bool isPublic;
  final DateTime? lastUpdated;
  final Map<String, dynamic>? preferences;
  final List<Address>? addresses;
  
  // ... methods
}
```

### Database Table (`profiles`)
```sql
CREATE TABLE profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT,
  display_name TEXT,
  bio TEXT,
  profile_image_url TEXT,
  date_of_birth DATE,
  gender TEXT,
  is_public BOOLEAN DEFAULT true,
  last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  preferences JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
);
```

### Mapping Discrepancies
| Issue | Description | Resolution Strategy |
|-------|-------------|---------------------|
| Addresses Relationship | Clean entity includes addresses list; Database normalizes this | Fetch addresses separately and combine in repository |
| Preferences | Stored as JSONB in database | Parse/stringify in repository layer |
| Timestamps | Database has created_at not in entity | Handle in repository layer |

## Product Entity

### Domain Entity (`domain/entities/product.dart`)
```dart
class Product extends Equatable {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? discountPercentage;
  final double? rating;
  final int? reviewCount;
  final String mainImageUrl;
  final List<String>? additionalImages;
  final bool inStock;
  final int? stockQuantity;
  final String categoryId;
  final String? subcategoryId;
  final String? brand;
  final Map<String, dynamic>? attributes;
  final List<String>? tags;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String>? images;
  final bool onSale;
  
  // ... methods
}
```

### Legacy Model (`models/product.dart`)
```dart
class Product extends Equatable {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? discountPrice;
  final String imageUrl;
  final List<String>? additionalImages;
  final bool isInStock;
  final int stockQuantity;
  final List<String> categories;
  final String? categoryId;
  final double rating;
  final int reviewCount;
  final String brand;
  final DateTime dateAdded;
  final Map<String, dynamic> attributes;
  final bool isFeatured;
  final bool isOnSale;
  final bool? isInWishlist;
  
  // ... methods
}
```

### Database Table (`products`)
```sql
CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  price DECIMAL(10, 2) NOT NULL,
  discount_price DECIMAL(10, 2),
  image_url TEXT NOT NULL,
  additional_images TEXT[],
  is_in_stock BOOLEAN DEFAULT true,
  stock_quantity INTEGER NOT NULL DEFAULT 0,
  category_id UUID REFERENCES categories(id),
  subcategory_id UUID REFERENCES subcategories(id),
  brand TEXT,
  date_added TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  attributes JSONB DEFAULT '{}'::jsonb,
  is_featured BOOLEAN DEFAULT false,
  is_on_sale BOOLEAN DEFAULT false,
  tags TEXT[],
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT fk_category FOREIGN KEY (category_id) REFERENCES categories(id),
  CONSTRAINT fk_subcategory FOREIGN KEY (subcategory_id) REFERENCES subcategories(id)
);
```

### Mapping Discrepancies
| Issue | Description | Resolution Strategy |
|-------|-------------|---------------------|
| Discount Handling | Legacy uses discountPrice; Clean uses discountPercentage | Store both in database, calculate as needed |
| Stock Status | Legacy uses isInStock; Clean uses inStock | Standardize naming in clean architecture |
| Images | Clean has mainImageUrl and images; Legacy has imageUrl and additionalImages | Ensure consistent field usage, map as needed |
| Categories | Legacy has categories list; Clean has categoryId | Handle join in repository or store categoryId |
| Wishlists | Legacy has isInWishlist; Clean omits this | Handle through a join table and separate repository method |
| Featured Flag | Legacy has isFeatured; Clean omits this | Include in database, handle in repository |

## Migration Path

For each entity, the migration path will follow these steps:

1. Update domain entity if needed to accommodate all required fields
2. Ensure database schema has all necessary fields
3. Implement repository layer to handle mapping between entity and database
4. Update or create use cases to work with the clean architecture entity
5. Modify UI to use the clean architecture entity and use cases 