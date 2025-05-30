# Dayliz App Database Documentation

This directory contains documentation related to the Dayliz App database schema and migrations.

## Overview

The Dayliz App uses Supabase as its primary database, which is built on PostgreSQL. The database schema is designed to support the clean architecture implementation of the app, with tables that map directly to domain entities.

## Directory Structure

- `README.md` - This file
- `entity_database_mapping.md` - Mapping between domain entities and database tables
- `migration_plan.md` - Plan for migrating the database schema to align with clean architecture
- `updated_schema.sql` - SQL script for creating the updated database schema

## Database Schema

The database schema consists of the following main tables:

- `users` - User accounts (managed by Supabase Auth)
- `user_profiles` - User profile information
- `addresses` - User addresses for shipping and billing
- `products` - Product catalog
- `categories` - Product categories
- `subcategories` - Product subcategories
- `cart_items` - Items in user shopping carts
- `wishlist_items` - Items in user wishlists
- `orders` - User orders
- `order_items` - Items in user orders
- `payment_methods` - User payment methods
- `zones` - Delivery zones for the zone-based delivery system

## Entity-Database Mapping

The domain entities in the clean architecture implementation map directly to database tables. For detailed mapping information, see [Entity Database Mapping](entity_database_mapping.md).

## Migration Plan

The migration plan outlines the steps for migrating the database schema to align with the clean architecture implementation. For detailed information, see [Migration Plan](migration_plan.md).

## Row Level Security (RLS)

Supabase uses PostgreSQL's Row Level Security (RLS) feature to control access to data. RLS policies are defined for each table to ensure that users can only access their own data.

### Common RLS Policies

Most tables have the following RLS policies:

- `Users can view their own data` - Users can only view their own data
- `Users can insert their own data` - Users can only insert data that belongs to them
- `Users can update their own data` - Users can only update their own data
- `Users can delete their own data` - Users can only delete their own data

## Database Migrations

Database migrations are managed through Supabase's Migration Control Panel (MCP). Migrations are applied in order, with each migration building on the previous one.

### Migration Naming Convention

Migrations follow the naming convention:

```
clean_architecture_schema_alignment_part{n}
```

Where `{n}` is the part number of the migration.

## Best Practices

When working with the database, follow these best practices:

1. **Use Repositories**: Always access the database through repository implementations, not directly.

2. **Map to Domain Entities**: Always map database results to domain entities before returning them from repositories.

3. **Use Transactions**: Use transactions for operations that modify multiple tables to ensure data consistency.

4. **Validate Input**: Always validate input before inserting or updating data in the database.

5. **Handle Errors**: Always handle database errors gracefully and provide meaningful error messages.

6. **Test Thoroughly**: Always test database operations thoroughly, including edge cases and error conditions.

## Troubleshooting

If you encounter issues with the database, check the following:

1. **Connection Issues**: Ensure that the Supabase URL and API key are correct.

2. **Permission Issues**: Ensure that the appropriate RLS policies are in place for the tables you're accessing.

3. **Schema Issues**: Ensure that the database schema matches the expected schema for the clean architecture implementation.

4. **Migration Issues**: Ensure that all migrations have been applied successfully.

## Further Reading

- [Supabase Documentation](https://supabase.io/docs)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
