-- Geofencing Database Schema for Dayliz App
-- Created for Tura Zone Implementation

-- =====================================================
-- TOWNS TABLE
-- =====================================================
-- Stores town-level settings (common for all zones in a town)
CREATE TABLE IF NOT EXISTS towns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  state TEXT NOT NULL,
  country TEXT DEFAULT 'India',
  
  -- Town-level delivery settings
  delivery_fee INTEGER DEFAULT 25,
  min_order_amount INTEGER DEFAULT 200,
  estimated_delivery_time TEXT DEFAULT '30-45 mins',
  currency TEXT DEFAULT 'INR',
  
  -- Town status
  is_active BOOLEAN DEFAULT true,
  launch_date DATE,
  
  -- Metadata
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Constraints
  UNIQUE(name, state)
);

-- =====================================================
-- ZONES TABLE
-- =====================================================
-- Stores individual delivery zones with geofencing data
CREATE TABLE IF NOT EXISTS zones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  town_id UUID REFERENCES towns(id) ON DELETE CASCADE,
  zone_number INTEGER NOT NULL, -- 1, 2, 3, etc.
  
  -- Geofencing data
  zone_type TEXT NOT NULL CHECK (zone_type IN ('polygon', 'circle')),
  
  -- For polygon zones (hilly/irregular areas)
  boundary_coordinates JSONB, -- Array of {lat, lng} objects
  
  -- For circular zones (flat urban areas)
  center_lat DECIMAL(10,8),
  center_lng DECIMAL(11,8),
  radius_km DECIMAL(5,2),
  
  -- Zone-specific overrides (optional)
  custom_delivery_fee INTEGER, -- Override town default
  custom_min_order INTEGER,    -- Override town default
  custom_delivery_time TEXT,   -- Override town default
  
  -- Zone status
  is_active BOOLEAN DEFAULT true,
  priority INTEGER DEFAULT 1, -- Higher priority zones checked first
  
  -- Metadata
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Constraints
  UNIQUE(town_id, zone_number),
  CHECK (
    (zone_type = 'polygon' AND boundary_coordinates IS NOT NULL) OR
    (zone_type = 'circle' AND center_lat IS NOT NULL AND center_lng IS NOT NULL AND radius_km IS NOT NULL)
  )
);

-- =====================================================
-- ZONE PRODUCTS TABLE (Optional - for zone-specific products)
-- =====================================================
CREATE TABLE IF NOT EXISTS zone_products (
  zone_id UUID REFERENCES zones(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id) ON DELETE CASCADE,
  is_available BOOLEAN DEFAULT true,
  zone_specific_price INTEGER, -- Override default product price
  stock_quantity INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  PRIMARY KEY (zone_id, product_id)
);

-- =====================================================
-- USER LOCATIONS TABLE
-- =====================================================
-- Stores user's selected/detected locations
CREATE TABLE IF NOT EXISTS user_locations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Location data
  latitude DECIMAL(10,8) NOT NULL,
  longitude DECIMAL(11,8) NOT NULL,
  address_text TEXT,
  formatted_address TEXT,
  place_id TEXT, -- Google Places ID
  
  -- Zone assignment
  zone_id UUID REFERENCES zones(id),
  town_id UUID REFERENCES towns(id),
  
  -- Location metadata
  location_type TEXT DEFAULT 'manual', -- 'gps', 'manual', 'search'
  is_primary BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_zones_town_id ON zones(town_id);
CREATE INDEX IF NOT EXISTS idx_zones_active ON zones(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_zones_priority ON zones(priority DESC);
CREATE INDEX IF NOT EXISTS idx_user_locations_user_id ON user_locations(user_id);
CREATE INDEX IF NOT EXISTS idx_user_locations_zone_id ON user_locations(zone_id);
CREATE INDEX IF NOT EXISTS idx_user_locations_primary ON user_locations(is_primary) WHERE is_primary = true;

-- =====================================================
-- SAMPLE DATA FOR TURA
-- =====================================================
-- Insert Tura town
INSERT INTO towns (name, state, delivery_fee, min_order_amount, estimated_delivery_time, launch_date, is_active)
VALUES ('Tura', 'Meghalaya', 25, 200, '30-45 mins', CURRENT_DATE, true)
ON CONFLICT (name, state) DO NOTHING;

-- Get Tura town ID for zone insertion
-- Note: Actual zone coordinates will be added later when you provide them
INSERT INTO zones (
  name, 
  town_id, 
  zone_number, 
  zone_type, 
  boundary_coordinates,
  description,
  is_active
) 
SELECT 
  'Zone-1 Main Bazaar Area',
  t.id,
  1,
  'polygon',
  '[]'::jsonb, -- Placeholder - will be updated with real coordinates
  'Primary delivery zone covering Main Bazaar and surrounding 5-6 areas in Tura',
  true
FROM towns t 
WHERE t.name = 'Tura' AND t.state = 'Meghalaya'
ON CONFLICT (town_id, zone_number) DO NOTHING;

-- =====================================================
-- FUNCTIONS FOR GEOFENCING
-- =====================================================

-- Function to check if a point is inside a polygon zone
CREATE OR REPLACE FUNCTION point_in_polygon(
  point_lat DECIMAL(10,8),
  point_lng DECIMAL(11,8),
  polygon_coords JSONB
) RETURNS BOOLEAN AS $$
DECLARE
  coords JSONB;
  i INTEGER;
  j INTEGER;
  inside BOOLEAN := false;
  xi DECIMAL;
  yi DECIMAL;
  xj DECIMAL;
  yj DECIMAL;
BEGIN
  -- Ray casting algorithm for point-in-polygon
  coords := polygon_coords;
  
  FOR i IN 0..jsonb_array_length(coords) - 1 LOOP
    j := (i + 1) % jsonb_array_length(coords);
    
    xi := (coords->i->>'lng')::DECIMAL;
    yi := (coords->i->>'lat')::DECIMAL;
    xj := (coords->j->>'lng')::DECIMAL;
    yj := (coords->j->>'lat')::DECIMAL;
    
    IF ((yi > point_lat) != (yj > point_lat)) AND 
       (point_lng < (xj - xi) * (point_lat - yi) / (yj - yi) + xi) THEN
      inside := NOT inside;
    END IF;
  END LOOP;
  
  RETURN inside;
END;
$$ LANGUAGE plpgsql;

-- Function to check if a point is inside a circular zone
CREATE OR REPLACE FUNCTION point_in_circle(
  point_lat DECIMAL(10,8),
  point_lng DECIMAL(11,8),
  center_lat DECIMAL(10,8),
  center_lng DECIMAL(11,8),
  radius_km DECIMAL(5,2)
) RETURNS BOOLEAN AS $$
DECLARE
  distance_km DECIMAL;
BEGIN
  -- Calculate distance using Haversine formula (simplified)
  distance_km := ST_Distance(
    ST_Point(point_lng, point_lat)::geography,
    ST_Point(center_lng, center_lat)::geography
  ) / 1000;
  
  RETURN distance_km <= radius_km;
END;
$$ LANGUAGE plpgsql;

-- Function to find zone for a given coordinate
CREATE OR REPLACE FUNCTION find_zone_for_coordinates(
  user_lat DECIMAL(10,8),
  user_lng DECIMAL(11,8)
) RETURNS TABLE(
  zone_id UUID,
  zone_name TEXT,
  town_name TEXT,
  delivery_fee INTEGER,
  min_order_amount INTEGER,
  estimated_delivery_time TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    z.id,
    z.name,
    t.name,
    COALESCE(z.custom_delivery_fee, t.delivery_fee),
    COALESCE(z.custom_min_order, t.min_order_amount),
    COALESCE(z.custom_delivery_time, t.estimated_delivery_time)
  FROM zones z
  JOIN towns t ON z.town_id = t.id
  WHERE z.is_active = true 
    AND t.is_active = true
    AND (
      (z.zone_type = 'polygon' AND point_in_polygon(user_lat, user_lng, z.boundary_coordinates)) OR
      (z.zone_type = 'circle' AND point_in_circle(user_lat, user_lng, z.center_lat, z.center_lng, z.radius_km))
    )
  ORDER BY z.priority DESC
  LIMIT 1;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- ROW LEVEL SECURITY (Optional)
-- =====================================================
-- Enable RLS for user_locations
ALTER TABLE user_locations ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own locations
CREATE POLICY user_locations_policy ON user_locations
  FOR ALL USING (auth.uid() = user_id);

-- =====================================================
-- TRIGGERS FOR UPDATED_AT
-- =====================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_towns_updated_at
  BEFORE UPDATE ON towns
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_zones_updated_at
  BEFORE UPDATE ON zones
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_locations_updated_at
  BEFORE UPDATE ON user_locations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
