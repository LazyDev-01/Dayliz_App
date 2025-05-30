# Database Schema Alignment for Clean Architecture

This document outlines the alignment between the clean architecture domain entities and the Supabase database schema. The goal is to ensure that database tables properly map to domain entities while maintaining backward compatibility with existing code.

## Entity-Table Mapping

| Domain Entity | Database Table | Notes |
|---------------|----------------|-------|
| `User` | `public.users` and `auth.users` | Auth information in `auth.users`, profile in `public.users` |
| `UserProfile` | `public.user_profiles` | Extended user information |
| `Address` | `public.addresses` | User addresses |
| `Product` | `public.products` | Product information |
| `Category` | `public.categories` | Product categories |
| `SubCategory` | `public.subcategories` | Product subcategories (consider hierarchical categories) |
| `Order` | `public.orders` | Order information |
| `OrderItem` | `public.order_items` | Order line items |
| `CartItem` | `public.cart_items` | Shopping cart items |
| `WishlistItem` | `public.wishlists` | User wishlist items |
| `PaymentMethod` | `public.payment_methods` | User payment methods |

## Schema Alignment Changes

The following changes were made to align the database schema with the domain entities:

### User & UserProfile
- Added `bio` and `is_public` fields to `user_profiles`
- Ensured `preferences` is available as `jsonb` type

### Address
- Added `label`, `additional_info`, and `coordinates` fields
- Renamed `recipient_phone` to `phone_number` for consistency

### Product
- Added `main_image_url` field to directly store primary image URL
- Added `additional_images` array to store secondary image URLs
- Modified `discount_percentage` to use correct data type

### Order
- Added `billing_address_id` to support separate billing address
- Added `tracking_number` for order tracking
- Added `coupon_code` to complement `coupon_id` reference

### Payment Method
- Created new `payment_methods` table to store payment information
- Added appropriate security policies

### Wishlist & Cart Items
- Added `added_at` timestamp to track when items were added
- For cart items, added `selected` and `saved_for_later` flags

### Categories
- Added `slug` field for SEO-friendly URLs
- Added `parent_id` for hierarchical category structure

## Version Tracking

A new table `clean_architecture_versions` tracks schema changes related to clean architecture. Current version is 1.0.0.

## Database Views

Consider creating the following views to facilitate easier data access:

1. `product_details_view` - Complete product information with categories and images
2. `user_profile_view` - Combined user and profile information
3. `order_details_view` - Complete order information with items and addresses

## Next Steps

1. Create database triggers to maintain consistency between related tables
2. Consider optimizing indexes for common query patterns
3. Implement data validation at the database level where appropriate
4. Review and update RLS policies to ensure proper data security

## Migration Strategy

When making changes to the schema:

1. Always use migrations to track changes
2. Update the `clean_architecture_versions` table
3. Document changes in this file
4. Test with both legacy and clean architecture code paths

---

**Note**: This alignment is part of the Phase 9 (Backend Integration and Live Data) of the clean architecture migration plan. Future updates may introduce further refinements as more features are migrated to the clean architecture pattern.

## Implementing Supabase Data Sources

To interact with the aligned schema, we've implemented clean architecture data sources that use Supabase. Here's an example for the CartItem entity:

```dart
/// Implementation of [CartRemoteDataSource] for Supabase backend
class CartSupabaseDataSource implements CartRemoteDataSource {
  final SupabaseClient _supabaseClient;

  CartSupabaseDataSource({required SupabaseClient supabaseClient})
      : _supabaseClient = supabaseClient;

  @override
  Future<List<CartItemModel>> getCartItems() async {
    try {
      final user = _supabaseClient.auth.currentUser;
      if (user == null) {
        throw ServerException(message: 'User is not authenticated');
      }

      // Using the fields aligned in the database schema
      final response = await _supabaseClient
          .from('cart_items')
          .select('''
            id,
            product_id,
            quantity,
            added_at,  // New field from schema alignment
            selected,  // New field from schema alignment
            saved_for_later,  // New field from schema alignment
            products (*)
          ''')
          .eq('user_id', user.id)
          .order('added_at', ascending: false);

      return (response as List<dynamic>).map((item) {
        final product = ProductModel.fromJson(item['products']);
        
        return CartItemModel(
          id: item['id'],
          product: product,
          quantity: item['quantity'],
          addedAt: DateTime.parse(item['added_at']),  // Using the new field
        );
      }).toList();
    } catch (e) {
      throw ServerException(message: 'Failed to get cart items: ${e.toString()}');
    }
  }

  // Additional methods for managing cart items...
}
```
