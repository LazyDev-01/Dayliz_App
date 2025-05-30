# Route Cleanup Plan

## 🚨 **CURRENT PROBLEM**

The app has **54 routes** with many duplicates and legacy routes that are causing confusion and potential navigation issues.

## 📋 **ROUTES TO KEEP (Clean Architecture Only)**

### **Core App Routes (12 routes)**
```
✅ /                          - Root/Splash
✅ /home                       - Main screen
✅ /login                      - Login screen
✅ /signup                     - Registration screen
✅ /verify-email               - Email verification
✅ /auth/verify                - Auth verification handler
✅ /reset-password             - Password reset screen
✅ /update-password            - Update password screen
✅ /profile                    - User profile
✅ /addresses                  - Address management
✅ /address/add                - Add new address
✅ /address/edit/:id           - Edit address
```

### **Shopping Routes (8 routes)**
```
✅ /categories                 - Categories screen
✅ /category/:id               - Category products
✅ /product/:id                - Product details
✅ /cart                       - Shopping cart
✅ /checkout                   - Checkout process
✅ /order-confirmation/:orderId - Order confirmation
✅ /orders                     - Order history
✅ /payment-methods            - Payment methods
```

### **Utility Routes (4 routes)**
```
✅ /search                     - Search screen
✅ /wishlist                   - Wishlist screen
✅ /preferences                - User preferences
✅ /address-form               - Address form (legacy support)
```

### **Development Routes (4 routes - Remove in Production)**
```
🔧 /debug/google-sign-in       - Google Sign-In debug
🔧 /debug/cart-dependencies    - Cart debug
🔧 /test/product-feature       - Product testing
🔧 /dev/database-seeder        - Database seeder
```

## ❌ **ROUTES TO REMOVE (30+ routes)**

### **Legacy Routes**
```
❌ /home-legacy
❌ /search-legacy
❌ /search-screen
❌ /wishlist-legacy
❌ /auth/verify-legacy
❌ /search-test
```

### **Duplicate Clean Routes**
```
❌ /clean/category/:id         - Duplicate of /category/:id
❌ /clean/product/:id          - Duplicate of /product/:id
❌ /clean-demo
❌ /clean-home                 - Redirect to /home
❌ /clean/:path                - Generic clean handler
❌ /clean/login                - Redirect to /login
❌ /clean/register             - Redirect to /signup
❌ /clean/forgot-password      - Redirect to /reset-password
❌ /clean/profile              - Redirect to /profile
❌ /clean/preferences          - Redirect to /preferences
❌ /clean/addresses            - Redirect to /addresses
❌ /clean/cart                 - Duplicate of /cart
❌ /clean/orders               - Duplicate of /orders
❌ /clean/checkout             - Duplicate of /checkout
❌ /clean-wishlist             - Duplicate of /wishlist
❌ /clean/categories           - Duplicate of /categories
❌ /clean/payment-methods      - Duplicate of /payment-methods
❌ /clean/order-confirmation/:orderId - Duplicate
```

### **Debug/Development Duplicates**
```
❌ /clean/debug/supabase-test
❌ /clean/debug/menu
❌ /clean/debug/google-sign-in
❌ /clean/test/product-card
❌ /dev/settings
```

## 🎯 **FINAL CLEAN ROUTE COUNT: 28 routes**

- **Core App**: 12 routes
- **Shopping**: 8 routes  
- **Utility**: 4 routes
- **Development**: 4 routes (remove in production)

## 🔧 **IMPLEMENTATION PLAN**

### **Phase 1: Remove Legacy Routes**
1. Remove all `/clean/*` routes that duplicate main routes
2. Remove all `*-legacy` routes
3. Remove test and duplicate routes

### **Phase 2: Consolidate Main Routes**
1. Ensure all main routes use clean architecture screens
2. Remove redirect routes (make direct routes)
3. Update navigation references

### **Phase 3: Update Navigation**
1. Update bottom navigation index observer
2. Update deep link handling
3. Test all navigation flows

### **Phase 4: Production Cleanup**
1. Remove all debug routes in production builds
2. Add route guards for development routes
3. Final testing

## 🚀 **BENEFITS**

- **Faster Navigation**: Fewer routes to process
- **Cleaner Code**: No duplicate route definitions
- **Better Debugging**: Clear route structure
- **Easier Maintenance**: Single source of truth for each screen
- **Improved Performance**: Reduced router complexity

## ⚠️ **RISKS & MITIGATION**

### **Risk**: Breaking existing deep links
**Mitigation**: Keep redirect routes temporarily, then remove after testing

### **Risk**: Navigation issues
**Mitigation**: Test all navigation flows after cleanup

### **Risk**: Development workflow disruption  
**Mitigation**: Keep essential debug routes, remove only duplicates

## 📝 **NEXT STEPS**

1. **Backup current routing** (already in git)
2. **Implement cleanup** in phases
3. **Test thoroughly** after each phase
4. **Update documentation** with final route structure
5. **Remove development routes** before production deployment
