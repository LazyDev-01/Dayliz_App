# Multi-Vendor Workflow Example: Two Vendors in Tura Zone 1

## Scenario Setup

### Vendors in Tura Zone 1:
1. **Dayliz Fresh** (Existing vendor)
2. **Local Fruits Store** (New local vendor)

### Sample Database Data:

#### Vendors Table:
```sql
-- Vendor 1: Dayliz Fresh (existing)
INSERT INTO vendors (id, name, description, contact_phone, rating, avg_preparation_time_minutes, is_active) VALUES
('07892607-bfb3-4671-95a5-e5e2dddfefe3', 'Dayliz Fresh', 'Premium quality fresh products', '+91 9876543210', 4.2, 25, true);

-- Vendor 2: Local Fruits Store (new)
INSERT INTO vendors (id, name, description, contact_phone, rating, avg_preparation_time_minutes, is_active) VALUES
('12345678-abcd-4671-95a5-e5e2dddfefe4', 'Local Fruits Store', 'Fresh local fruits and vegetables', '+91 9876543211', 4.5, 35, true);
```

#### Vendor-Zone Relationships:
```sql
INSERT INTO vendor_zones (vendor_id, zone_id, is_active, priority, commission_rate) VALUES
('07892607-bfb3-4671-95a5-e5e2dddfefe3', '0065483d-4249-4919-8122-4d051241ac2b', true, 1, 15.00),
('12345678-abcd-4671-95a5-e5e2dddfefe4', '0065483d-4249-4919-8122-4d051241ac2b', true, 2, 12.00);
```

#### Vendor Inventory:
```sql
-- Dayliz Fresh inventory
INSERT INTO vendor_inventory (vendor_id, product_id, zone_id, stock_quantity, selling_price, discount_price, is_available) VALUES
('07892607-bfb3-4671-95a5-e5e2dddfefe3', 'banana-product-id', '0065483d-4249-4919-8122-4d051241ac2b', 50, 60.00, null, true),
('07892607-bfb3-4671-95a5-e5e2dddfefe3', 'milk-product-id', '0065483d-4249-4919-8122-4d051241ac2b', 100, 25.00, null, true);

-- Local Fruits Store inventory
INSERT INTO vendor_inventory (vendor_id, product_id, zone_id, stock_quantity, selling_price, discount_price, is_available) VALUES
('12345678-abcd-4671-95a5-e5e2dddfefe4', 'banana-product-id', '0065483d-4249-4919-8122-4d051241ac2b', 30, 55.00, null, true);
-- Note: Local Fruits Store doesn't sell milk
```

## Step-by-Step Workflow

### 1. User Location Detection
```json
// API Call: POST /api/location/detect
{
  "latitude": 25.5138,
  "longitude": 90.2065
}

// Response:
{
  "zone_id": "0065483d-4249-4919-8122-4d051241ac2b",
  "zone_name": "Tura Zone 1",
  "delivery_available": true
}
```

### 2. Product Browsing - Organic Bananas
```json
// API Call: GET /api/products/banana-product-id/vendors?zone_id=0065483d-4249-4919-8122-4d051241ac2b

// Response:
{
  "product_id": "banana-product-id",
  "product_name": "Organic Bananas",
  "available_vendors": [
    {
      "vendor_id": "07892607-bfb3-4671-95a5-e5e2dddfefe3",
      "vendor_name": "Dayliz Fresh",
      "price": 60.00,
      "discount_price": null,
      "stock_quantity": 50,
      "rating": 4.2,
      "estimated_delivery_minutes": 25,
      "is_available": true
    },
    {
      "vendor_id": "12345678-abcd-4671-95a5-e5e2dddfefe4",
      "vendor_name": "Local Fruits Store",
      "price": 55.00,
      "discount_price": null,
      "stock_quantity": 30,
      "rating": 4.5,
      "estimated_delivery_minutes": 35,
      "is_available": true
    }
  ],
  "recommended_vendor": {
    "vendor_id": "12345678-abcd-4671-95a5-e5e2dddfefe4",
    "reason": "Best price (₹55 vs ₹60) with high rating (4.5⭐)"
  }
}
```

### 3. Vendor Selection Algorithm
```javascript
// Vendor Selection Logic
function selectBestVendor(vendors, criteria = 'balanced') {
  const availableVendors = vendors.filter(v => v.is_available && v.stock_quantity > 0);
  
  switch(criteria) {
    case 'price_optimized':
      return availableVendors.sort((a, b) => a.price - b.price)[0];
    
    case 'delivery_optimized':
      return availableVendors.sort((a, b) => a.estimated_delivery_minutes - b.estimated_delivery_minutes)[0];
    
    case 'rating_optimized':
      return availableVendors.sort((a, b) => b.rating - a.rating)[0];
    
    case 'balanced':
    default:
      // Weighted scoring: 40% price, 30% delivery time, 30% rating
      return availableVendors.map(vendor => ({
        ...vendor,
        score: (
          (1 - (vendor.price / Math.max(...availableVendors.map(v => v.price)))) * 0.4 +
          (1 - (vendor.estimated_delivery_minutes / Math.max(...availableVendors.map(v => v.estimated_delivery_minutes)))) * 0.3 +
          (vendor.rating / 5) * 0.3
        )
      })).sort((a, b) => b.score - a.score)[0];
  }
}

// Result for bananas (balanced criteria):
// Local Fruits Store wins with score: 0.89
// (Better price + high rating compensates for slower delivery)
```

### 4. Add to Cart - Bananas
```json
// API Call: POST /api/cart/add
{
  "product_id": "banana-product-id",
  "vendor_id": "12345678-abcd-4671-95a5-e5e2dddfefe4",
  "quantity": 1,
  "zone_id": "0065483d-4249-4919-8122-4d051241ac2b"
}

// Response:
{
  "cart_item_id": "cart-item-1",
  "product_name": "Organic Bananas",
  "vendor_name": "Local Fruits Store",
  "quantity": 1,
  "unit_price": 55.00,
  "total_price": 55.00,
  "estimated_delivery": "35 minutes"
}
```

### 5. Add Second Product - Fresh Milk
```json
// API Call: GET /api/products/milk-product-id/vendors?zone_id=0065483d-4249-4919-8122-4d051241ac2b

// Response:
{
  "product_id": "milk-product-id",
  "product_name": "Fresh Farm Milk",
  "available_vendors": [
    {
      "vendor_id": "07892607-bfb3-4671-95a5-e5e2dddfefe3",
      "vendor_name": "Dayliz Fresh",
      "price": 25.00,
      "stock_quantity": 100,
      "rating": 4.2,
      "estimated_delivery_minutes": 25,
      "is_available": true
    }
  ],
  "recommended_vendor": {
    "vendor_id": "07892607-bfb3-4671-95a5-e5e2dddfefe3",
    "reason": "Only available vendor"
  }
}
```

### 6. Cart Summary (Mixed Vendor Order)
```json
// API Call: GET /api/cart

// Response:
{
  "cart_id": "user-cart-123",
  "total_items": 2,
  "vendors": [
    {
      "vendor_id": "12345678-abcd-4671-95a5-e5e2dddfefe4",
      "vendor_name": "Local Fruits Store",
      "items": [
        {
          "product_name": "Organic Bananas",
          "quantity": 1,
          "unit_price": 55.00,
          "total_price": 55.00
        }
      ],
      "subtotal": 55.00,
      "delivery_fee": 20.00,
      "vendor_total": 75.00,
      "estimated_delivery": "35 minutes"
    },
    {
      "vendor_id": "07892607-bfb3-4671-95a5-e5e2dddfefe3",
      "vendor_name": "Dayliz Fresh",
      "items": [
        {
          "product_name": "Fresh Farm Milk",
          "quantity": 1,
          "unit_price": 25.00,
          "total_price": 25.00
        }
      ],
      "subtotal": 25.00,
      "delivery_fee": 20.00,
      "vendor_total": 45.00,
      "estimated_delivery": "25 minutes"
    }
  ],
  "grand_total": 120.00,
  "total_delivery_fees": 40.00,
  "order_split_notice": "Your order will be delivered in 2 separate deliveries from different vendors"
}
```

### 7. Order Processing (Split Orders)
```json
// API Call: POST /api/orders/create

// Response:
{
  "main_order_id": "ORDER-123",
  "split_orders": [
    {
      "order_id": "ORDER-123-A",
      "vendor_id": "12345678-abcd-4671-95a5-e5e2dddfefe4",
      "vendor_name": "Local Fruits Store",
      "items": ["Organic Bananas x1"],
      "total": 75.00,
      "status": "confirmed",
      "estimated_delivery": "35 minutes"
    },
    {
      "order_id": "ORDER-123-B", 
      "vendor_id": "07892607-bfb3-4671-95a5-e5e2dddfefe3",
      "vendor_name": "Dayliz Fresh",
      "items": ["Fresh Farm Milk x1"],
      "total": 45.00,
      "status": "confirmed",
      "estimated_delivery": "25 minutes"
    }
  ],
  "payment_status": "completed",
  "total_paid": 120.00
}
```

### 8. Real-time Inventory Updates
```sql
-- After order confirmation, inventory is automatically updated:

-- Local Fruits Store - Bananas
UPDATE vendor_inventory 
SET stock_quantity = stock_quantity - 1, 
    updated_at = NOW() 
WHERE vendor_id = '12345678-abcd-4671-95a5-e5e2dddfefe4' 
  AND product_id = 'banana-product-id' 
  AND zone_id = '0065483d-4249-4919-8122-4d051241ac2b';
-- Result: Bananas stock: 30 → 29

-- Dayliz Fresh - Milk  
UPDATE vendor_inventory 
SET stock_quantity = stock_quantity - 1, 
    updated_at = NOW() 
WHERE vendor_id = '07892607-bfb3-4671-95a5-e5e2dddfefe3' 
  AND product_id = 'milk-product-id' 
  AND zone_id = '0065483d-4249-4919-8122-4d051241ac2b';
-- Result: Milk stock: 100 → 99
```

## Key Benefits Demonstrated

### 1. **Smart Vendor Selection**
- Price comparison across vendors
- Automatic best vendor recommendation
- User can still choose preferred vendor

### 2. **Mixed Vendor Orders**
- Seamless handling of products from different vendors
- Clear cost breakdown per vendor
- Transparent delivery expectations

### 3. **Real-time Inventory**
- Accurate stock levels per vendor per zone
- Automatic inventory updates after orders
- Prevents overselling

### 4. **Scalable Architecture**
- Easy to add more vendors
- Zone-based vendor management
- Performance optimized queries

This workflow shows how your multi-vendor system will work seamlessly, providing customers with the best options while maintaining operational efficiency!
