# Database Schema Alignment for Clean Architecture

## Overview

This document tracks the progress of aligning the Supabase database schema with the clean architecture entity models in the Dayliz App. The goal is to ensure that the database structure properly supports the domain entities while maintaining data integrity and performance.

## Current Status

| Entity | Database Table | Alignment Status | Notes |
|--------|---------------|-----------------|-------|
| User | `public.users` | 🔄 In Progress | Missing some fields from UserProfile entity |
| UserProfile | `public.user_profiles` | 🔄 In Progress | Needs to be created or extended |
| Product | `public.products` | 🔄 In Progress | Missing some fields, needs normalization |
| Category | `public.categories` | 🔄 In Progress | Structure mostly aligned, needs subcategories relation |
| SubCategory | `public.subcategories` | 🔄 In Progress | Needs to be created or aligned |
| Cart | `public.cart_items` | 🔄 In Progress | Needs user relation and product relation |
| Order | `public.orders` | 🔄 In Progress | Missing some fields from Order entity |
| OrderItem | `public.order_items` | 🔄 In Progress | Needs proper relations to orders and products |
| Address | `public.addresses` | 🔄 In Progress | Missing some fields from Address entity |
| Wishlist | `public.wishlist_items` | 🔄 In Progress | Needs user relation and product relation |
| PaymentMethod | `public.payment_methods` | 🔄 In Progress | Needs to be created or aligned |

## Required Schema Changes

### User & UserProfile

```sql
-- Extend users table with additional fields
ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS is_email_verified BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS metadata JSONB;

-- Create user_profiles table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID PRIMARY KEY REFERENCES public.users(id),
    name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    phone TEXT,
    profile_image_url TEXT,
    preferences JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Product

```sql
-- Extend products table with additional fields
ALTER TABLE public.products
ADD COLUMN IF NOT EXISTS main_image_url TEXT,
ADD COLUMN IF NOT EXISTS additional_images TEXT[],
ADD COLUMN IF NOT EXISTS is_featured BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS is_new_arrival BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS is_on_sale BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS discount_percentage DECIMAL(5,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS average_rating DECIMAL(3,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS review_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}'::jsonb;
```

### Category & SubCategory

```sql
-- Ensure categories table has required fields
ALTER TABLE public.categories
ADD COLUMN IF NOT EXISTS name TEXT NOT NULL,
ADD COLUMN IF NOT EXISTS image_url TEXT,
ADD COLUMN IF NOT EXISTS icon TEXT,
ADD COLUMN IF NOT EXISTS theme_color TEXT,
ADD COLUMN IF NOT EXISTS display_order INTEGER DEFAULT 0;

-- Create subcategories table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.subcategories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category_id UUID REFERENCES public.categories(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    image_url TEXT,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Address

```sql
-- Extend addresses table with additional fields
ALTER TABLE public.addresses
ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
ADD COLUMN IF NOT EXISTS recipient_name TEXT NOT NULL,
ADD COLUMN IF NOT EXISTS phone_number TEXT NOT NULL,
ADD COLUMN IF NOT EXISTS address_type TEXT NOT NULL,
ADD COLUMN IF NOT EXISTS street TEXT NOT NULL,
ADD COLUMN IF NOT EXISTS building TEXT,
ADD COLUMN IF NOT EXISTS floor TEXT,
ADD COLUMN IF NOT EXISTS apartment TEXT,
ADD COLUMN IF NOT EXISTS landmark TEXT,
ADD COLUMN IF NOT EXISTS is_default BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS latitude DECIMAL(10,6),
ADD COLUMN IF NOT EXISTS longitude DECIMAL(10,6),
ADD COLUMN IF NOT EXISTS zone TEXT;
```

## Next Steps

1. **Schema Analysis**
   - Complete detailed analysis of all entity fields vs. database columns
   - Document required changes for each entity
   - Identify potential data migration issues

2. **Migration Scripts**
   - Create SQL migration scripts for each table
   - Test migrations on development database
   - Document rollback procedures

3. **Data Mapping**
   - Update repository implementations to map between entities and database schema
   - Handle any data type conversions or transformations
   - Implement proper error handling for data inconsistencies

4. **Testing**
   - Test all CRUD operations with the updated schema
   - Verify data integrity across related tables
   - Ensure backward compatibility with existing code

## Progress Tracking

### Completed Tasks
- ✅ Initial schema analysis for User entity
- ✅ Initial schema analysis for Product entity
- ✅ Initial schema analysis for Category entity
- ✅ Initial schema analysis for Address entity

### In Progress
- 🔄 Detailed field mapping for all entities
- 🔄 Creating SQL migration scripts
- 🔄 Testing schema changes on development database

### Planned
- 🔲 Update repository implementations to work with new schema
- 🔲 Implement data migration utilities
- 🔲 Test all CRUD operations with updated schema
- 🔲 Document final schema design
