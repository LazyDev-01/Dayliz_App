-- Setup Test Vendor for Vendor Panel Development
-- This script creates a test vendor that can be used to login to the vendor panel

-- First, ensure the vendors table exists with all required columns
CREATE TABLE IF NOT EXISTS vendors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(200) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20),
    status VARCHAR(20) DEFAULT 'active',
    vendor_type VARCHAR(20) DEFAULT 'external',
    operational_model VARCHAR(30) DEFAULT 'single_vendor',
    is_active BOOLEAN DEFAULT true,
    priority_level INTEGER DEFAULT 1,
    operational_hours JSONB,
    delivery_radius_km DECIMAL(5,2) DEFAULT 5.0,
    avg_preparation_time_minutes INTEGER DEFAULT 30,
    commission_rate DECIMAL(5,2) DEFAULT 15.00,
    min_order_amount DECIMAL(10,2) DEFAULT 0,
    rating DECIMAL(3,2) DEFAULT 0,
    total_orders INTEGER DEFAULT 0,
    last_order_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert test vendor data
INSERT INTO vendors (
    name,
    email,
    phone,
    status,
    vendor_type,
    operational_model,
    is_active,
    priority_level,
    operational_hours,
    delivery_radius_km,
    avg_preparation_time_minutes,
    commission_rate,
    min_order_amount,
    rating,
    total_orders
) VALUES (
    'Test Grocery Store',
    'vendor@test.com',
    '+91-9876543210',
    'active',
    'external',
    'single_vendor',
    true,
    1,
    '{
        "monday": {"open": "09:00", "close": "21:00"},
        "tuesday": {"open": "09:00", "close": "21:00"},
        "wednesday": {"open": "09:00", "close": "21:00"},
        "thursday": {"open": "09:00", "close": "21:00"},
        "friday": {"open": "09:00", "close": "21:00"},
        "saturday": {"open": "09:00", "close": "22:00"},
        "sunday": {"open": "10:00", "close": "20:00"}
    }'::jsonb,
    5.0,
    20,
    12.50,
    200.00,
    4.2,
    156
) ON CONFLICT (email) DO UPDATE SET
    name = EXCLUDED.name,
    phone = EXCLUDED.phone,
    status = EXCLUDED.status,
    vendor_type = EXCLUDED.vendor_type,
    operational_model = EXCLUDED.operational_model,
    is_active = EXCLUDED.is_active,
    priority_level = EXCLUDED.priority_level,
    operational_hours = EXCLUDED.operational_hours,
    delivery_radius_km = EXCLUDED.delivery_radius_km,
    avg_preparation_time_minutes = EXCLUDED.avg_preparation_time_minutes,
    commission_rate = EXCLUDED.commission_rate,
    min_order_amount = EXCLUDED.min_order_amount,
    rating = EXCLUDED.rating,
    total_orders = EXCLUDED.total_orders,
    updated_at = NOW();

-- Note: The corresponding auth.users entry needs to be created manually through Supabase Auth
-- or through the Supabase dashboard with the following credentials:
-- Email: vendor@test.com
-- Password: vendor123456
-- 
-- This can be done by:
-- 1. Going to Supabase Dashboard > Authentication > Users
-- 2. Click "Add User"
-- 3. Enter email: vendor@test.com
-- 4. Enter password: vendor123456
-- 5. Click "Create User"

-- Verify the vendor was created
SELECT 
    id,
    name,
    email,
    phone,
    status,
    vendor_type,
    operational_model,
    is_active,
    rating,
    total_orders,
    created_at
FROM vendors 
WHERE email = 'vendor@test.com';
