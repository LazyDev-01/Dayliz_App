# Order Management Configuration

## Overview
The order management system has been optimized and cleaned up for production use. This document outlines the configuration options and features available.

## Core Functions

### 1. Basic Order Creation
```sql
-- Simple order creation without stock validation
SELECT create_order_with_items(order_data, order_items);
```

### 2. Enhanced Order Creation with Stock Management
```sql
-- Order creation with stock validation and deduction
SELECT create_order_with_items_enhanced(
  order_data, 
  order_items, 
  validate_stock := true,  -- Enable stock validation
  deduct_stock := true     -- Enable automatic stock deduction
);
```

## Configuration Options

### Stock Management
- **validate_stock**: Check product availability before creating order
- **deduct_stock**: Automatically reduce inventory when order is created

### Current Settings
- **Stock Validation**: Disabled (for faster order processing)
- **Stock Deduction**: Disabled (manual inventory management)
- **Payment Validation**: Enabled (basic validation)
- **Audit Logging**: Enabled (for compliance)

## Performance Optimizations

### Database Indexes
- `idx_orders_user_id_created_at`: Fast user order history
- `idx_orders_order_number`: Quick order lookup
- `idx_orders_status_created_at`: Order status filtering
- `idx_order_items_order_id`: Order items retrieval
- `idx_order_items_product_id`: Product order history
- `idx_products_stock_quantity`: Stock availability queries

### Function Optimizations
- **SECURITY DEFINER**: Bypasses RLS for better performance
- **Input validation**: Early validation to prevent unnecessary processing
- **Unique order numbers**: Timestamp-based with conflict resolution
- **Transaction safety**: Atomic operations with proper rollback

## Error Handling

### Client-Side Error Messages
- Product availability issues
- Payment method validation
- Address validation
- Authentication errors
- Network connectivity issues

### Server-Side Error Codes
- `INVALID_INPUT`: Missing or malformed data
- `INVALID_USER_ID`: User ID format issues
- `USER_NOT_FOUND`: User doesn't exist
- `INVALID_ADDRESS`: Address validation failed
- `INSUFFICIENT_STOCK`: Product availability issues
- `ORDER_CREATION_FAILED`: General creation failure

## Monitoring and Logging

### Audit Trail
All order operations are logged in `order_audit_log` table with:
- Operation type and status
- User ID and order ID
- Detailed operation data
- Error messages
- Timestamps

### Debug Logging
Debug information is logged in `order_debug_log` table for troubleshooting.

## Security Features

### Input Validation
- UUID format validation
- Required field validation
- Data type validation
- Range validation for amounts

### Access Control
- User ownership validation for addresses
- Product existence validation
- Transaction isolation

### Error Handling
- Sanitized error messages
- No sensitive data exposure
- Proper exception handling

## Future Enhancements

### Planned Features
1. **Real-time stock validation** with Redis cache
2. **Payment gateway integration** with Razorpay
3. **Order status webhooks** for real-time updates
4. **Inventory reservation** system
5. **Fraud detection** algorithms

### Configuration Migration
To enable stock management in the future:

```dart
// In OrderService, change the RPC call to:
final response = await _supabase.rpc('create_order_with_items_enhanced', params: {
  'order_data': orderData,
  'order_items': items,
  'validate_stock': true,
  'deduct_stock': true,
});
```

## Maintenance

### Regular Tasks
- Clean up old debug logs (automated)
- Monitor order creation performance
- Review error patterns in audit logs
- Update indexes based on query patterns

### Health Checks
- Order creation success rate
- Average order processing time
- Error rate monitoring
- Database performance metrics
