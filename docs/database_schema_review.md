# Database Schema Review

<!-- 2025-04-22: Initial database schema review for Supabase -->

## Current Database Structure

The current Supabase database includes the following key tables:

### Authentication Tables
- `auth.users`: Core user identity with login information
- `auth.refresh_tokens`: Used for JWT refresh
- `auth.instances`: Manages users across multiple sites
- `auth.audit_log_entries`: Maintains an audit trail for user actions
- `auth.schema_migrations`: Tracks auth system updates

### Storage Tables
- `storage.buckets`: Contains information about storage buckets
- `storage.objects`: Stores objects within the buckets
- `storage.migrations`: Tracks migration history for the storage schema

### Application Tables
These tables will need to be created or updated for the clean architecture:

- `profiles`: User profiles (to be created/updated)
- `addresses`: User addresses (to be created/updated)
- `products`: Product catalog (to be created/updated)
- `categories`: Product categories (to be created/updated)
- `orders`: Customer orders (to be created/updated)
- `order_items`: Items in an order (to be created/updated)
- `payment_methods`: User payment methods (to be created/updated)
- `wishlists`: User favorites/wishlist (to be created/updated)

## Schema Analysis and Issues

### Normalization Issues

1. **User-Address Relationship**
   - Addresses should be in a separate table (one-to-many)
   - Each address record should reference user_id
   - Separate table allows for multiple addresses per user

2. **Product Categories**
   - Current implementation has both categories array and categoryId
   - Should fully normalize to use category_id with foreign key constraint
   - Consider a many-to-many relationship table for products with multiple categories

3. **Order Data Structure**
   - Need to separate orders and order_items
   - Order items should reference both order_id and product_id
   - Order status should use enum type for consistency

### Data Integrity Constraints

1. **Missing Foreign Key Constraints**
   - Add explicit FK constraints between related tables
   - Ensure appropriate ON DELETE and ON UPDATE behaviors

2. **Inconsistent Default Values**
   - Standardize default values across similar fields
   - Use database defaults where appropriate

3. **Timestamps Management**
   - Add created_at and updated_at to all tables
   - Implement triggers to automatically update timestamps

### Performance Considerations

1. **Indexes**
   - Create indexes for frequently queried fields
   - Add composite indexes for multi-column searches
   - Consider partial indexes for filtered queries

2. **Denormalization Opportunities**
   - Cache computed values where appropriate
   - Add summary fields for frequently calculated values

3. **JSONB Usage**
   - Use JSONB for flexible data like product attributes
   - Add GIN indexes for JSONB search
   - Consider when to normalize vs. use JSONB

## Schema Optimization Plan

### Phase 1: Foundation Tables

1. **Create/Update Core Tables**

```sql
-- User profiles table
CREATE TABLE IF NOT EXISTS profiles (
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
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Addresses table
CREATE TABLE IF NOT EXISTS addresses (
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
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Categories table
CREATE TABLE IF NOT EXISTS categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT,
  image_url TEXT,
  parent_id UUID REFERENCES categories(id),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Products table
CREATE TABLE IF NOT EXISTS products (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  price DECIMAL(10, 2) NOT NULL,
  discount_price DECIMAL(10, 2),
  discount_percentage DECIMAL(5, 2),
  image_url TEXT NOT NULL,
  additional_images TEXT[],
  is_in_stock BOOLEAN DEFAULT true,
  stock_quantity INTEGER NOT NULL DEFAULT 0,
  category_id UUID REFERENCES categories(id),
  subcategory_id UUID REFERENCES categories(id),
  brand TEXT,
  attributes JSONB DEFAULT '{}'::jsonb,
  is_featured BOOLEAN DEFAULT false,
  is_on_sale BOOLEAN DEFAULT false,
  tags TEXT[],
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

2. **Create Product-Category Junction Table**

```sql
-- For many-to-many relationship between products and categories
CREATE TABLE IF NOT EXISTS product_categories (
  product_id UUID REFERENCES products(id) ON DELETE CASCADE,
  category_id UUID REFERENCES categories(id) ON DELETE CASCADE,
  PRIMARY KEY (product_id, category_id)
);
```

### Phase 2: Order and Transactional Tables

```sql
-- Orders table
CREATE TABLE IF NOT EXISTS orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id),
  status TEXT NOT NULL,
  total_amount DECIMAL(10, 2) NOT NULL,
  shipping_address_id UUID REFERENCES addresses(id),
  billing_address_id UUID REFERENCES addresses(id),
  payment_method_id UUID,
  shipping_method TEXT,
  shipping_cost DECIMAL(10, 2) DEFAULT 0,
  tax_amount DECIMAL(10, 2) DEFAULT 0,
  discount_amount DECIMAL(10, 2) DEFAULT 0,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Order items table
CREATE TABLE IF NOT EXISTS order_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id),
  quantity INTEGER NOT NULL DEFAULT 1,
  unit_price DECIMAL(10, 2) NOT NULL,
  total_price DECIMAL(10, 2) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Payment methods table
CREATE TABLE IF NOT EXISTS payment_methods (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  provider TEXT NOT NULL,
  is_default BOOLEAN DEFAULT false,
  payment_details JSONB NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Wishlists table
CREATE TABLE IF NOT EXISTS wishlists (
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  added_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  PRIMARY KEY (user_id, product_id)
);
```

### Phase 3: Indexes and Constraints

```sql
-- Add performance indexes
CREATE INDEX idx_addresses_user_id ON addresses(user_id);
CREATE INDEX idx_products_category_id ON products(category_id);
CREATE INDEX idx_products_is_featured ON products(is_featured) WHERE is_featured = true;
CREATE INDEX idx_products_is_on_sale ON products(is_on_sale) WHERE is_on_sale = true;
CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);
CREATE INDEX idx_wishlists_user_id ON wishlists(user_id);

-- Add JSONB indexes
CREATE INDEX idx_products_attributes ON products USING GIN (attributes);
CREATE INDEX idx_profiles_preferences ON profiles USING GIN (preferences);
```

### Phase 4: Triggers and Functions

```sql
-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to all tables with updated_at
CREATE TRIGGER update_profiles_timestamp
BEFORE UPDATE ON profiles
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_addresses_timestamp
BEFORE UPDATE ON addresses
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

-- ...repeat for all tables with updated_at column
```

## Data Migration Strategy

1. **Preparation**
   - Create backup of existing data
   - Set up staging environment for testing
   - Develop and test migration scripts

2. **Execution Steps**
   - Create new tables without dropping existing ones
   - Migrate data from old to new structure
   - Verify data integrity after migration
   - Switch application to use new tables
   - Archive old tables

3. **Rollback Plan**
   - Maintain archive of original data
   - Create restore scripts for emergency rollback
   - Test rollback procedure before production migration

## Conclusion and Recommendations

- Implement schema changes incrementally, starting with core tables
- Ensure proper indexing for performance optimization
- Add comprehensive constraints for data integrity
- Use JSONB strategically for flexible data without overusing
- Maintain upgrade and rollback scripts
- Test thoroughly before applying changes to production

Next steps:
1. Review and approve schema changes
2. Create migration scripts for each phase
3. Implement changes in development environment
4. Test with representative data volume 