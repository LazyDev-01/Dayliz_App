# Flexible Multi-Stage Vendor Database Architecture

## Design Philosophy

### **Backward & Forward Compatible Design:**
- **Stage 1**: Single vendor works with existing queries
- **Stage 2**: Multi-vendor enabled by configuration, not code changes
- **Stage 3**: Dark store added as special vendor type
- **Flexibility**: Switch between models anytime via database configuration

## Database Schema Design

### **1. Enhanced Vendors Table**
```sql
-- Enhanced vendors table to support all stages
ALTER TABLE vendors ADD COLUMN IF NOT EXISTS vendor_type VARCHAR(20) DEFAULT 'external';
-- Values: 'external', 'dark_store', 'warehouse', 'micro_fulfillment'

ALTER TABLE vendors ADD COLUMN IF NOT EXISTS operational_model VARCHAR(30) DEFAULT 'single_vendor';
-- Values: 'single_vendor', 'multi_vendor', 'hybrid', 'dark_store_only'

ALTER TABLE vendors ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;
ALTER TABLE vendors ADD COLUMN IF NOT EXISTS priority_level INTEGER DEFAULT 1;
-- Higher number = higher priority (1 = highest)

ALTER TABLE vendors ADD COLUMN IF NOT EXISTS operational_hours JSONB;
-- Example: {"monday": {"open": "09:00", "close": "21:00"}}

ALTER TABLE vendors ADD COLUMN IF NOT EXISTS delivery_radius_km DECIMAL(5,2) DEFAULT 5.0;
ALTER TABLE vendors ADD COLUMN IF NOT EXISTS avg_preparation_time_minutes INTEGER DEFAULT 30;
ALTER TABLE vendors ADD COLUMN IF NOT EXISTS commission_rate DECIMAL(5,2) DEFAULT 15.00;
ALTER TABLE vendors ADD COLUMN IF NOT EXISTS min_order_amount DECIMAL(10,2) DEFAULT 0;

-- Performance tracking
ALTER TABLE vendors ADD COLUMN IF NOT EXISTS rating DECIMAL(3,2) DEFAULT 0;
ALTER TABLE vendors ADD COLUMN IF NOT EXISTS total_orders INTEGER DEFAULT 0;
ALTER TABLE vendors ADD COLUMN IF NOT EXISTS last_order_date DATE;
```

### **2. Vendor-Zone Relationships (Multi-Vendor Ready)**
```sql
-- Vendor zone assignments (supports single and multi-vendor)
CREATE TABLE IF NOT EXISTS vendor_zones (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vendor_id UUID REFERENCES vendors(id) ON DELETE CASCADE,
    zone_id UUID REFERENCES zones(id) ON DELETE CASCADE,
    is_active BOOLEAN DEFAULT true,
    priority INTEGER DEFAULT 1, -- 1 = highest priority
    commission_rate DECIMAL(5,2), -- Can override vendor default
    is_primary_vendor BOOLEAN DEFAULT false, -- For single vendor mode
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(vendor_id, zone_id)
);

-- Index for performance
CREATE INDEX IF NOT EXISTS idx_vendor_zones_zone_active ON vendor_zones(zone_id, is_active);
CREATE INDEX IF NOT EXISTS idx_vendor_zones_primary ON vendor_zones(zone_id, is_primary_vendor) WHERE is_primary_vendor = true;
```

### **3. Subcategory-Vendor Assignments (Specialization Ready)**
```sql
-- Vendor subcategory specializations (for multi-vendor stage)
CREATE TABLE IF NOT EXISTS vendor_subcategory_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vendor_id UUID REFERENCES vendors(id) ON DELETE CASCADE,
    subcategory_id UUID REFERENCES subcategories(id) ON DELETE CASCADE,
    zone_id UUID REFERENCES zones(id) ON DELETE CASCADE,
    is_exclusive BOOLEAN DEFAULT true, -- Only this vendor handles this subcategory in this zone
    is_active BOOLEAN DEFAULT true,
    priority INTEGER DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(subcategory_id, zone_id) -- Ensures one vendor per subcategory per zone
);

-- Index for performance
CREATE INDEX IF NOT EXISTS idx_vendor_subcategory_zone ON vendor_subcategory_assignments(zone_id, subcategory_id, is_active);
```

### **4. Flexible Inventory Management**
```sql
-- Unified inventory table (works for vendors and dark stores)
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
    
    -- Pricing (can override product price)
    cost_price DECIMAL(10,2), -- Your cost (for dark stores)
    selling_price DECIMAL(10,2), -- Price to customer
    discount_price DECIMAL(10,2), -- Discounted price
    
    -- Availability
    is_available BOOLEAN DEFAULT true,
    availability_reason TEXT, -- "out_of_stock", "vendor_closed", etc.
    
    -- Timestamps
    last_restocked_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(vendor_id, product_id, zone_id)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_vendor_inventory_zone_available ON vendor_inventory(zone_id, is_available, stock_quantity);
CREATE INDEX IF NOT EXISTS idx_vendor_inventory_product_zone ON vendor_inventory(product_id, zone_id, is_available);
```

### **5. Smart Allocation Rules (Hybrid Model Ready)**
```sql
-- Allocation strategy configuration (for hybrid stage)
CREATE TABLE IF NOT EXISTS inventory_allocation_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    zone_id UUID REFERENCES zones(id) ON DELETE CASCADE,
    subcategory_id UUID REFERENCES subcategories(id) ON DELETE CASCADE,
    
    -- Allocation strategy
    allocation_strategy VARCHAR(50) DEFAULT 'single_vendor',
    -- Values: 'single_vendor', 'dark_store_first', 'vendor_first', 'price_optimized', 'delivery_optimized'
    
    -- Priority configuration
    vendor_priority_order JSONB, -- Array of vendor_ids in priority order
    dark_store_priority INTEGER DEFAULT 1,
    vendor_fallback BOOLEAN DEFAULT true,
    
    -- Active configuration
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(zone_id, subcategory_id)
);
```

### **6. Configuration Management**
```sql
-- System configuration for different operational modes
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
('multi_vendor_enabled', 'false', 'Whether multi-vendor functionality is enabled');
```

## Stage-by-Stage Implementation

### **Stage 1: Single Vendor (Current)**
```sql
-- Current setup: Mark Dayliz Fresh as primary vendor for all zones
INSERT INTO vendor_zones (vendor_id, zone_id, is_primary_vendor, priority) 
SELECT v.id, z.id, true, 1
FROM vendors v 
CROSS JOIN zones z 
WHERE v.name = 'Dayliz Fresh';

-- Migrate existing product inventory
INSERT INTO vendor_inventory (vendor_id, product_id, zone_id, stock_quantity, selling_price, is_available)
SELECT p.vendor_id, p.id, z.id, p.stock_quantity, p.price, p.is_active
FROM products p
CROSS JOIN zones z
WHERE p.vendor_id IS NOT NULL;

-- Set single vendor mode
UPDATE system_configuration 
SET config_value = '"single_vendor"' 
WHERE config_key = 'operational_mode';
```

### **Stage 2: Multi-Vendor Subcategory Specialization**
```sql
-- Example: Assign vendors to subcategories
-- Dayliz Fresh handles Rice & Grains
INSERT INTO vendor_subcategory_assignments (vendor_id, subcategory_id, zone_id, is_exclusive)
SELECT v.id, sc.id, z.id, true
FROM vendors v
CROSS JOIN subcategories sc
CROSS JOIN zones z
WHERE v.name = 'Dayliz Fresh' 
  AND sc.name = 'Rice & Grains';

-- Fresh Fruits Hub handles Fruits & Vegetables
INSERT INTO vendor_subcategory_assignments (vendor_id, subcategory_id, zone_id, is_exclusive)
SELECT v.id, sc.id, z.id, true
FROM vendors v
CROSS JOIN subcategories sc  
CROSS JOIN zones z
WHERE v.name = 'Fresh Fruits Hub'
  AND sc.name = 'Fruits & Vegetables';

-- Enable multi-vendor mode
UPDATE system_configuration 
SET config_value = '"multi_vendor"' 
WHERE config_key = 'operational_mode';

UPDATE system_configuration 
SET config_value = 'true' 
WHERE config_key = 'multi_vendor_enabled';
```

### **Stage 3: Hybrid Model (Multi-Vendor + Dark Store)**
```sql
-- Add dark store as special vendor
INSERT INTO vendors (id, name, vendor_type, operational_model, avg_preparation_time_minutes)
VALUES ('dayliz-darkstore-id', 'Dayliz Dark Store', 'dark_store', 'hybrid', 15);

-- Assign dark store to zones
INSERT INTO vendor_zones (vendor_id, zone_id, priority)
SELECT 'dayliz-darkstore-id', id, 1 -- Highest priority
FROM zones;

-- Set allocation rules for strategic products
INSERT INTO inventory_allocation_rules (zone_id, subcategory_id, allocation_strategy, dark_store_priority)
SELECT z.id, sc.id, 'dark_store_first', 1
FROM zones z
CROSS JOIN subcategories sc
WHERE sc.name IN ('Rice & Grains', 'Oil & Spices', 'Cleaning Supplies');

-- Enable hybrid mode
UPDATE system_configuration 
SET config_value = '"hybrid"' 
WHERE config_key = 'operational_mode';

UPDATE system_configuration 
SET config_value = 'true' 
WHERE config_key = 'dark_store_enabled';
```

## Flexible Query Patterns

### **Universal Vendor Selection Query**
```sql
-- This query works for all stages based on configuration
WITH operational_config AS (
    SELECT config_value::text AS mode 
    FROM system_configuration 
    WHERE config_key = 'operational_mode'
),
vendor_selection AS (
    CASE 
        WHEN (SELECT mode FROM operational_config) = 'single_vendor' THEN
            -- Single vendor mode: use primary vendor
            SELECT v.id as vendor_id, v.name as vendor_name, 1 as priority
            FROM vendors v
            JOIN vendor_zones vz ON v.id = vz.vendor_id
            WHERE vz.zone_id = $1 AND vz.is_primary_vendor = true
            
        WHEN (SELECT mode FROM operational_config) = 'multi_vendor' THEN
            -- Multi-vendor mode: use subcategory assignments
            SELECT v.id as vendor_id, v.name as vendor_name, vsa.priority
            FROM vendors v
            JOIN vendor_subcategory_assignments vsa ON v.id = vsa.vendor_id
            WHERE vsa.zone_id = $1 AND vsa.subcategory_id = $2 AND vsa.is_active = true
            
        WHEN (SELECT mode FROM operational_config) = 'hybrid' THEN
            -- Hybrid mode: use allocation rules
            SELECT v.id as vendor_id, v.name as vendor_name, 
                   CASE WHEN v.vendor_type = 'dark_store' THEN iar.dark_store_priority 
                        ELSE 2 END as priority
            FROM vendors v
            JOIN vendor_zones vz ON v.id = vz.vendor_id
            LEFT JOIN inventory_allocation_rules iar ON vz.zone_id = iar.zone_id
            WHERE vz.zone_id = $1 AND vz.is_active = true
    END
)
SELECT * FROM vendor_selection ORDER BY priority;
```

**This architecture gives you complete flexibility to start simple and scale complex, all through database configuration changes!** 🚀

Would you like me to create the migration scripts to implement this step by step?
