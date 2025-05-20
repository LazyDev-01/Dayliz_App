# Clean Architecture Database Migration Plan

This document outlines the plan for migrating the database schema to align with the clean architecture implementation.

## Migration Progress

| Version | Description | Status | Date |
|---------|-------------|--------|------|
| 1.1.0 | Schema alignment for clean architecture entities - Part 1 | ✅ Completed | 2023-07-10 |
| 1.2.0 | Schema alignment for clean architecture entities - Part 2 | ✅ Completed | 2023-07-10 |
| 1.3.0 | Schema alignment for clean architecture entities - Part 3 | ✅ Completed | 2023-07-10 |
| 1.4.0 | Schema alignment for clean architecture entities - Part 4 | ✅ Completed | 2023-07-10 |
| 1.5.1 | Schema alignment for payment_methods table | ✅ Completed | 2023-07-10 |
| 1.5.2 | Schema alignment for orders table | ✅ Completed | 2023-07-10 |
| 1.6.0 | Enable RLS on all tables | ✅ Completed | 2023-07-10 |
| 2.0.1 | Add name column to payment_methods table | ✅ Completed | 2023-07-11 |
| 2.0.2 | Add details column to payment_methods table | ✅ Completed | 2023-07-11 |
| 2.1.0 | Data migration for payment methods | ✅ Completed | 2023-07-11 |
| 2.2.0 | Data migration for addresses | ✅ Completed | 2023-07-11 |
| 2.3.0 | Data migration for cart items | ✅ Completed | 2023-07-11 |
| 2.4.0 | Data migration for orders and order items | ✅ Completed | 2023-07-11 |
| 2.5.1 | Add last_updated column to user_profiles table | ✅ Completed | 2023-07-11 |
| 2.5.2 | Data migration for user profiles | ✅ Completed | 2023-07-11 |
| 2.5.3 | Add profile_image_url column to user_profiles table | ✅ Completed | 2023-07-11 |
| 2.6.0 | Data migration finalization | ✅ Completed | 2023-07-11 |

## Migration Details

### 1.1.0 - Schema Alignment for Clean Architecture Entities - Part 1

- Updated `user_profiles` table to align with UserProfile entity
- Updated `addresses` table to align with Address entity
- Updated `products` table to align with Product entity
- Updated `categories` table to align with Category entity
- Updated `subcategories` table to align with SubCategory entity
- Created `payment_methods` table to align with PaymentMethod entity
- Created indexes for performance
- Created RLS policies for payment_methods

### 1.2.0 - Schema Alignment for Clean Architecture Entities - Part 2

- Updated `cart_items` table to align with CartItem entity
- Created `wishlist_items` table to align with WishlistItem entity
- Updated `orders` table to align with Order entity
- Updated `order_items` table to align with OrderItem entity
- Created indexes for performance

### 1.3.0 - Schema Alignment for Clean Architecture Entities - Part 3

- Updated data types and constraints for addresses table
- Created indexes for addresses table
- Added foreign key constraints for zone_id

### 1.4.0 - Schema Alignment for Clean Architecture Entities - Part 4

- Updated data types and constraints for products table
- Created indexes for products table
- Added default values for in_stock field

### 1.5.1 - Schema Alignment for Payment Methods Table

- Updated data types and constraints for payment_methods table
- Created unique constraint for default payment methods per user

### 1.5.2 - Schema Alignment for Orders Table

- Created trigger function for updating updated_at timestamp
- Added check constraint for valid order status values
- Created trigger for automatically updating updated_at timestamp

### 1.6.0 - Enable RLS on All Tables

- Enabled Row Level Security (RLS) on all tables
- Created RLS policies for addresses table
- Created RLS policies for cart_items table
- Created RLS policies for orders table

### 2.0.1 - Add name column to payment_methods table

- Added name column to payment_methods table to align with PaymentMethod entity

### 2.0.2 - Add details column to payment_methods table

- Added details column to payment_methods table to store payment method details in JSONB format

### 2.1.0 - Data migration for payment methods

- Created a function to convert legacy payment method data to the new format
- Generated names for payment methods based on their type and details
- Converted payment method details to JSONB format

### 2.2.0 - Data migration for addresses

- Created coordinates JSON from latitude and longitude
- Migrated label to address_type where needed
- Set default address_type for addresses without one
- Ensured all addresses have a recipient_name

### 2.3.0 - Data migration for cart items

- Set added_at to created_at if it's null
- Set default values for selected and saved_for_later

### 2.4.0 - Data migration for orders and order items

- Calculated subtotal, tax, and shipping for orders
- Updated order_items with product_name and image_url
- Set options to empty JSON if it's null

### 2.5.1 - Add last_updated column to user_profiles table

- Added last_updated column to user_profiles table to align with UserProfile entity

### 2.5.2 - Data migration for user profiles

- Set preferences to empty JSON if it's null
- Set last_updated to updated_at if it exists
- Set is_public to true if it's null

### 2.5.3 - Add profile_image_url column to user_profiles table

- Added profile_image_url column to user_profiles table
- Migrated data from avatar_url to profile_image_url

### 2.6.0 - Data migration finalization

- Created a function to validate the data migration
- Checked that all required fields have been migrated
- Verified data integrity across all tables

## Migration Progress (continued)

| Version | Description | Status | Date |
|---------|-------------|--------|------|
| 3.1.0 | Performance optimization: Indexes for common queries | ✅ Completed | 2023-07-12 |
| 3.1.1 | Create trigram extension for text search | ✅ Completed | 2023-07-12 |
| 3.1.2 | Performance optimization: Indexes for common queries (fixed) | ✅ Completed | 2023-07-12 |
| 3.2.0 | Performance optimization: Materialized views for common reports | ✅ Completed | 2023-07-12 |
| 3.3.0 | Performance optimization: Database functions for complex operations | ✅ Completed | 2023-07-12 |
| 3.4.0 | Performance optimization: Triggers for automatic updates | ✅ Completed | 2023-07-12 |
| 3.4.1 | Performance optimization: Materialized view refresh triggers | ✅ Completed | 2023-07-12 |
| 3.5.0 | Performance optimization: Full-text search for products | ✅ Completed | 2023-07-12 |
| 3.6.0 | Performance optimization: Geospatial queries for addresses | ✅ Completed | 2023-07-12 |
| 3.7.0 | Performance optimization: Real-time notifications | ✅ Completed | 2023-07-12 |
| 3.8.0 | Performance optimization: Database maintenance functions | ✅ Completed | 2023-07-12 |

## Performance Optimization Details

### 3.1.0 - Performance Optimization: Indexes for Common Queries

- Created indexes for product search by name
- Created indexes for filtering products by category and subcategory
- Created indexes for filtering products by price range
- Created indexes for filtering products by discount
- Created indexes for filtering orders by status and user
- Created indexes for filtering orders by date range
- Created indexes for filtering addresses by user and default status
- Created indexes for filtering addresses by zone
- Created indexes for filtering cart items by user and saved status
- Created indexes for filtering cart items by product
- Created indexes for filtering wishlist items by user
- Created indexes for filtering wishlist items by added date
- Created indexes for searching user profiles by name
- Created indexes for filtering payment methods by type

### 3.1.1 - Create Trigram Extension for Text Search

- Created the pg_trgm extension for text search

### 3.2.0 - Performance Optimization: Materialized Views for Common Reports

- Created a materialized view for product statistics
- Created a materialized view for category statistics
- Created a materialized view for user order statistics
- Created a function to refresh all materialized views

### 3.3.0 - Performance Optimization: Database Functions for Complex Operations

- Created a function to get a user's cart with product details
- Created a function to get a user's wishlist with product details
- Created a function to get a user's orders with details
- Created a function to get order details
- Created a function to search products

### 3.4.0 - Performance Optimization: Triggers for Automatic Updates

- Created a trigger to update updated_at timestamp
- Created a trigger to update product counts in subcategories

### 3.4.1 - Performance Optimization: Materialized View Refresh Triggers

- Created a trigger to refresh materialized views when data changes
- Created triggers for products, orders, and order_items tables

### 3.5.0 - Performance Optimization: Full-Text Search for Products

- Added a tsvector column to the products table
- Created a function to update the search vector
- Created a trigger to update the search vector
- Created a GIN index on the search vector
- Created a function to search products using full-text search

### 3.6.0 - Performance Optimization: Geospatial Queries for Addresses

- Created the PostGIS extension
- Added a geometry column to the addresses table
- Created a function to update the geometry column
- Created a trigger to update the geometry column
- Created a spatial index on the geometry column
- Created a function to find addresses within a radius
- Created a function to find the nearest zone for an address

### 3.7.0 - Performance Optimization: Real-Time Notifications

- Created a notifications table
- Created indexes for the notifications table
- Created a function to create a notification
- Created a function to mark a notification as read
- Created a function to mark all notifications as read for a user
- Created a function to create an order status notification
- Created a trigger to create an order status notification

### 3.8.0 - Performance Optimization: Database Maintenance Functions

- Created a function to vacuum the database
- Created a function to analyze the database
- Created a function to get database statistics
- Created a function to get index statistics

## Pending Migrations

### 4.0.0 - Advanced Features

- Implement advanced analytics and reporting
- Add machine learning-based product recommendations
- Implement A/B testing framework

## Entity-Database Mapping

For detailed mapping between domain entities and database tables, see [Entity Database Mapping](entity_database_mapping.md).

## Testing Plan

1. **Unit Tests**: Create unit tests for each repository implementation to ensure they correctly map between domain entities and database models.

2. **Integration Tests**: Create integration tests to verify the repositories can correctly perform CRUD operations against the Supabase database.

3. **End-to-End Tests**: Create end-to-end tests to verify the entire application works correctly with the updated database schema.

## Rollback Plan

In case of issues with the migrations, the following rollback plan will be implemented:

1. Restore from the latest backup before the migrations
2. Apply only the migrations that were verified to work correctly
3. Fix issues with the problematic migrations
4. Re-apply the fixed migrations

## Conclusion

This migration plan ensures a smooth transition from the legacy database schema to a schema that aligns with the clean architecture implementation. By following this plan, we can ensure that the database schema supports the domain entities and use cases defined in the clean architecture implementation.
