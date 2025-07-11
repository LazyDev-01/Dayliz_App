# Hierarchical Implementation Roadmap
## REGION → ZONE → AREA + VENDOR-CATEGORY SYSTEM

## 🎯 IMPLEMENTATION PHASES

### **PHASE 2A: FOUNDATION (Week 1-2)**
**Priority: Build the hierarchical foundation**

#### Database Schema Implementation:
```sql
-- 1. Create hierarchical tables
CREATE TABLE regions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL,
  display_name VARCHAR(150) NOT NULL,
  status VARCHAR(20) DEFAULT 'active',
  operational_settings JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE zones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  region_id UUID REFERENCES regions(id),
  name VARCHAR(100) NOT NULL,
  display_name VARCHAR(150) NOT NULL,
  geofence_coordinates JSONB, -- Polygon coordinates
  status VARCHAR(20) DEFAULT 'active',
  delivery_settings JSONB,
  service_hours JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE areas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  zone_id UUID REFERENCES zones(id),
  name VARCHAR(100) NOT NULL,
  display_name VARCHAR(150) NOT NULL,
  geofence_polygon JSONB,
  pin_codes TEXT[],
  gps_coordinates JSONB,
  status VARCHAR(20) DEFAULT 'active',
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### Core Functions:
```sql
-- Location detection function
CREATE FUNCTION detect_user_zone(lat DECIMAL, lng DECIMAL) 
RETURNS TABLE(region_id UUID, zone_id UUID, area_id UUID);

-- Zone-based product filtering
CREATE FUNCTION get_zone_products(zone_id UUID, category_ids UUID[])
RETURNS TABLE(product_id UUID, vendor_id UUID, price DECIMAL, stock INTEGER);
```

#### Mobile App Changes:
```dart
// Add location detection service
class LocationService {
  Future<ZoneInfo> detectUserZone(double lat, double lng);
  Future<bool> isLocationInServiceArea(double lat, double lng);
}

// Update product service for zone-based filtering
class ProductService {
  Future<List<Product>> getZoneProducts(String zoneId);
  Future<List<Category>> getZoneCategories(String zoneId);
}
```

### **PHASE 2B: VENDOR-CATEGORY SYSTEM (Week 3-4)**
**Priority: Implement vendor specialization**

#### Vendor Management Schema:
```sql
CREATE TABLE vendors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(200) NOT NULL,
  contact_info JSONB,
  vendor_type VARCHAR(50), -- 'specialized', 'multi_category', 'darkstore'
  status VARCHAR(20) DEFAULT 'active',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL,
  display_name VARCHAR(150) NOT NULL,
  description TEXT,
  parent_category_id UUID REFERENCES categories(id),
  status VARCHAR(20) DEFAULT 'active',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE zone_vendor_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  zone_id UUID REFERENCES zones(id),
  vendor_id UUID REFERENCES vendors(id),
  category_id UUID REFERENCES categories(id),
  is_primary BOOLEAN DEFAULT true,
  status VARCHAR(20) DEFAULT 'active',
  assigned_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(zone_id, category_id) -- Prevents category overlap
);
```

#### Order Routing Logic:
```sql
CREATE FUNCTION route_order_to_vendor(
  zone_id UUID, 
  order_items JSONB[]
) RETURNS TABLE(vendor_id UUID, items JSONB[]);
```

### **PHASE 2C: GEOFENCING, WEATHER SYSTEM & ADMIN TOOLS (Month 2)**
**Priority: Complete the system with management tools and weather adaptability**

#### Geofencing Implementation:
```dart
class GeofencingService {
  Future<bool> isPointInPolygon(LatLng point, List<LatLng> polygon);
  Future<Area?> detectAreaFromLocation(double lat, double lng);
  Future<Zone?> getZoneFromArea(String areaId);
}
```

#### Weather-Adaptive Delivery System:
```sql
-- Weather rules table
CREATE TABLE weather_delivery_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  zone_id UUID REFERENCES zones(id),
  weather_condition VARCHAR(50), -- 'normal', 'rain', 'storm', 'extreme'
  delivery_fee_override DECIMAL(10,2),
  delivery_time_multiplier DECIMAL(3,2), -- 1.0 = normal, 1.5 = 50% longer
  service_suspended BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Weather monitoring function
CREATE FUNCTION get_current_weather_rules(zone_id UUID)
RETURNS TABLE(delivery_fee DECIMAL, time_multiplier DECIMAL, suspended BOOLEAN);
```

```dart
// Weather Service
class WeatherService {
  Future<WeatherCondition> getCurrentWeather(String zoneId);
  Future<DeliveryRules> getWeatherAdjustedRules(String zoneId);
  Future<void> notifyWeatherChange(String zoneId, WeatherCondition condition);
}

// Dynamic Pricing Service
class DynamicPricingService {
  Future<DeliveryFee> calculateDeliveryFee(double orderValue, String zoneId);
  Future<Duration> estimateDeliveryTime(String zoneId);
  Future<bool> isServiceAvailable(String zoneId);
}
```

#### Admin Dashboard Features:
```dart
// Region Management
class RegionManagement {
  Future<void> createRegion(RegionData data);
  Future<void> addZoneToRegion(String regionId, ZoneData data);
  Future<void> addAreaToZone(String zoneId, AreaData data);
}

// Vendor Assignment
class VendorManagement {
  Future<void> assignVendorToZone(String vendorId, String zoneId, List<String> categoryIds);
  Future<void> validateCategoryAssignment(String zoneId, String categoryId);
}

// Weather Management
class WeatherManagement {
  Future<void> setWeatherRules(String zoneId, WeatherRules rules);
  Future<void> suspendServiceForWeather(String zoneId, String reason);
  Future<void> resumeServiceAfterWeather(String zoneId);
}
```

## 🏗️ TECHNICAL ARCHITECTURE

### **User Journey Flow (Weather-Adaptive):**
```
1. User opens app
2. GPS detects location (lat, lng)
3. System calls detect_user_zone(lat, lng)
4. Returns: region_id, zone_id, area_id
5. Check current weather for zone
6. Apply weather-based delivery rules
7. Show adjusted delivery fee and time to user
8. App stores zone context + weather rules
9. Product catalog filtered by zone
10. Order placed → routed to correct vendor based on categories
11. Weather-adjusted delivery time communicated
12. Delivery assigned to zone-specific agent with weather briefing
```

### **Weather-Based Delivery Logic:**
```
Normal Weather (Clear/Cloudy):
├── Standard delivery fees apply
├── 15-30 minute delivery promise
└── Normal operations

Bad Weather (Rain/Light Storm):
├── ₹30 flat delivery fee (overrides all other rules)
├── 30-45 minute delivery promise
├── Weather surcharge notification to customer
└── Agent safety briefing

Extreme Weather (Heavy Storm/Flood):
├── Service suspended temporarily
├── Customer notification: "Service unavailable due to weather"
├── Estimated resumption time provided
└── Option to place order for later delivery
```

### **Vendor Assignment Logic:**
```
Zone A (Tura Main Bazar):
├── Vendor 1: Categories [Groceries, Staples]
├── Vendor 2: Categories [Fresh Produce, Dairy]
├── Vendor 3: Categories [Personal Care, Health]
└── Vendor 4: Categories [Snacks, Beverages]

Order with items from multiple categories:
├── Groceries → Vendor 1
├── Fresh Produce → Vendor 2
└── Personal Care → Vendor 3

Result: Order split across 3 vendors OR
Alternative: Route entire order to Multi-Category Vendor if available
```

### **Database Relationships:**
```
regions (1) → zones (many)
zones (1) → areas (many)
zones (1) → zone_vendor_categories (many)
vendors (1) → zone_vendor_categories (many)
categories (1) → zone_vendor_categories (many)
products (1) → zone_vendor_inventory (many)
```

## 🎯 SUCCESS METRICS

### **Phase 2A Success Criteria:**
- [ ] User location automatically detects zone
- [ ] Product catalog shows zone-specific items
- [ ] Orders route to correct zone
- [ ] Single zone (Tura) fully operational

### **Phase 2B Success Criteria:**
- [ ] Vendor-category assignments working
- [ ] No category conflicts in zones
- [ ] Orders route to correct vendor based on categories
- [ ] Multi-vendor order handling (if needed)

### **Phase 2C Success Criteria:**
- [ ] Admin can easily add new regions/zones/areas
- [ ] Geofencing accurately detects user areas
- [ ] Vendor management tools functional
- [ ] System ready for rapid expansion

## 🚀 EXPANSION STRATEGY

### **Adding New Zone (Post-Implementation):**
```
1. Admin creates new zone in region
2. Defines geofence boundaries for areas
3. Assigns vendors to categories
4. Sets up inventory for vendors
5. Assigns delivery agents
6. Zone goes live automatically
```

### **Adding New Region (Post-Implementation):**
```
1. Admin creates new region
2. Defines zones within region
3. Sets up areas with geofencing
4. Onboards regional vendors
5. Configures delivery network
6. Region operational in days, not months
```

This roadmap transforms your current single-zone system into a scalable, hierarchical multi-region platform while maintaining the simplicity of starting with just Tura Bazaar!
