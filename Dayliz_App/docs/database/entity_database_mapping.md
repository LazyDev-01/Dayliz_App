# Entity-to-Database Mapping

This document maps the domain entities in the clean architecture implementation to their corresponding database tables in Supabase.

## Address Entity

### Domain Entity (`lib/domain/entities/address.dart`)

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
  final String? addressType;
  final String? additionalInfo;
  final double? latitude;
  final double? longitude;
  final String? landmark;
  final String? zoneId;
  final String? recipientName;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}
```

### Database Table (`addresses`)

| Entity Field    | Database Column   | Data Type                | Notes                                |
|-----------------|-------------------|--------------------------|--------------------------------------|
| id              | id                | uuid                     | Primary key                          |
| userId          | user_id           | uuid                     | Foreign key to auth.users            |
| addressLine1    | address_line1     | text                     | Required                             |
| addressLine2    | address_line2     | text                     | Optional                             |
| city            | city              | text                     | Required                             |
| state           | state             | text                     | Required                             |
| postalCode      | postal_code       | text                     | Required                             |
| country         | country           | text                     | Required                             |
| phoneNumber     | phone_number      | text                     | Optional                             |
| isDefault       | is_default        | boolean                  | Default: false                       |
| addressType     | address_type      | text                     | Optional (home, work, other)         |
| additionalInfo  | additional_info   | text                     | Optional                             |
| latitude        | latitude          | numeric                  | Optional                             |
| longitude       | longitude         | numeric                  | Optional                             |
| landmark        | landmark          | text                     | Optional                             |
| zoneId          | zone_id           | uuid                     | Foreign key to zones                 |
| recipientName   | recipient_name    | text                     | Optional                             |
| createdAt       | created_at        | timestamp with time zone | Auto-generated                       |
| updatedAt       | updated_at        | timestamp with time zone | Auto-updated                         |

## UserProfile Entity

### Domain Entity (`lib/domain/entities/user_profile.dart`)

```dart
class UserProfile extends Equatable {
  final String id;
  final String userId;
  final String? fullName;
  final String? profileImageUrl;
  final DateTime? dateOfBirth;
  final String? gender;
  final DateTime? lastUpdated;
  final Map<String, dynamic>? preferences;
}
```

### Database Table (`user_profiles`)

| Entity Field     | Database Column     | Data Type                | Notes                                |
|------------------|---------------------|--------------------------|--------------------------------------|
| id               | id                  | uuid                     | Primary key                          |
| userId           | user_id             | uuid                     | Foreign key to auth.users            |
| fullName         | full_name           | text                     | Optional                             |
| profileImageUrl  | profile_image_url   | text                     | Optional                             |
| dateOfBirth      | date_of_birth       | date                     | Optional                             |
| gender           | gender              | text                     | Optional                             |
| lastUpdated      | updated_at          | timestamp with time zone | Auto-updated                         |
| preferences      | preferences         | jsonb                    | Optional                             |

## Product Entity

### Domain Entity (`lib/domain/entities/product.dart`)

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
  final String? categoryName;
  final String? subcategoryName;
}
```

### Database Table (`products`)

| Entity Field       | Database Column      | Data Type                | Notes                                |
|--------------------|----------------------|--------------------------|--------------------------------------|
| id                 | id                   | uuid                     | Primary key                          |
| name               | name                 | text                     | Required                             |
| description        | description          | text                     | Required                             |
| price              | price                | decimal                  | Required                             |
| discountPercentage | discount_percentage  | decimal                  | Optional                             |
| rating             | rating               | decimal                  | Optional                             |
| reviewCount        | review_count         | integer                  | Optional                             |
| mainImageUrl       | main_image_url       | text                     | Required                             |
| additionalImages   | additional_images    | jsonb                    | Optional, array of image URLs        |
| inStock            | in_stock             | boolean                  | Default: true                        |
| stockQuantity      | stock_quantity       | integer                  | Optional                             |
| categoryId         | category_id          | uuid                     | Foreign key to categories            |
| subcategoryId      | subcategory_id       | uuid                     | Foreign key to subcategories         |
| brand              | brand                | text                     | Optional                             |
| attributes         | attributes           | jsonb                    | Optional                             |
| tags               | tags                 | text[]                   | Optional                             |
| createdAt          | created_at           | timestamp with time zone | Auto-generated                       |
| updatedAt          | updated_at           | timestamp with time zone | Auto-updated                         |
| onSale             | on_sale              | boolean                  | Default: false                       |

## PaymentMethod Entity

### Domain Entity (`lib/domain/entities/payment_method.dart`)

```dart
class PaymentMethod extends Equatable {
  final String id;
  final String userId;
  final String type;
  final String name;
  final bool isDefault;
  final Map<String, dynamic> details;
}
```

### Database Table (`payment_methods`)

| Entity Field | Database Column | Data Type                | Notes                                |
|--------------|-----------------|--------------------------|--------------------------------------|
| id           | id              | uuid                     | Primary key                          |
| userId       | user_id         | uuid                     | Foreign key to auth.users            |
| type         | type            | text                     | Required (card, paypal, cod, etc.)   |
| name         | name            | text                     | Required                             |
| isDefault    | is_default      | boolean                  | Default: false                       |
| details      | details         | jsonb                    | Required                             |
| -            | created_at      | timestamp with time zone | Auto-generated                       |
| -            | updated_at      | timestamp with time zone | Auto-updated                         |

## Order Entity

### Domain Entity (`lib/domain/entities/order.dart`)

```dart
class Order extends Equatable {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final double subtotal;
  final double tax;
  final double shipping;
  final double total;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Address shippingAddress;
  final Address? billingAddress;
  final PaymentMethod paymentMethod;
  final String? trackingNumber;
  final String? notes;
  final String? couponCode;
  final double? discount;
}
```

### Database Table (`orders`)

| Entity Field    | Database Column     | Data Type                | Notes                                |
|-----------------|---------------------|--------------------------|--------------------------------------|
| id              | id                  | uuid                     | Primary key                          |
| userId          | user_id             | uuid                     | Foreign key to auth.users            |
| items           | -                   | -                        | Stored in order_items table          |
| subtotal        | subtotal            | decimal                  | Required                             |
| tax             | tax                 | decimal                  | Required                             |
| shipping        | shipping            | decimal                  | Required                             |
| total           | total_amount        | decimal                  | Required                             |
| status          | status              | text                     | Required                             |
| createdAt       | created_at          | timestamp with time zone | Auto-generated                       |
| updatedAt       | updated_at          | timestamp with time zone | Auto-updated                         |
| shippingAddress | delivery_address_id | uuid                     | Foreign key to addresses             |
| billingAddress  | billing_address_id  | uuid                     | Foreign key to addresses             |
| paymentMethod   | payment_method_id   | uuid                     | Foreign key to payment_methods       |
| trackingNumber  | tracking_number     | text                     | Optional                             |
| notes           | notes               | text                     | Optional                             |
| couponCode      | coupon_code         | text                     | Optional                             |
| discount        | discount_amount     | decimal                  | Optional                             |

## OrderItem Entity

### Domain Entity (`lib/domain/entities/order_item.dart`)

```dart
class OrderItem extends Equatable {
  final String id;
  final String productId;
  final String productName;
  final String? imageUrl;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final Map<String, dynamic>? options;
  final String? variantId;
  final String? sku;
}
```

### Database Table (`order_items`)

| Entity Field | Database Column | Data Type                | Notes                                |
|--------------|-----------------|--------------------------|--------------------------------------|
| id           | id              | uuid                     | Primary key                          |
| -            | order_id        | uuid                     | Foreign key to orders                |
| productId    | product_id      | uuid                     | Foreign key to products              |
| productName  | product_name    | text                     | Required                             |
| imageUrl     | image_url       | text                     | Optional                             |
| quantity     | quantity        | integer                  | Required                             |
| unitPrice    | product_price   | decimal                  | Required                             |
| totalPrice   | total_price     | decimal                  | Required                             |
| options      | options         | jsonb                    | Optional                             |
| variantId    | variant_id      | text                     | Optional                             |
| sku          | sku             | text                     | Optional                             |
| -            | created_at      | timestamp with time zone | Auto-generated                       |
| -            | updated_at      | timestamp with time zone | Auto-updated                         |

## CartItem Entity

### Domain Entity (`lib/domain/entities/cart_item.dart`)

```dart
class CartItem extends Equatable {
  final String id;
  final Product product;
  final int quantity;
  final DateTime addedAt;
}
```

### Database Table (`cart_items`)

| Entity Field | Database Column | Data Type                | Notes                                |
|--------------|-----------------|--------------------------|--------------------------------------|
| id           | id              | uuid                     | Primary key                          |
| -            | user_id         | uuid                     | Foreign key to auth.users            |
| product      | product_id      | uuid                     | Foreign key to products              |
| quantity     | quantity        | integer                  | Required                             |
| addedAt      | added_at        | timestamp with time zone | Auto-generated                       |
| -            | created_at      | timestamp with time zone | Auto-generated                       |
| -            | updated_at      | timestamp with time zone | Auto-updated                         |
| -            | selected        | boolean                  | Default: true                        |
| -            | saved_for_later | boolean                  | Default: false                       |

## WishlistItem Entity

### Domain Entity (`lib/domain/entities/wishlist_item.dart`)

```dart
class WishlistItem extends Equatable {
  final String id;
  final String productId;
  final DateTime dateAdded;
}
```

### Database Table (`wishlist_items`)

| Entity Field | Database Column | Data Type                | Notes                                |
|--------------|-----------------|--------------------------|--------------------------------------|
| id           | id              | uuid                     | Primary key                          |
| -            | user_id         | uuid                     | Foreign key to auth.users            |
| productId    | product_id      | uuid                     | Foreign key to products              |
| dateAdded    | added_at        | timestamp with time zone | Auto-generated                       |
| -            | created_at      | timestamp with time zone | Auto-generated                       |
| -            | updated_at      | timestamp with time zone | Auto-updated                         |
