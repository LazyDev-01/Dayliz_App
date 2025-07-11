# Phase 2 Requirements & Planning Document
## DAYLIZ Q-COMMERCE: REGION → ZONE → AREA HIERARCHICAL MODEL

## 📋 INSTRUCTIONS FOR EDITING THIS FILE:
**Please edit this file to specify your exact requirements:**
- ✅ = Implement NOW (Phase 2 immediate)
- 🔄 = Implement but DISABLE (ready for future enabling)
- ⏳ = Implement LATER (Phase 3 or beyond)
- ❌ = Not needed/Skip

## 🏗️ BUSINESS MODEL OVERVIEW:

### **HIERARCHICAL STRUCTURE:**
```
🌍 REGION (City/Operational Cluster)
├── Example: Tura, Shillong, Guwahati
│
🏘️ ZONE (Delivery Units within Region)
├── Zone A (Tura) → Main Bazar, Hawakhana, Akhongre
├── Zone B (Tura) → Civil Hospital, Police Station area
│
📍 AREA (Precise Localities for Geofencing)
├── Main Bazar, Hawakhana, Akhongre, Civil Hospital
└── Used for: GPS mapping, pin-code validation, geofencing
```

### **VENDOR ASSIGNMENT MODEL:**
```
🏪 VENDOR SPECIALIZATION PER ZONE:
├── Option 1: Category-Specific Vendors
│   ├── Vendor A: Groceries & Staples
│   ├── Vendor B: Fresh Produce & Dairy
│   ├── Vendor C: Personal Care & Health
│   └── Vendor D: Snacks & Beverages
│
├── Option 2: Multi-Category Vendor
│   └── Single vendor handles ALL categories
│
└── Option 3: Hybrid + Fallback
    ├── Specialized vendors for main categories
    └── Dayliz Darkstore for special/backup products
```

### **CORE BUSINESS RULES:**
```
✅ No category overlap between vendors in same zone
✅ Each zone can have 1 or multiple vendors
✅ Master product list (global) + zone-specific pricing/stock
✅ User location → Area → Zone → Vendor routing
✅ 15-30 min delivery promise across all zones
✅ Uniform delivery fee: ₹25 (<₹200), ₹20 (<₹500), Free (>₹499)
```

---

## 🚀 PHASE 2 FEATURE PRIORITIES

### 1. 📍 REAL-TIME ORDER TRACKING
**Status:** [ ] ✅ NOW | [ ] 🔄 DISABLE | [ ] ⏳ LATER | [ ] ❌ SKIP

**Features to implement:**
- [✅] Order status updates (Placed → Preparing → Out for Delivery → Delivered)
- [⏳] Estimated delivery time calculation
- [⏳] Live agent location tracking on map
- [✅] Order timeline/progress bar in app
- [✅] Status change notifications

**Implementation Notes:**
```
Your specific requirements:
- Order status update refinement (Placed -> Picked up -> Out for Delivery -> Delivered)
- Status change notification (out for delivery and delivered)
```

### 2. 💳 ADVANCED PAYMENT INTEGRATION
**Status:** [ ] ✅ NOW | [ ] 🔄 DISABLE | [ ] ⏳ LATER | [ ] ❌ SKIP

**Payment Methods:**
- [🔄] UPI Integration (GPay, PhonePe, Paytm)
- [⏳] Credit/Debit Cards (Razorpay)
- [❌] Net Banking
- [🔄] Digital Wallets (Paytm, Amazon Pay)
- [🔄] Gift Cards/Store Credit
- [⏳] Split Payments
- [⏳] EMI Options
- [⏳] Saved Payment Methods

**Implementation Notes:**
```
Your specific requirements:
- The disabled marked items means it should be implement but keep it disabled.
- COD should be primary method and active.
- 
```

### 3. 📦 INVENTORY MANAGEMENT SYSTEM
**Status:** [ ] ✅ NOW | [ ] 🔄 DISABLE | [ ] ⏳ LATER | [ ] ❌ SKIP

**Stock Management Features:**
- [✅] Automatic stock deduction on order
- [🔄] Stock reservation during checkout
- [🔄] Low stock alerts to admin
- [🔄] Reorder level management
- [🔄] Expiry date tracking
- [🔄] Bulk stock updates
- [🔄] Stock reports and analytics

**Implementation Notes:**
```
Your specific requirements:
- Disabled should be kept ready and disabled for future
- Build the inventory system with flexibility keeping in mind vendors own the inventory and not dayliz as explained below.

Important note:
- Dayliz will not have any darkstore or own physical store for now. It's primary objective is to partner with local vendors in each and make use of their stores. But in future dayliz will have their own darkstore or inventory but for limited products(mostly for direct brand products or sponsors)

```

### 4. 🔔 CUSTOMER NOTIFICATIONS
**Status:** [ ] ✅ NOW | [ ] 🔄 DISABLE | [ ] ⏳ LATER | [ ] ❌ SKIP

**Notification Channels:**
- [✅] Push Notifications
- [⏳] SMS Alerts
- [🔄] Email Updates
- [⏳] WhatsApp Messages
- [✅] In-app Notifications

**Notification Types:**
- [🔄] Order confirmations
- [✅] Status updates
- [✅] Delivery notifications
- [🔄] Promotional offers
- [🔄] Reorder reminders
- [🔄] Stock availability alerts

**Implementation Notes:**
```
Your specific requirements:
- Disabled item should be ready but kept disabled.
- 
- 
```

### 5. 🎛️ ADMIN DASHBOARD FEATURES
**Status:** [ ] ✅ NOW | [ ] 🔄 DISABLE | [ ] ⏳ LATER | [ ] ❌ SKIP

**Dashboard Components:**
- [✅] Real-time metrics (orders, revenue, etc.)
- [✅] Order management interface
- [✅] Inventory control panel
- [✅] Customer management
- [✅] Agent/delivery management
- [✅] Analytics and reports
- [✅] Product catalog management
- [✅] Pricing and offers management

**Implementation Notes:**
```
Your specific requirements:
- Don't implement advanced features for now.
-
-
```

### 6. 🌍 HIERARCHICAL REGION-ZONE-AREA MANAGEMENT
**Status:** [ ] ✅ NOW | [ ] 🔄 DISABLE | [ ] ⏳ LATER | [ ] ❌ SKIP

**Region Management:**
- [✅] Region creation (City/Operational cluster level)
- [✅] Region-wise operational settings
- [✅] Multi-region analytics and reporting
- [⏳] Region expansion workflow - Automate later; start manual for first 3–4 regions

**Zone Management (Within Regions):**
- [✅] Zone creation and boundary definition
- [✅] Zone-to-area mapping
- [✅] Zone-specific vendor assignment
- [✅] Zone-wise delivery agent management
- [✅] Zone performance analytics

**Area Management (Geofencing):**
- [✅] Area creation with precise coordinates
- [✅] GPS-based area detection
- [✅] Pin-code to area mapping
- [✅] Geofencing polygon definition
- [✅] Area coverage validation

**Implementation Notes:**
```
Your specific requirements:
- Start with: Region (Tura) → Zone A → Areas (Main Bazar, Hawakhana, etc.)
- Build for: Multi-region scalability
- User flow: Location → Area → Zone → Vendor routing
- Geofencing-based precise area detection
```

### 7. 🏪 VENDOR-CATEGORY ASSIGNMENT SYSTEM
**Status:** [ ] ✅ NOW | [ ] 🔄 DISABLE | [ ] ⏳ LATER | [ ] ❌ SKIP

**Vendor Assignment Features:**
- [✅] Category-specific vendor assignment per zone - Core logic — each vendor gets specific categories within a zone
- [✅] Multi-category vendor support - Must support mega vendors who manage all categories
- [✅] Vendor conflict prevention (no category overlap) - Enforce unique (zone_id + category_id) per vendor
- [✅] Vendor capability management - Admin control to tag vendors by capability, trust score, etc.
- [⏳] Fallback vendor assignment (Dayliz Darkstore) - Plan for this soon, but okay to add in Phase 2

**Category Management:**
- [✅] Product category definition - 
- [✅] Category-vendor mapping per zone - Key part of zone_vendor_categories table
- [✅] Category-specific inventory tracking - Tied to vendor + zone combo
- [⏳] Category performance analytics

**Order Routing Logic:**
- [✅] Smart vendor selection based on category - Auto-detect which vendor is assigned for a category in that zone
- [⏳] Multi-vendor order splitting (if needed) - Keep single-vendor routing for now; add split orders later if needed
- [✅] Vendor availability checking - Pull from inventory status (is_available)
- [⏳] Fallback vendor routing - 	Plug in Dayliz darkstore when you expand hybrid model

**Vendor Dashboard (Category-Specific):**
- [✅] Category-specific inventory management - Vendor sees only the categories assigned to them
- [✅] Category-wise order management - Needed for their dispatch & packaging
- [⏳] Category performance metrics - Useful for quality control, but can come after launch
- [✅] Category-specific pricing controls - Vendor controls zone-based pricing via their dashboard

**Implementation Notes:**
```
Your specific requirements:
- No category overlap between vendors in same zone
- Support both specialized and multi-category vendors
- Smart order routing based on product categories
- Vendor conflict prevention system
```

### 8. 🌦️ WEATHER-ADAPTIVE DELIVERY SYSTEM
**Status:** [ ] ✅ NOW | [ ] 🔄 DISABLE | [ ] ⏳ LATER | [ ] ❌ SKIP

**Weather Detection Features:**
- [✅] Real-time weather API integration - Use OpenWeatherMap initially (free, easy)
- [✅] Weather condition classification (Normal/Bad/Extreme) - 	Basic tiering: Normal / Bad / Extreme
- [⏳] Automatic delivery fee adjustment - Start with manual toggle via admin panel
- [⏳] Dynamic delivery time estimation - 	Add logic based on conditions in Phase 2
- [✅] Weather-based service suspension - Manual override by admin — notify users via app

**Delivery Adjustments:**
- [✅] Normal weather: Standard fees and timing
- [✅] Bad weather: ₹30 flat fee + extended time (30-45 mins)
- [✅] Extreme weather: Service suspension with notifications
- [✅] Weather alerts to customers and delivery agents

**Weather Integration:**
- [✅] Weather API (OpenWeatherMap/AccuWeather) -Use OpenWeatherMap now, switch to premium later
- [✅] Real-time weather monitoring per zone - 	Track weather at the zone level, not just city
- [⏳] Automatic rule application - Phase 2: Full automation of pricing & suspension
- [✅] Weather-based notifications - Push alerts + app banners
- [⏳] Historical weather data for analytics - For analytics, refunds, performance tracking later

**Customer Communication:**
- [✅] Weather surcharge explanation - On checkout + help section
- [✅] Extended delivery time notifications - Popup or toast on checkout page
- [✅] Service suspension alerts - Push + App UI alert
- [✅] Weather-based delivery updates - “Due to rain, your order may be delayed…” etc.

**Implementation Notes:**
```
Your specific requirements:
- Bad weather: ₹30 flat delivery fee (overrides normal structure)
- Extended delivery time: 30-45 minutes during bad weather
- Automatic weather detection and rule application
- Clear customer communication about weather impacts
```


## 📋 BUSINESS RULES CONFIGURATION

### 🛒 ORDER RULES

**Minimum Order Values:**
```
Regular Delivery: ₹149 minimum
```

**Order Limits:**
```
COD Orders:
- New customers: ₹2000 max
- Regular customers: ₹5000 max
- Premium customers: ₹8000 max

Prepaid Orders:
- New customers: ₹40,000 max
- Regular customers: ₹100,000 max
```

**Your Custom Order Rules:**
```
- First time order must not exceed above 1500 for COD orders.
- 
- 
```

### 🚚 DELIVERY RULES (HIERARCHICAL MODEL)

**Business Model:** Region → Zone → Area hierarchical q-commerce with vendor specialization

**Uniform Delivery Promise (Across All Regions/Zones):**
```
⏱️ Delivery Time: 15-30 minutes
🚚 Delivery Method: Zone-specific vendor → Zone delivery agents
🚫 Cross-zone Delivery: Not available
📍 Coverage: Area-based geofencing
```

**Delivery Fee Structure (Weather-Adaptive):**
```
☀️ Normal Weather:
├── ₹25 for orders below ₹200
├── ₹20 for orders below ₹500
└── FREE for orders above ₹499

🌧️ Bad Weather (Rain/Storm):
├── ₹30 flat rate (regardless of order value)
├── Weather surcharge applied automatically
└── Extended delivery time: 30-45 minutes

❄️ Extreme Weather:
├── Service temporarily suspended
└── Customer notification sent
```

**Hierarchical Delivery Management:**
```
🌍 Region Level:
├── Regional delivery standards
├── Regional service hours
└── Regional delivery fee structure

🏘️ Zone Level:
├── Zone-specific vendor assignment
├── Zone delivery agent management
├── Zone-wise order routing
└── Zone performance tracking

📍 Area Level:
├── Precise geofencing boundaries
├── GPS-based area detection
├── Area-to-zone mapping
└── Delivery address validation
```

**Service Hours:** 8AM - 9PM (uniform across all regions/zones)

**Order Routing Flow:**
```
User Location → Area Detection → Zone Identification →
Category-based Vendor Selection → Delivery Agent Assignment
```

**Your Custom Delivery Rules:**
```
```

### 💳 PAYMENT RULES

**Payment Method Preferences:**
- [✅] COD Priority (encourage cash payments)
- [⏳] Digital Priority (encourage online payments) - Make it feature ready.
- [✅] Balanced approach

**COD Restrictions:**
- [✅] Enable for all orders
- [✅] Restrict above ₹2000 amount
- [ ] Restrict for certain categories
- [ ] Require verification for new customers

**Your Custom Payment Rules:**
```
- 
- 
- 
```

### 📦 PRODUCT & ZONE RULES

**Multi-Zone Product Strategy:**
- [ ] Global Products (same across all zones)
- [ ] Zone-Specific Products (local specialties)
- [ ] Hybrid Approach (recommended)

**Zone Management:**
```
Zone Onboarding Process:
- [ ] Geofence boundary definition
- [ ] Vendor assignment
- [ ] Product catalog setup (global + local)
- [ ] Delivery agent assignment
- [ ] Zone-specific pricing (if needed)
```

**Product Categories:**
```
Perishables (Milk, Vegetables):
- [ ] Same-day delivery only
- [ ] No returns after delivery
- [ ] Zone-specific sourcing

Age-restricted Items:
- [ ] ID verification required
- [ ] Age verification (18+)
- [ ] Zone-specific compliance

Local Specialties:
- [ ] Zone-specific products
- [ ] Local vendor sourcing
- [ ] Cultural preferences
```

**Your Custom Product/Zone Rules:**
```
-
-
-
```

### 👥 CUSTOMER RULES

**Loyalty Program:** [ ] Enable | [ ] Disable

**Customer Tiers:**
```
Bronze (0-___ orders): ___% benefits
Silver (___-___ orders): ___% benefits  
Gold (___-___ orders): ___% benefits
Platinum (___+ orders): ___% benefits
```

**Account Security:**
- [ ] OTP for orders above ₹___
- [ ] Address verification for new locations
- [ ] Payment method verification
- [ ] Suspicious activity monitoring

**Your Custom Customer Rules:**
```
- 
- 
- 
```

---

## 🎯 IMPLEMENTATION TIMELINE

### Phase 2A (Immediate - Week 1-2):
```
Priority 1: 
Priority 2: 
Priority 3: 
```

### Phase 2B (Short-term - Week 3-4):
```
Priority 1: 
Priority 2: 
Priority 3: 
```

### Phase 2C (Medium-term - Month 2):
```
Priority 1: 
Priority 2: 
Priority 3: 
```

---

## 💡 SPECIAL REQUIREMENTS

### Technical Preferences:
```
- Database: Continue with Supabase | Switch to ___
- Notifications: Firebase | Third-party service ___
- Payments: Razorpay | Other ___
- Maps: Google Maps | Other ___
```

### Business Priorities:
```
Most Important: 
Second Priority: 
Third Priority: 
```

### Budget Considerations:
```
High Priority (invest now): 
Medium Priority (if budget allows): 
Low Priority (future consideration): 
```

---

## 📝 NOTES & CUSTOM REQUIREMENTS

### Your Specific Needs:
```
1. 
2. 
3. 
4. 
5. 
```

### Questions/Clarifications Needed:
```

1. How and where will the order timeline/progress bar in app be implemented?
2. 
3. 
```

### Future Considerations:
```
1. 
2. 
3. 
```

---

## 🔧 TECHNICAL IMPLEMENTATION DETAILS

### Current System Status:
```
✅ Order Creation: Fully functional
✅ Database Schema: Optimized (needs hierarchical extension)
✅ Error Handling: Comprehensive
✅ Audit Logging: Enabled
🔄 Stock Validation: Available but disabled
🔄 Stock Deduction: Available but disabled
🔄 Payment Validation: Basic validation enabled
❌ Hierarchical Structure: Not implemented (Phase 2 priority)
❌ Vendor-Category System: Not implemented (Phase 2 priority)
❌ Geofencing: Not implemented (Phase 2 priority)
```

### Required Database Schema (Hierarchical Model):
```sql
-- HIERARCHICAL STRUCTURE
regions (
  id, name, display_name, status,
  operational_settings, created_at
)

zones (
  id, region_id, name, display_name,
  geofence_coordinates, status,
  delivery_settings, service_hours,
  weather_delivery_rules, created_at
)

areas (
  id, zone_id, name, display_name,
  geofence_polygon, pin_codes,
  gps_coordinates, status, created_at
)

-- VENDOR-CATEGORY SYSTEM
vendors (
  id, name, contact_info, status,
  vendor_type, created_at
)

categories (
  id, name, display_name, description,
  parent_category_id, status, created_at
)

zone_vendor_categories (
  zone_id, vendor_id, category_id,
  is_primary, status, assigned_at
)

-- INVENTORY MANAGEMENT
zone_vendor_inventory (
  zone_id, vendor_id, product_id,
  stock_quantity, zone_price,
  is_available, last_updated
)

-- ORDER ROUTING
orders (
  id, user_id, region_id, zone_id, area_id,
  assigned_vendor_id, delivery_agent_id,
  order_data, status, created_at
)
```

### Available Functions (Ready to Enable):
```
✅ create_order_with_items() - Current function
🔄 create_order_with_items_enhanced() - With stock management
🔄 validate_order_stock() - Stock checking
🔄 deduct_order_stock() - Inventory deduction
🔄 validate_order_payment() - Payment validation
🔄 get_order_audit_trail() - Detailed logging
```

### Integration Points:
```
Mobile App: Flutter (current)
Database: Supabase (current)
Payments: Ready for Razorpay integration
Notifications: Ready for Firebase integration
Maps: Ready for Google Maps integration
```

### Performance Optimizations:
```
✅ Database indexes created
✅ Query optimization done
✅ Error handling optimized
✅ Security measures implemented
```

---

## 📊 CURRENT METRICS (For Reference):
```
Total Orders: 23
Total Products: 2,500
Total Users: 18
System Uptime: 100%
Order Success Rate: 100%
Average Order Value: ₹500-800
```

---

**📌 INSTRUCTIONS:**
1. Fill out this document with your preferences
2. Mark priorities clearly (✅ 🔄 ⏳ ❌)
3. Add your custom requirements in the notes sections
4. Specify timeline preferences
5. Add budget considerations
6. Save and share back for implementation planning

**Once you complete this, I'll have a perfect roadmap to implement exactly what you need, when you need it, and how you want it!**

**This document will be our single source of truth for Phase 2 development.** 🎯
