-- Updated schema with standardized data types
-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create custom types
CREATE TYPE order_status AS ENUM ('processing', 'out_for_delivery', 'delivered', 'cancelled');
CREATE TYPE payment_status AS ENUM ('pending', 'completed', 'failed', 'refunded');
CREATE TYPE payment_method AS ENUM ('creditCard', 'wallet', 'cashOnDelivery', 'upi');

-- USERS TABLE
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE NOT NULL,
    phone TEXT UNIQUE,
    full_name TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    avatar_url TEXT,
    role TEXT DEFAULT 'customer',
    last_login TIMESTAMP WITH TIME ZONE
);

-- PRODUCTS TABLE
CREATE TABLE IF NOT EXISTS products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    discount_price DECIMAL(10, 2),
    image_url TEXT,
    additional_images JSONB DEFAULT '[]'::JSONB,
    is_in_stock BOOLEAN DEFAULT TRUE,
    stock_quantity INTEGER DEFAULT 0,
    category_id UUID REFERENCES categories(id),
    brand TEXT,
    date_added TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    attributes JSONB DEFAULT '{}'::JSONB,
    is_featured BOOLEAN DEFAULT FALSE,
    is_on_sale BOOLEAN DEFAULT FALSE,
    rating DECIMAL(3, 1) DEFAULT 0.0,
    review_count INTEGER DEFAULT 0
);

-- ORDERS TABLE
CREATE TABLE IF NOT EXISTS orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id),
    total_amount DECIMAL(10, 2) NOT NULL,
    status order_status DEFAULT 'processing',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    shipping_address JSONB,
    billing_address JSONB,
    payment_method payment_method DEFAULT 'cashOnDelivery',
    payment_status payment_status DEFAULT 'pending',
    tracking_number TEXT,
    cancellation_reason TEXT,
    refund_amount DECIMAL(10, 2),
    address_lat DECIMAL(10, 6),
    address_lng DECIMAL(10, 6),
    driver_id UUID REFERENCES drivers(id),
    delivered_at TIMESTAMP WITH TIME ZONE
);

-- ORDER ITEMS TABLE
CREATE TABLE IF NOT EXISTS order_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id),
    name TEXT NOT NULL,
    image_url TEXT,
    quantity INTEGER NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    discount_amount DECIMAL(10, 2),
    attributes JSONB
);

-- CART ITEMS TABLE
CREATE TABLE IF NOT EXISTS cart_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id),
    quantity INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ADDRESSES TABLE
CREATE TABLE IF NOT EXISTS addresses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    address_line1 TEXT NOT NULL,
    address_line2 TEXT,
    city TEXT NOT NULL,
    state TEXT NOT NULL,
    postal_code TEXT NOT NULL,
    country TEXT NOT NULL DEFAULT 'India',
    phone_number TEXT NOT NULL,
    is_default BOOLEAN DEFAULT FALSE,
    lat DECIMAL(10, 6),
    lng DECIMAL(10, 6),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- PAYMENT METHODS TABLE
CREATE TABLE IF NOT EXISTS payment_methods (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    card_number TEXT,
    card_holder_name TEXT,
    expiry_date TEXT,
    card_type TEXT,
    upi_id TEXT,
    bank_name TEXT,
    is_default BOOLEAN DEFAULT FALSE,
    nick_name TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- DRIVERS TABLE
CREATE TABLE IF NOT EXISTS drivers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    vehicle_type TEXT,
    vehicle_number TEXT,
    license_number TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    current_lat DECIMAL(10, 6),
    current_lng DECIMAL(10, 6),
    last_location_update TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_orders_user ON orders(user_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_order_items_order ON order_items(order_id);
CREATE INDEX idx_cart_items_user ON cart_items(user_id);
CREATE INDEX idx_addresses_user ON addresses(user_id);
CREATE INDEX idx_payment_methods_user ON payment_methods(user_id);
CREATE INDEX idx_drivers_user ON drivers(user_id);







-- First add columns to addresses table
ALTER TABLE IF EXISTS addresses 
ADD COLUMN IF NOT EXISTS latitude DECIMAL(10,6),
ADD COLUMN IF NOT EXISTS longitude DECIMAL(10,6),
ADD COLUMN IF NOT EXISTS zone_id UUID REFERENCES zones(id);

-- Create zones table
CREATE TABLE IF NOT EXISTS zones (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT,
  delivery_fee DECIMAL(10,2),
  minimum_order_amount DECIMAL(10,2),
  is_active BOOLEAN DEFAULT TRUE,
  polygon GEOMETRY(POLYGON, 4326), -- SRID 4326 corresponds to WGS84 (GPS coordinates)
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index on zone geometry for faster spatial queries
CREATE INDEX IF NOT EXISTS idx_zones_polygon ON zones USING GIST (polygon);

-- Create index for zone_id in addresses table
CREATE INDEX IF NOT EXISTS idx_addresses_zone_id ON addresses(zone_id);

-- Add RLS policies for zones table
ALTER TABLE zones ENABLE ROW LEVEL SECURITY;

-- Create policy for admins (can do everything)
CREATE POLICY "Admins can do everything on zones" ON zones
  FOR ALL USING (
    auth.role() = 'authenticated' AND (
      EXISTS (
        SELECT 1 FROM users
        WHERE id = auth.uid() AND role = 'admin'
      )
    )
  );

-- Create policy for read-only access to all authenticated users
CREATE POLICY "All users can view active zones" ON zones
  FOR SELECT USING (
    auth.role() = 'authenticated' AND is_active = TRUE
  );

-- Function to determine zone based on coordinates
CREATE OR REPLACE FUNCTION get_zone_id_for_point(
  lat DECIMAL(10,6),
  lng DECIMAL(10,6)
) RETURNS UUID AS $$
DECLARE
  zone_id UUID;
BEGIN
  -- Create a point geometry from the coordinates
  SELECT id INTO zone_id FROM zones
  WHERE ST_Contains(polygon, ST_SetSRID(ST_MakePoint(lng, lat), 4326))
  AND is_active = TRUE
  LIMIT 1;
  
  RETURN zone_id;
END;
$$ LANGUAGE plpgsql;

-- Add a trigger to automatically update zone_id when lat/long change
CREATE OR REPLACE FUNCTION update_address_zone() RETURNS TRIGGER AS $$
BEGIN
  IF (NEW.latitude IS NOT NULL AND NEW.longitude IS NOT NULL) THEN
    NEW.zone_id := get_zone_id_for_point(NEW.latitude, NEW.longitude);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_address_zone
BEFORE INSERT OR UPDATE OF latitude, longitude
ON addresses
FOR EACH ROW
EXECUTE FUNCTION update_address_zone();