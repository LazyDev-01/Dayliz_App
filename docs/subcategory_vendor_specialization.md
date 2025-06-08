# Subcategory-Level Vendor Specialization Model

## Current Dayliz Category Structure

### **Your 4 Main Categories:**
1. **Grocery & Kitchen**
2. **Snacks & Drinks** 
3. **Beauty & Hygiene**
4. **Household & Essentials**

### **Subcategories Under Each Category:**

#### 1. Grocery & Kitchen
- 🍎 Fruits & Vegetables
- 🌾 Rice & Grains
- 🛢️ Oil & Spices
- 🥛 Dairy Products
- 🍖 Meat & Seafood (if applicable)

#### 2. Snacks & Drinks
- 🍪 Biscuits & Cookies
- 🥤 Beverages & Drinks
- 🍿 Chips & Namkeen
- 🍫 Chocolates & Sweets

#### 3. Beauty & Hygiene
- 🧴 Personal Care
- 💄 Beauty Products
- 🦷 Oral Care
- 👶 Baby Care

#### 4. Household & Essentials
- 🧽 Cleaning Supplies
- 📝 Stationery
- 🔋 Electronics & Accessories
- 🏠 Home Decor

## Vendor Specialization Assignment (Tura Zone 1)

### **Subcategory-Level Vendor Mapping:**

```sql
-- Sample vendor assignments for Tura Zone 1
INSERT INTO vendor_subcategory_assignments (vendor_id, subcategory_id, zone_id) VALUES

-- Grocery & Kitchen subcategories
('fresh-fruits-hub-id', 'fruits-vegetables-subcategory-id', 'tura-zone-1'),
('grain-master-id', 'rice-grains-subcategory-id', 'tura-zone-1'),
('spice-palace-id', 'oil-spices-subcategory-id', 'tura-zone-1'),
('dairy-fresh-id', 'dairy-products-subcategory-id', 'tura-zone-1'),

-- Snacks & Drinks subcategories  
('snack-junction-id', 'biscuits-cookies-subcategory-id', 'tura-zone-1'),
('beverage-corner-id', 'beverages-drinks-subcategory-id', 'tura-zone-1'),
('namkeen-house-id', 'chips-namkeen-subcategory-id', 'tura-zone-1'),
('sweet-shop-id', 'chocolates-sweets-subcategory-id', 'tura-zone-1'),

-- Beauty & Hygiene subcategories
('beauty-corner-id', 'personal-care-subcategory-id', 'tura-zone-1'),
('cosmetics-store-id', 'beauty-products-subcategory-id', 'tura-zone-1'),
('health-care-id', 'oral-care-subcategory-id', 'tura-zone-1'),
('baby-world-id', 'baby-care-subcategory-id', 'tura-zone-1'),

-- Household & Essentials subcategories
('clean-home-id', 'cleaning-supplies-subcategory-id', 'tura-zone-1'),
('office-mart-id', 'stationery-subcategory-id', 'tura-zone-1'),
('tech-corner-id', 'electronics-accessories-subcategory-id', 'tura-zone-1'),
('home-decor-id', 'home-decor-subcategory-id', 'tura-zone-1');
```

## Product-Vendor Mapping Query

### **How to Find Vendor for Any Product:**

```sql
-- Find which vendor sells "Organic Bananas" in Tura Zone 1
SELECT 
    p.name as product_name,
    sc.name as subcategory_name,
    c.name as category_name,
    v.name as vendor_name,
    v.contact_phone,
    vi.stock_quantity,
    vi.is_available
FROM products p
JOIN subcategories sc ON p.subcategory_id = sc.id
JOIN categories c ON sc.category_id = c.id
JOIN vendor_subcategory_assignments vsa ON sc.id = vsa.subcategory_id
JOIN vendors v ON vsa.vendor_id = v.id
LEFT JOIN vendor_inventory vi ON v.id = vi.vendor_id 
    AND p.id = vi.product_id 
    AND vi.zone_id = vsa.zone_id
WHERE p.name = 'Organic Bananas'
    AND vsa.zone_id = 'tura-zone-1-id';

-- Result:
-- Organic Bananas | Fruits & Vegetables | Grocery & Kitchen | Fresh Fruits Hub | +91-xxx | 50 | true
```

## API Implementation Example

### **Get Products by Subcategory:**

```javascript
// API: GET /api/subcategories/fruits-vegetables/products?zone_id=tura-zone-1

async function getProductsBySubcategory(subcategoryId, zoneId) {
    const query = `
        SELECT 
            p.id,
            p.name,
            p.price,
            p.main_image_url,
            v.name as vendor_name,
            v.id as vendor_id,
            v.rating as vendor_rating,
            v.avg_preparation_time_minutes,
            vi.stock_quantity,
            vi.is_available,
            sc.name as subcategory_name,
            c.name as category_name
        FROM products p
        JOIN subcategories sc ON p.subcategory_id = sc.id
        JOIN categories c ON sc.category_id = c.id
        JOIN vendor_subcategory_assignments vsa ON sc.id = vsa.subcategory_id
        JOIN vendors v ON vsa.vendor_id = v.id
        LEFT JOIN vendor_inventory vi ON v.id = vi.vendor_id 
            AND p.id = vi.product_id 
            AND vi.zone_id = $2
        WHERE p.subcategory_id = $1 
            AND vsa.zone_id = $2
            AND p.is_active = true
            AND v.is_active = true
        ORDER BY p.name;
    `;
    
    return await db.query(query, [subcategoryId, zoneId]);
}
```

### **API Response Example:**

```json
{
    "subcategory": "Fruits & Vegetables",
    "category": "Grocery & Kitchen", 
    "zone": "Tura Zone 1",
    "assigned_vendor": {
        "vendor_id": "fresh-fruits-hub-id",
        "vendor_name": "Fresh Fruits Hub",
        "specialization": "Fruits & Vegetables specialist",
        "rating": 4.5,
        "avg_delivery_time": "30 minutes"
    },
    "products": [
        {
            "product_id": "organic-bananas-id",
            "name": "Organic Bananas",
            "price": 60.00,
            "stock_quantity": 50,
            "is_available": true,
            "vendor_name": "Fresh Fruits Hub"
        },
        {
            "product_id": "fresh-tomatoes-id", 
            "name": "Fresh Tomatoes",
            "price": 40.00,
            "stock_quantity": 30,
            "is_available": true,
            "vendor_name": "Fresh Fruits Hub"
        }
    ]
}
```

## User Shopping Experience

### **Category → Subcategory → Products Flow:**

```
User Journey:
1. Browse Categories → "Grocery & Kitchen"
2. Browse Subcategories → "Fruits & Vegetables" 
3. See Products → All from "Fresh Fruits Hub"
4. Add to Cart → Automatic vendor assignment
5. Continue Shopping → "Rice & Grains" subcategory
6. See Products → All from "Grain Master Store"
7. Checkout → Mixed vendor order (2 vendors)
```

### **Cart Example:**

```json
{
    "cart_summary": {
        "total_vendors": 2,
        "vendors": [
            {
                "vendor_name": "Fresh Fruits Hub",
                "specialization": "Fruits & Vegetables",
                "items": [
                    {"product": "Organic Bananas", "price": 60.00},
                    {"product": "Fresh Tomatoes", "price": 40.00}
                ],
                "subtotal": 100.00,
                "delivery_fee": 25.00
            },
            {
                "vendor_name": "Grain Master Store", 
                "specialization": "Rice & Grains",
                "items": [
                    {"product": "Basmati Rice", "price": 120.00}
                ],
                "subtotal": 120.00,
                "delivery_fee": 25.00
            }
        ],
        "grand_total": 270.00
    }
}
```

## Benefits of Subcategory-Level Assignment

### **1. True Specialization:**
- 🍎 **Fruit vendors** → Expert in freshness, seasonal availability
- 🌾 **Grain vendors** → Expert in quality, storage, varieties
- 🛢️ **Spice vendors** → Expert in authenticity, sourcing, blends

### **2. Better Quality Control:**
- Vendors focus on specific product expertise
- Better supplier relationships in specialized areas
- Quality consistency within subcategories

### **3. Operational Efficiency:**
- Faster order fulfillment (vendors know their products well)
- Better inventory management (specialized stock)
- Reduced vendor conflicts (clear boundaries)

### **4. Scalable Business Model:**
- Easy to add new vendors for specific subcategories
- Can have backup vendors for critical subcategories
- Zone expansion with specialized vendor recruitment

### **5. Real-World Business Logic:**
```
Real World Example:
- Fresh Fruits Hub → Knows seasonal fruits, storage, freshness
- Grain Master → Knows rice varieties, quality grades, storage
- Spice Palace → Knows spice authenticity, blends, sourcing
- Dairy Fresh → Knows cold chain, expiry management, freshness
```

## Migration from Current Setup

### **Current State:**
- Dayliz Fresh handles ALL products
- No specialization

### **Target State:**
- Dayliz Fresh → Specialized in one subcategory (e.g., "Rice & Grains")
- Add specialized vendors for other subcategories
- Gradual migration subcategory by subcategory

**This subcategory-level specialization gives you the perfect balance of vendor expertise and operational simplicity!** 🎯

Would you like me to create the migration plan to move from your current single-vendor setup to this specialized subcategory model?
