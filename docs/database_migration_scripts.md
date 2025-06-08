# Database Migration Scripts for Flexible Vendor Architecture

## Migration Overview

### **Migration Strategy:**
1. **Migration 1**: Enhance existing tables (backward compatible)
2. **Migration 2**: Add multi-vendor support tables
3. **Migration 3**: Add hybrid/dark store support
4. **Migration 4**: Migrate existing data
5. **Migration 5**: Add configuration management

## Migration 1: Enhance Existing Vendors Table

```sql
-- Migration 1: Enhance vendors table for flexibility
-- File: 001_enhance_vendors_table.sql

BEGIN;

-- Add new columns to vendors table
ALTER TABLE vendors ADD COLUMN IF NOT EXISTS vendor_type VARCHAR(20) DEFAULT 'external';
ALTER TABLE vendors ADD COLUMN IF NOT EXISTS operational_model VARCHAR(30) DEFAULT 'single_vendor';
ALTER TABLE vendors ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;
ALTER TABLE vendors ADD COLUMN IF NOT EXISTS priority_level INTEGER DEFAULT 1;
ALTER TABLE vendors ADD COLUMN IF NOT EXISTS operational_hours JSONB;
ALTER TABLE vendors ADD COLUMN IF NOT EXISTS delivery_radius_km DECIMAL(5,2) DEFAULT 5.0;
ALTER TABLE vendors ADD COLUMN IF NOT EXISTS avg_preparation_time_minutes INTEGER DEFAULT 30;
ALTER TABLE vendors ADD COLUMN IF NOT EXISTS commission_rate DECIMAL(5,2) DEFAULT 15.00;
ALTER TABLE vendors ADD COLUMN IF NOT EXISTS min_order_amount DECIMAL(10,2) DEFAULT 0;
ALTER TABLE vendors ADD COLUMN IF NOT EXISTS rating DECIMAL(3,2) DEFAULT 0;
ALTER TABLE vendors ADD COLUMN IF NOT EXISTS total_orders INTEGER DEFAULT 0;
ALTER TABLE vendors ADD COLUMN IF NOT EXISTS last_order_date DATE;

-- Add comments for documentation
COMMENT ON COLUMN vendors.vendor_type IS 'Type: external, dark_store, warehouse, micro_fulfillment';
COMMENT ON COLUMN vendors.operational_model IS 'Model: single_vendor, multi_vendor, hybrid, dark_store_only';
COMMENT ON COLUMN vendors.priority_level IS 'Priority level: 1 = highest priority';

-- Update existing vendors with default values
UPDATE vendors SET 
    vendor_type = 'external',
    operational_model = 'single_vendor',
    is_active = true,
    priority_level = 1,
    delivery_radius_km = 5.0,
    avg_preparation_time_minutes = 30,
    commission_rate = 15.00,
    min_order_amount = 0,
    rating = 0,
    total_orders = 0
WHERE vendor_type IS NULL;

COMMIT;
```

## Migration 2: Add Multi-Vendor Support Tables

```sql
-- Migration 2: Add multi-vendor support tables
-- File: 002_add_multi_vendor_tables.sql

BEGIN;

-- Vendor-Zone relationships table
CREATE TABLE IF NOT EXISTS vendor_zones (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vendor_id UUID REFERENCES vendors(id) ON DELETE CASCADE,
    zone_id UUID REFERENCES zones(id) ON DELETE CASCADE,
    is_active BOOLEAN DEFAULT true,
    priority INTEGER DEFAULT 1,
    commission_rate DECIMAL(5,2),
    is_primary_vendor BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(vendor_id, zone_id)
);

-- Vendor subcategory assignments table
CREATE TABLE IF NOT EXISTS vendor_subcategory_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vendor_id UUID REFERENCES vendors(id) ON DELETE CASCADE,
    subcategory_id UUID REFERENCES subcategories(id) ON DELETE CASCADE,
    zone_id UUID REFERENCES zones(id) ON DELETE CASCADE,
    is_exclusive BOOLEAN DEFAULT true,
    is_active BOOLEAN DEFAULT true,
    priority INTEGER DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(subcategory_id, zone_id)
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_vendor_zones_zone_active ON vendor_zones(zone_id, is_active);
CREATE INDEX IF NOT EXISTS idx_vendor_zones_primary ON vendor_zones(zone_id, is_primary_vendor) WHERE is_primary_vendor = true;
CREATE INDEX IF NOT EXISTS idx_vendor_subcategory_zone ON vendor_subcategory_assignments(zone_id, subcategory_id, is_active);

-- Add comments
COMMENT ON TABLE vendor_zones IS 'Defines which vendors operate in which zones';
COMMENT ON TABLE vendor_subcategory_assignments IS 'Assigns vendors to specific subcategories per zone';

COMMIT;
```

## Migration 3: Add Inventory and Allocation Tables

```sql
-- Migration 3: Add inventory and allocation management
-- File: 003_add_inventory_allocation_tables.sql

BEGIN;

-- Unified inventory management table
CREATE TABLE IF NOT EXISTS vendor_inventory (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vendor_id UUID REFERENCES vendors(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    zone_id UUID REFERENCES zones(id) ON DELETE CASCADE,
    
    -- Stock management
    stock_quantity INTEGER DEFAULT 0,
    reserved_quantity INTEGER DEFAULT 0,
    reorder_level INTEGER DEFAULT 10,
    max_stock_level INTEGER DEFAULT 100,
    
    -- Pricing
    cost_price DECIMAL(10,2),
    selling_price DECIMAL(10,2),
    discount_price DECIMAL(10,2),
    
    -- Availability
    is_available BOOLEAN DEFAULT true,
    availability_reason TEXT,
    
    -- Timestamps
    last_restocked_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(vendor_id, product_id, zone_id)
);

-- Allocation rules for hybrid model
CREATE TABLE IF NOT EXISTS inventory_allocation_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    zone_id UUID REFERENCES zones(id) ON DELETE CASCADE,
    subcategory_id UUID REFERENCES subcategories(id) ON DELETE CASCADE,
    
    allocation_strategy VARCHAR(50) DEFAULT 'single_vendor',
    vendor_priority_order JSONB,
    dark_store_priority INTEGER DEFAULT 1,
    vendor_fallback BOOLEAN DEFAULT true,
    
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(zone_id, subcategory_id)
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_vendor_inventory_zone_available ON vendor_inventory(zone_id, is_available, stock_quantity);
CREATE INDEX IF NOT EXISTS idx_vendor_inventory_product_zone ON vendor_inventory(product_id, zone_id, is_available);
CREATE INDEX IF NOT EXISTS idx_allocation_rules_zone_subcategory ON inventory_allocation_rules(zone_id, subcategory_id, is_active);

-- Add comments
COMMENT ON TABLE vendor_inventory IS 'Manages inventory for all vendors including dark stores';
COMMENT ON TABLE inventory_allocation_rules IS 'Defines allocation strategy for hybrid model';

COMMIT;
```

## Migration 4: Add System Configuration

```sql
-- Migration 4: Add system configuration management
-- File: 004_add_system_configuration.sql

BEGIN;

-- System configuration table
CREATE TABLE IF NOT EXISTS system_configuration (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    config_key VARCHAR(100) UNIQUE NOT NULL,
    config_value JSONB NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default configurations
INSERT INTO system_configuration (config_key, config_value, description) VALUES
('operational_mode', '"single_vendor"', 'Current operational mode: single_vendor, multi_vendor, or hybrid'),
('vendor_selection_strategy', '"primary_vendor"', 'How to select vendors: primary_vendor, subcategory_based, or smart_allocation'),
('dark_store_enabled', 'false', 'Whether dark store functionality is enabled'),
('multi_vendor_enabled', 'false', 'Whether multi-vendor functionality is enabled'),
('inventory_management_enabled', 'true', 'Whether inventory management is enabled'),
('auto_vendor_selection', 'true', 'Whether to automatically select best vendor'),
('commission_calculation_enabled', 'true', 'Whether to calculate vendor commissions')
ON CONFLICT (config_key) DO NOTHING;

-- Add index
CREATE INDEX IF NOT EXISTS idx_system_config_key ON system_configuration(config_key, is_active);

-- Add comments
COMMENT ON TABLE system_configuration IS 'System-wide configuration for vendor operations';

COMMIT;
```

## Migration 5: Migrate Existing Data

```sql
-- Migration 5: Migrate existing data to new structure
-- File: 005_migrate_existing_data.sql

BEGIN;

-- Step 1: Create vendor-zone relationships for existing vendors
INSERT INTO vendor_zones (vendor_id, zone_id, is_primary_vendor, priority, is_active)
SELECT DISTINCT 
    v.id as vendor_id,
    z.id as zone_id,
    true as is_primary_vendor,  -- Mark existing vendors as primary
    1 as priority,
    true as is_active
FROM vendors v
CROSS JOIN zones z
WHERE v.is_verified = true
ON CONFLICT (vendor_id, zone_id) DO NOTHING;

-- Step 2: Migrate existing product inventory to vendor_inventory
INSERT INTO vendor_inventory (
    vendor_id, 
    product_id, 
    zone_id, 
    stock_quantity, 
    selling_price, 
    is_available,
    created_at
)
SELECT DISTINCT
    p.vendor_id,
    p.id as product_id,
    z.id as zone_id,
    COALESCE(p.stock_quantity, 0) as stock_quantity,
    p.price as selling_price,
    p.is_active as is_available,
    NOW() as created_at
FROM products p
CROSS JOIN zones z
WHERE p.vendor_id IS NOT NULL
ON CONFLICT (vendor_id, product_id, zone_id) DO NOTHING;

-- Step 3: Set up default allocation rules for single vendor mode
INSERT INTO inventory_allocation_rules (
    zone_id,
    subcategory_id,
    allocation_strategy,
    is_active
)
SELECT DISTINCT
    z.id as zone_id,
    sc.id as subcategory_id,
    'single_vendor' as allocation_strategy,
    true as is_active
FROM zones z
CROSS JOIN subcategories sc
ON CONFLICT (zone_id, subcategory_id) DO NOTHING;

-- Step 4: Update system configuration to reflect current state
UPDATE system_configuration 
SET config_value = '"single_vendor"', updated_at = NOW()
WHERE config_key = 'operational_mode';

UPDATE system_configuration 
SET config_value = 'false', updated_at = NOW()
WHERE config_key = 'multi_vendor_enabled';

UPDATE system_configuration 
SET config_value = 'false', updated_at = NOW()
WHERE config_key = 'dark_store_enabled';

COMMIT;
```

## Migration 6: Add Helper Functions

```sql
-- Migration 6: Add helper functions for vendor operations
-- File: 006_add_helper_functions.sql

BEGIN;

-- Function to get current operational mode
CREATE OR REPLACE FUNCTION get_operational_mode()
RETURNS TEXT AS $$
BEGIN
    RETURN (
        SELECT config_value::text 
        FROM system_configuration 
        WHERE config_key = 'operational_mode' AND is_active = true
    );
END;
$$ LANGUAGE plpgsql;

-- Function to get vendors for a product in a zone
CREATE OR REPLACE FUNCTION get_vendors_for_product(
    p_product_id UUID,
    p_zone_id UUID
)
RETURNS TABLE(
    vendor_id UUID,
    vendor_name TEXT,
    vendor_type TEXT,
    stock_quantity INTEGER,
    selling_price DECIMAL,
    is_available BOOLEAN,
    priority INTEGER
) AS $$
DECLARE
    current_mode TEXT;
BEGIN
    current_mode := get_operational_mode();
    
    IF current_mode = 'single_vendor' THEN
        -- Single vendor mode: return primary vendor
        RETURN QUERY
        SELECT 
            v.id,
            v.name,
            v.vendor_type,
            vi.stock_quantity,
            vi.selling_price,
            vi.is_available,
            vz.priority
        FROM vendors v
        JOIN vendor_zones vz ON v.id = vz.vendor_id
        JOIN vendor_inventory vi ON v.id = vi.vendor_id
        WHERE vz.zone_id = p_zone_id 
          AND vz.is_primary_vendor = true
          AND vi.product_id = p_product_id
          AND vi.zone_id = p_zone_id
          AND v.is_active = true
          AND vz.is_active = true;
          
    ELSIF current_mode = 'multi_vendor' THEN
        -- Multi-vendor mode: return vendors based on subcategory assignment
        RETURN QUERY
        SELECT 
            v.id,
            v.name,
            v.vendor_type,
            vi.stock_quantity,
            vi.selling_price,
            vi.is_available,
            vsa.priority
        FROM vendors v
        JOIN vendor_subcategory_assignments vsa ON v.id = vsa.vendor_id
        JOIN vendor_inventory vi ON v.id = vi.vendor_id
        JOIN products p ON vi.product_id = p.id
        WHERE vsa.zone_id = p_zone_id
          AND vsa.subcategory_id = p.subcategory_id
          AND vi.product_id = p_product_id
          AND vi.zone_id = p_zone_id
          AND v.is_active = true
          AND vsa.is_active = true
          AND vi.is_available = true;
          
    ELSIF current_mode = 'hybrid' THEN
        -- Hybrid mode: return vendors based on allocation rules
        RETURN QUERY
        SELECT 
            v.id,
            v.name,
            v.vendor_type,
            vi.stock_quantity,
            vi.selling_price,
            vi.is_available,
            CASE 
                WHEN v.vendor_type = 'dark_store' THEN iar.dark_store_priority
                ELSE 2
            END as priority
        FROM vendors v
        JOIN vendor_zones vz ON v.id = vz.vendor_id
        JOIN vendor_inventory vi ON v.id = vi.vendor_id
        JOIN products p ON vi.product_id = p.id
        LEFT JOIN inventory_allocation_rules iar ON vz.zone_id = iar.zone_id AND p.subcategory_id = iar.subcategory_id
        WHERE vz.zone_id = p_zone_id
          AND vi.product_id = p_product_id
          AND vi.zone_id = p_zone_id
          AND v.is_active = true
          AND vz.is_active = true
          AND vi.is_available = true
        ORDER BY priority;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Function to switch operational mode
CREATE OR REPLACE FUNCTION switch_operational_mode(new_mode TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    IF new_mode NOT IN ('single_vendor', 'multi_vendor', 'hybrid') THEN
        RAISE EXCEPTION 'Invalid operational mode: %', new_mode;
    END IF;
    
    UPDATE system_configuration 
    SET config_value = to_jsonb(new_mode), updated_at = NOW()
    WHERE config_key = 'operational_mode';
    
    -- Update related configurations
    CASE new_mode
        WHEN 'single_vendor' THEN
            UPDATE system_configuration SET config_value = 'false' WHERE config_key = 'multi_vendor_enabled';
            UPDATE system_configuration SET config_value = 'false' WHERE config_key = 'dark_store_enabled';
        WHEN 'multi_vendor' THEN
            UPDATE system_configuration SET config_value = 'true' WHERE config_key = 'multi_vendor_enabled';
            UPDATE system_configuration SET config_value = 'false' WHERE config_key = 'dark_store_enabled';
        WHEN 'hybrid' THEN
            UPDATE system_configuration SET config_value = 'true' WHERE config_key = 'multi_vendor_enabled';
            UPDATE system_configuration SET config_value = 'true' WHERE config_key = 'dark_store_enabled';
    END CASE;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

COMMIT;
```

## Quick Execution Summary

### **To implement this architecture:**

1. **Run migrations in order** (001 through 006)
2. **Current state**: Single vendor mode with Dayliz Fresh
3. **Ready for**: Multi-vendor and dark store when needed

### **To switch modes later:**
```sql
-- Switch to multi-vendor mode
SELECT switch_operational_mode('multi_vendor');

-- Switch to hybrid mode  
SELECT switch_operational_mode('hybrid');

-- Switch back to single vendor
SELECT switch_operational_mode('single_vendor');
```

### **Test current setup:**
```sql
-- Test vendor selection for any product
SELECT * FROM get_vendors_for_product('product-id', 'zone-id');

-- Check current mode
SELECT get_operational_mode();
```

**This gives you complete flexibility - start simple, scale complex, all through database configuration!** 🚀

Would you like me to create the actual SQL files for you to execute these migrations?
