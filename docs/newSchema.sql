-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create auth schema if it doesn't exist (for compatibility with Supabase)
CREATE SCHEMA IF NOT EXISTS auth;

-- Create custom types
CREATE TYPE user_role AS ENUM ('customer', 'admin', 'seller');
CREATE TYPE order_status AS ENUM ('pending', 'processing', 'shipped', 'delivered', 'cancelled');
CREATE TYPE payment_method AS ENUM ('creditCard', 'wallet', 'cashOnDelivery');
CREATE TYPE payment_status AS ENUM ('pending', 'completed', 'failed', 'refunded');

-- USERS TABLE
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE NOT NULL,
    phone TEXT UNIQUE,
    full_name TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    avatar_url TEXT,
    role user_role DEFAULT 'customer',
    last_login TIMESTAMP WITH TIME ZONE
);

-- USER PROFILES TABLE (extended user information)
CREATE TABLE IF NOT EXISTS user_profiles (
    id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    bio TEXT,
    date_of_birth DATE,
    gender TEXT,
    preferences JSONB DEFAULT '{}'::JSONB,
    notification_settings JSONB DEFAULT '{"marketing": false, "order_updates": true, "promotions": true}'::JSONB
);

-- ADDRESSES TABLE
CREATE TABLE IF NOT EXISTS addresses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    phone TEXT,
    address_line1 TEXT NOT NULL,
    address_line2 TEXT,
    city TEXT NOT NULL,
    state TEXT NOT NULL,
    postal_code TEXT NOT NULL,
    country TEXT NOT NULL DEFAULT 'India',
    is_default BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- CATEGORIES TABLE
CREATE TABLE IF NOT EXISTS categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    icon TEXT, -- icon name or code
    image_url TEXT,
    theme_color TEXT,
    parent_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    is_active BOOLEAN DEFAULT true,
    product_count INTEGER DEFAULT 0,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT unique_category_name UNIQUE (name)
);

-- PRODUCTS TABLE
CREATE TABLE IF NOT EXISTS products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    description TEXT,
    short_description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    discount_price DECIMAL(10, 2),
    stock_quantity INTEGER NOT NULL DEFAULT 0,
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    is_featured BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    brand TEXT,
    average_rating DECIMAL(3, 2) DEFAULT 0,
    review_count INTEGER DEFAULT 0,
    tags TEXT[],
    attributes JSONB DEFAULT '{}'::JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- PRODUCT IMAGES TABLE
CREATE TABLE IF NOT EXISTS product_images (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    alt_text TEXT,
    is_primary BOOLEAN DEFAULT false,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- BANNERS TABLE
CREATE TABLE IF NOT EXISTS banners (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    subtitle TEXT,
    image_url TEXT NOT NULL,
    mobile_image_url TEXT,
    link_url TEXT,
    link_type TEXT,
    link_id UUID,
    is_active BOOLEAN DEFAULT true,
    start_date TIMESTAMP WITH TIME ZONE,
    end_date TIMESTAMP WITH TIME ZONE,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- WISHLIST TABLE
CREATE TABLE IF NOT EXISTS wishlists (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, product_id)
);

-- CART ITEMS TABLE
CREATE TABLE IF NOT EXISTS cart_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL DEFAULT 1,
    selected_attributes JSONB DEFAULT '{}'::JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, product_id, selected_attributes)
);

-- ORDERS TABLE
CREATE TABLE IF NOT EXISTS orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE SET NULL,
    order_number TEXT UNIQUE NOT NULL,
    status order_status DEFAULT 'pending',
    total_amount DECIMAL(10, 2) NOT NULL,
    subtotal DECIMAL(10, 2) NOT NULL,
    shipping_fee DECIMAL(10, 2) NOT NULL DEFAULT 0,
    tax_amount DECIMAL(10, 2) NOT NULL DEFAULT 0,
    discount_amount DECIMAL(10, 2) NOT NULL DEFAULT 0,
    payment_method payment_method NOT NULL,
    payment_status payment_status DEFAULT 'pending',
    shipping_address JSONB NOT NULL,
    billing_address JSONB,
    notes TEXT,
    tracking_number TEXT,
    estimated_delivery_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ORDER ITEMS TABLE
CREATE TABLE IF NOT EXISTS order_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE SET NULL,
    product_name TEXT NOT NULL,
    quantity INTEGER NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    discount_amount DECIMAL(10, 2) DEFAULT 0,
    attributes JSONB DEFAULT '{}'::JSONB,
    image_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- REVIEWS TABLE
CREATE TABLE IF NOT EXISTS reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    order_item_id UUID REFERENCES order_items(id) ON DELETE SET NULL,
    rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
    review_text TEXT,
    is_verified_purchase BOOLEAN DEFAULT false,
    is_approved BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, product_id, order_item_id)
);

-- COUPONS TABLE
CREATE TABLE IF NOT EXISTS coupons (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code TEXT UNIQUE NOT NULL,
    description TEXT,
    discount_type TEXT NOT NULL CHECK (discount_type IN ('percentage', 'fixed')),
    discount_value DECIMAL(10, 2) NOT NULL,
    minimum_purchase DECIMAL(10, 2) DEFAULT 0,
    maximum_discount DECIMAL(10, 2),
    is_active BOOLEAN DEFAULT true,
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE NOT NULL,
    usage_limit INTEGER,
    usage_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- USER COUPONS TABLE
CREATE TABLE IF NOT EXISTS user_coupons (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    coupon_id UUID NOT NULL REFERENCES coupons(id) ON DELETE CASCADE,
    is_used BOOLEAN DEFAULT false,
    used_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, coupon_id)
);

-- NOTIFICATIONS TABLE
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    notification_type TEXT NOT NULL,
    reference_id UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- FUNCTIONS AND TRIGGERS

-- Function to update timestamps
CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at trigger to all tables with updated_at column
CREATE TRIGGER update_users_modtime
BEFORE UPDATE ON users
FOR EACH ROW EXECUTE PROCEDURE update_modified_column();

CREATE TRIGGER update_addresses_modtime
BEFORE UPDATE ON addresses
FOR EACH ROW EXECUTE PROCEDURE update_modified_column();

CREATE TRIGGER update_categories_modtime
BEFORE UPDATE ON categories
FOR EACH ROW EXECUTE PROCEDURE update_modified_column();

CREATE TRIGGER update_products_modtime
BEFORE UPDATE ON products
FOR EACH ROW EXECUTE PROCEDURE update_modified_column();

CREATE TRIGGER update_banners_modtime
BEFORE UPDATE ON banners
FOR EACH ROW EXECUTE PROCEDURE update_modified_column();

CREATE TRIGGER update_cart_items_modtime
BEFORE UPDATE ON cart_items
FOR EACH ROW EXECUTE PROCEDURE update_modified_column();

CREATE TRIGGER update_orders_modtime
BEFORE UPDATE ON orders
FOR EACH ROW EXECUTE PROCEDURE update_modified_column();

CREATE TRIGGER update_reviews_modtime
BEFORE UPDATE ON reviews
FOR EACH ROW EXECUTE PROCEDURE update_modified_column();

CREATE TRIGGER update_coupons_modtime
BEFORE UPDATE ON coupons
FOR EACH ROW EXECUTE PROCEDURE update_modified_column();

-- Function to update product rating on review change
CREATE OR REPLACE FUNCTION update_product_rating()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE products
    SET 
        average_rating = (
            SELECT COALESCE(AVG(rating), 0)
            FROM reviews
            WHERE product_id = NEW.product_id AND is_approved = true
        ),
        review_count = (
            SELECT COUNT(*)
            FROM reviews
            WHERE product_id = NEW.product_id AND is_approved = true
        )
    WHERE id = NEW.product_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for updating product rating on review changes
CREATE TRIGGER update_product_rating_on_review
AFTER INSERT OR UPDATE OR DELETE ON reviews
FOR EACH ROW EXECUTE PROCEDURE update_product_rating();

-- Function to update category product count
CREATE OR REPLACE FUNCTION update_category_product_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
        UPDATE categories
        SET product_count = (
            SELECT COUNT(*)
            FROM products
            WHERE category_id = NEW.category_id AND is_active = true
        )
        WHERE id = NEW.category_id;
        
        IF TG_OP = 'UPDATE' AND OLD.category_id IS DISTINCT FROM NEW.category_id THEN
            UPDATE categories
            SET product_count = (
                SELECT COUNT(*)
                FROM products
                WHERE category_id = OLD.category_id AND is_active = true
            )
            WHERE id = OLD.category_id;
        END IF;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE categories
        SET product_count = (
            SELECT COUNT(*)
            FROM products
            WHERE category_id = OLD.category_id AND is_active = true
        )
        WHERE id = OLD.category_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger for updating category product count
CREATE TRIGGER update_category_product_count_trigger
AFTER INSERT OR UPDATE OF category_id, is_active OR DELETE ON products
FOR EACH ROW EXECUTE PROCEDURE update_category_product_count();

-- Function to ensure only one default address per user
CREATE OR REPLACE FUNCTION ensure_single_default_address()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_default THEN
        UPDATE addresses
        SET is_default = false
        WHERE user_id = NEW.user_id AND id != NEW.id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for ensuring only one default address
CREATE TRIGGER ensure_single_default_address_trigger
BEFORE INSERT OR UPDATE OF is_default ON addresses
FOR EACH ROW
WHEN (NEW.is_default = true)
EXECUTE PROCEDURE ensure_single_default_address();

-- Function to generate order number
CREATE OR REPLACE FUNCTION generate_order_number()
RETURNS TRIGGER AS $$
BEGIN
    NEW.order_number = 'DLZ-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || 
                      LPAD(CAST(nextval('order_number_seq') AS TEXT), 4, '0');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create sequence for order numbers
CREATE SEQUENCE IF NOT EXISTS order_number_seq START 1;

-- Trigger for generating order numbers
CREATE TRIGGER generate_order_number_trigger
BEFORE INSERT ON orders
FOR EACH ROW EXECUTE PROCEDURE generate_order_number();

-- RLS POLICIES

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE addresses ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE banners ENABLE ROW LEVEL SECURITY;
ALTER TABLE wishlists ENABLE ROW LEVEL SECURITY;
ALTER TABLE cart_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE coupons ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_coupons ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Users policies
CREATE POLICY users_read_own ON users 
    FOR SELECT USING (auth.uid() = id OR auth.jwt() ->> 'role' = 'admin');

CREATE POLICY users_update_own ON users 
    FOR UPDATE USING (auth.uid() = id OR auth.jwt() ->> 'role' = 'admin');

-- User profiles policies
CREATE POLICY user_profiles_read_own ON user_profiles 
    FOR SELECT USING (auth.uid() = id OR auth.jwt() ->> 'role' = 'admin');

CREATE POLICY user_profiles_update_own ON user_profiles 
    FOR UPDATE USING (auth.uid() = id OR auth.jwt() ->> 'role' = 'admin');

-- Addresses policies
CREATE POLICY addresses_crud_own ON addresses 
    FOR ALL USING (auth.uid() = user_id OR auth.jwt() ->> 'role' = 'admin');

-- Categories policies
CREATE POLICY categories_read_all ON categories 
    FOR SELECT USING (true);

CREATE POLICY categories_admin_crud ON categories 
    FOR ALL USING (auth.jwt() ->> 'role' = 'admin');

-- Products policies
CREATE POLICY products_read_active ON products 
    FOR SELECT USING (is_active = true OR auth.jwt() ->> 'role' = 'admin');

CREATE POLICY products_admin_crud ON products 
    FOR ALL USING (auth.jwt() ->> 'role' = 'admin');

-- Product images policies
CREATE POLICY product_images_read_all ON product_images 
    FOR SELECT USING (true);

CREATE POLICY product_images_admin_crud ON product_images 
    FOR ALL USING (auth.jwt() ->> 'role' = 'admin');

-- Banners policies
CREATE POLICY banners_read_active ON banners 
    FOR SELECT USING (is_active = true OR auth.jwt() ->> 'role' = 'admin');

CREATE POLICY banners_admin_crud ON banners 
    FOR ALL USING (auth.jwt() ->> 'role' = 'admin');

-- Wishlists policies
CREATE POLICY wishlists_crud_own ON wishlists 
    FOR ALL USING (auth.uid() = user_id OR auth.jwt() ->> 'role' = 'admin');

-- Cart items policies
CREATE POLICY cart_items_crud_own ON cart_items 
    FOR ALL USING (auth.uid() = user_id OR auth.jwt() ->> 'role' = 'admin');

-- Orders policies
CREATE POLICY orders_read_own ON orders 
    FOR SELECT USING (auth.uid() = user_id OR auth.jwt() ->> 'role' = 'admin');

CREATE POLICY orders_create_own ON orders 
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY orders_admin_crud ON orders 
    FOR ALL USING (auth.jwt() ->> 'role' = 'admin');

-- Order items policies
CREATE POLICY order_items_read_own ON order_items 
    FOR SELECT USING (EXISTS (
        SELECT 1 FROM orders 
        WHERE orders.id = order_items.order_id 
        AND (orders.user_id = auth.uid() OR auth.jwt() ->> 'role' = 'admin')
    ));

CREATE POLICY order_items_admin_crud ON order_items 
    FOR ALL USING (auth.jwt() ->> 'role' = 'admin');

-- Reviews policies
CREATE POLICY reviews_read_all ON reviews 
    FOR SELECT USING (is_approved = true OR auth.jwt() ->> 'role' = 'admin');

CREATE POLICY reviews_create_own ON reviews 
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY reviews_update_own ON reviews 
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY reviews_admin_crud ON reviews 
    FOR ALL USING (auth.jwt() ->> 'role' = 'admin');

-- Coupons policies
CREATE POLICY coupons_read_active ON coupons 
    FOR SELECT USING (is_active = true OR auth.jwt() ->> 'role' = 'admin');

CREATE POLICY coupons_admin_crud ON coupons 
    FOR ALL USING (auth.jwt() ->> 'role' = 'admin');

-- User coupons policies
CREATE POLICY user_coupons_crud_own ON user_coupons 
    FOR ALL USING (auth.uid() = user_id OR auth.jwt() ->> 'role' = 'admin');

-- Notifications policies
CREATE POLICY notifications_crud_own ON notifications 
    FOR ALL USING (auth.uid() = user_id OR auth.jwt() ->> 'role' = 'admin');

-- Add indexes for performance
CREATE INDEX idx_products_category_id ON products(category_id);
CREATE INDEX idx_addresses_user_id ON addresses(user_id);
CREATE INDEX idx_cart_items_user_id ON cart_items(user_id);
CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_reviews_product_id ON reviews(product_id);
CREATE INDEX idx_wishlists_user_id ON wishlists(user_id);
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_product_images_product_id ON product_images(product_id);