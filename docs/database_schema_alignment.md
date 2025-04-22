# Database Schema Alignment with Clean Architecture Entities

This document outlines the alignment between the Supabase database schema and the clean architecture entities in the Dayliz App. It serves as a reference for implementing data sources that connect to the Supabase backend.

## Table of Contents

1. [Address](#address)
2. [Product](#product)
3. [Category and SubCategory](#category-and-subcategory)
4. [User and UserProfile](#user-and-userprofile)
5. [Order and OrderItem](#order-and-orderitem)
6. [CartItem](#cartitem)
7. [Wishlist](#wishlist)
8. [Review](#review)

## Address

### Database Table: `addresses`

| Database Column      | Entity Property     | Data Type      | Notes                                   |
|----------------------|--------------------|----------------|----------------------------------------|
| id                   | id                 | UUID           | Primary key                            |
| user_id              | userId             | UUID           | Foreign key to users table             |
| address_line1        | addressLine1       | TEXT           | Required                               |
| address_line2        | addressLine2       | TEXT           | Optional                               |
| city                 | city               | TEXT           | Required                               |
| state                | state              | TEXT           | Required                               |
| postal_code          | postalCode         | TEXT           | Required                               |
| country              | country            | TEXT           | Required                               |
| is_default           | isDefault          | BOOLEAN        | Default: false                         |
| address_type         | addressType        | TEXT           | Optional (e.g., "Home", "Work")        |
| recipient_name       | recipientName      | TEXT           | Optional                               |
| recipient_phone      | recipientPhone     | TEXT           | Optional                               |
| landmark             | landmark           | TEXT           | Optional                               |
| latitude             | latitude           | NUMERIC(10, 6) | Optional                               |
| longitude            | longitude          | NUMERIC(10, 6) | Optional                               |
| zone_id              | zoneId             | UUID           | Foreign key to zones table             |
| created_at           | createdAt          | TIMESTAMP      | Default: now()                         |
| updated_at           | updatedAt          | TIMESTAMP      | Default: now()                         |

## Product

### Database Table: `products`

| Database Column      | Entity Property     | Data Type      | Notes                                   |
|----------------------|--------------------|----------------|----------------------------------------|
| id                   | id                 | UUID           | Primary key                            |
| name                 | name               | TEXT           | Required                               |
| description          | description        | TEXT           | Optional                               |
| price                | price              | NUMERIC(10, 2) | Required                               |
| discounted_price     | discountedPrice    | NUMERIC(10, 2) | Optional                               |
| subcategory_id       | subcategoryId      | UUID           | Foreign key to subcategories table     |
| category_id          | categoryId         | UUID           | Foreign key to categories table        |
| vendor_id            | vendorId           | UUID           | Foreign key to vendors table           |
| is_featured          | isFeatured         | BOOLEAN        | Default: false                         |
| is_on_sale           | isOnSale           | BOOLEAN        | Default: false                         |
| sale_end_date        | saleEndDate        | TIMESTAMP      | Optional                               |
| stock_quantity       | stockQuantity      | INTEGER        | Default: 0                             |
| ratings_avg          | ratingsAvg         | NUMERIC(3, 2)  | Default: 0                             |
| ratings_count        | ratingsCount       | INTEGER        | Default: 0                             |
| sku                  | sku                | TEXT           | Optional                               |
| weight               | weight             | NUMERIC(8, 2)  | Optional                               |
| dimensions           | dimensions         | TEXT           | Optional                               |
| is_active            | isActive           | BOOLEAN        | Default: true                          |
| created_at           | createdAt          | TIMESTAMP      | Default: now()                         |
| updated_at           | updatedAt          | TIMESTAMP      | Default: now()                         |
| (derived)            | mainImageUrl       | -              | Derived from product_images table      |
| (derived)            | inStock            | -              | Derived (stockQuantity > 0 && isActive) |

### Database Table: `product_images`

| Database Column      | Entity Property     | Data Type      | Notes                                   |
|----------------------|--------------------|----------------|----------------------------------------|
| id                   | -                  | UUID           | Primary key                            |
| product_id           | -                  | UUID           | Foreign key to products table          |
| image_url            | -                  | TEXT           | Required                               |
| is_primary           | -                  | BOOLEAN        | Default: false                         |
| display_order        | -                  | INTEGER        | Default: 0                             |
| created_at           | -                  | TIMESTAMP      | Default: now()                         |
| updated_at           | -                  | TIMESTAMP      | Default: now()                         |

## Category and SubCategory

### Database Table: `categories`

| Database Column      | Entity Property     | Data Type      | Notes                                   |
|----------------------|--------------------|----------------|----------------------------------------|
| id                   | id                 | UUID           | Primary key                            |
| name                 | name               | TEXT           | Required                               |
| icon_name            | iconName           | TEXT           | Optional                               |
| theme_color          | themeColor         | TEXT           | Optional (hex color code)              |
| image_url            | imageUrl           | TEXT           | Optional                               |
| display_order        | displayOrder       | INTEGER        | Default: 0                             |
| is_active            | isActive           | BOOLEAN        | Default: true                          |
| created_at           | createdAt          | TIMESTAMP      | Default: now()                         |
| updated_at           | updatedAt          | TIMESTAMP      | Default: now()                         |
| (derived)            | icon               | -              | Derived from icon_name                 |
| (derived)            | subCategories      | -              | Derived from subcategories table       |

### Database Table: `subcategories`

| Database Column      | Entity Property     | Data Type      | Notes                                   |
|----------------------|--------------------|----------------|----------------------------------------|
| id                   | id                 | UUID           | Primary key                            |
| name                 | name               | TEXT           | Required                               |
| category_id          | categoryId         | UUID           | Foreign key to categories table        |
| image_url            | imageUrl           | TEXT           | Optional                               |
| icon_name            | iconName           | TEXT           | Optional                               |
| display_order        | displayOrder       | INTEGER        | Default: 0                             |
| is_active            | isActive           | BOOLEAN        | Default: true                          |
| created_at           | createdAt          | TIMESTAMP      | Default: now()                         |
| updated_at           | updatedAt          | TIMESTAMP      | Default: now()                         |
| (derived)            | productCount       | -              | Derived from products table            |

## User and UserProfile

### Database Table: `users`

| Database Column      | Entity Property     | Data Type      | Notes                                   |
|----------------------|--------------------|----------------|----------------------------------------|
| id                   | id                 | UUID           | Primary key                            |
| email                | email              | TEXT           | Required, unique                       |
| phone                | phone              | TEXT           | Optional, unique                       |
| created_at           | createdAt          | TIMESTAMP      | Default: now()                         |
| updated_at           | updatedAt          | TIMESTAMP      | Default: now()                         |

### Database Table: `user_profiles`

| Database Column      | Entity Property     | Data Type      | Notes                                   |
|----------------------|--------------------|----------------|----------------------------------------|
| id                   | -                  | UUID           | Primary key                            |
| user_id              | -                  | UUID           | Foreign key to users table             |
| full_name            | name               | TEXT           | Optional                               |
| avatar_url           | profileImageUrl    | TEXT           | Optional                               |
| date_of_birth        | dateOfBirth        | DATE           | Optional                               |
| gender               | gender             | TEXT           | Optional                               |
| created_at           | -                  | TIMESTAMP      | Default: now()                         |
| updated_at           | -                  | TIMESTAMP      | Default: now()                         |

## Order and OrderItem

### Database Table: `orders`

| Database Column      | Entity Property     | Data Type      | Notes                                   |
|----------------------|--------------------|----------------|----------------------------------------|
| id                   | id                 | UUID           | Primary key                            |
| user_id              | userId             | UUID           | Foreign key to users table             |
| order_number         | orderNumber        | TEXT           | Required, unique                       |
| status               | status             | TEXT           | Default: 'pending'                     |
| total_amount         | totalAmount        | NUMERIC(10, 2) | Required                               |
| discount_amount      | discountAmount     | NUMERIC(10, 2) | Default: 0                             |
| delivery_fee         | deliveryFee        | NUMERIC(10, 2) | Default: 0                             |
| tax_amount           | taxAmount          | NUMERIC(10, 2) | Default: 0                             |
| final_amount         | finalAmount        | NUMERIC(10, 2) | Required                               |
| payment_method       | paymentMethod      | TEXT           | Optional                               |
| payment_status       | paymentStatus      | TEXT           | Default: 'pending'                     |
| coupon_id            | couponId           | UUID           | Foreign key to coupons table           |
| delivery_address_id  | deliveryAddressId  | UUID           | Foreign key to addresses table         |
| delivery_agent_id    | deliveryAgentId    | UUID           | Foreign key to delivery_agents table   |
| notes                | notes              | TEXT           | Optional                               |
| estimated_delivery_date | estimatedDeliveryDate | TIMESTAMP | Optional                               |
| delivered_at         | deliveredAt        | TIMESTAMP      | Optional                               |
| created_at           | createdAt          | TIMESTAMP      | Default: now()                         |
| updated_at           | updatedAt          | TIMESTAMP      | Default: now()                         |

### Database Table: `order_items`

| Database Column      | Entity Property     | Data Type      | Notes                                   |
|----------------------|--------------------|----------------|----------------------------------------|
| id                   | id                 | UUID           | Primary key                            |
| order_id             | orderId            | UUID           | Foreign key to orders table            |
| product_id           | productId          | UUID           | Foreign key to products table          |
| product_name         | productName        | TEXT           | Required                               |
| product_price        | unitPrice          | NUMERIC(10, 2) | Required                               |
| quantity             | quantity           | INTEGER        | Required                               |
| total_price          | totalPrice         | NUMERIC(10, 2) | Required                               |
| created_at           | createdAt          | TIMESTAMP      | Default: now()                         |
| updated_at           | updatedAt          | TIMESTAMP      | Default: now()                         |

## CartItem

### Database Table: `cart_items`

| Database Column      | Entity Property     | Data Type      | Notes                                   |
|----------------------|--------------------|----------------|----------------------------------------|
| id                   | id                 | UUID           | Primary key                            |
| user_id              | userId             | UUID           | Foreign key to users table             |
| product_id           | productId          | UUID           | Foreign key to products table          |
| quantity             | quantity           | INTEGER        | Default: 1                             |
| created_at           | createdAt          | TIMESTAMP      | Default: now()                         |
| updated_at           | updatedAt          | TIMESTAMP      | Default: now()                         |
| (derived)            | product            | -              | Derived from products table            |

## Wishlist

### Database Table: `wishlists`

| Database Column      | Entity Property     | Data Type      | Notes                                   |
|----------------------|--------------------|----------------|----------------------------------------|
| id                   | id                 | UUID           | Primary key                            |
| user_id              | userId             | UUID           | Foreign key to users table             |
| product_id           | productId          | UUID           | Foreign key to products table          |
| created_at           | createdAt          | TIMESTAMP      | Default: now()                         |
| updated_at           | updatedAt          | TIMESTAMP      | Default: now()                         |
| (derived)            | product            | -              | Derived from products table            |

## Review

### Database Table: `reviews`

| Database Column      | Entity Property     | Data Type      | Notes                                   |
|----------------------|--------------------|----------------|----------------------------------------|
| id                   | id                 | UUID           | Primary key                            |
| product_id           | productId          | UUID           | Foreign key to products table          |
| user_id              | userId             | UUID           | Foreign key to users table             |
| rating               | rating             | INTEGER        | Required (1-5)                         |
| comment              | comment            | TEXT           | Optional                               |
| is_verified          | isVerified         | BOOLEAN        | Default: false                         |
| created_at           | createdAt          | TIMESTAMP      | Default: now()                         |
| updated_at           | updatedAt          | TIMESTAMP      | Default: now()                         |

## Implementation Notes

1. **Naming Conventions**:
   - Database uses snake_case for column names
   - Entity properties use camelCase
   - Data sources should handle the conversion between these naming conventions

2. **Derived Properties**:
   - Some entity properties are derived from related tables or computed values
   - Data sources should handle these derivations when mapping database records to entities

3. **Timestamps**:
   - Most tables include created_at and updated_at columns
   - These should be mapped to DateTime objects in the entities

4. **Foreign Keys**:
   - Foreign key relationships in the database should be reflected in the entity relationships
   - Data sources should handle joining related tables when necessary

5. **Default Values**:
   - Default values in the database should be reflected in the entity constructors
