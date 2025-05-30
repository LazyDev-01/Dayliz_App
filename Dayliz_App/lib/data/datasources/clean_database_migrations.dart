import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get_it/get_it.dart';

import '../../domain/usecases/is_authenticated_usecase.dart';

/// Clean architecture implementation of database migrations
/// This class is responsible for running database migrations
class CleanDatabaseMigrations {
  static final CleanDatabaseMigrations _instance = CleanDatabaseMigrations._internal();
  static CleanDatabaseMigrations get instance => _instance;

  final SupabaseClient _client = Supabase.instance.client;
  final IsAuthenticatedUseCase _isAuthenticatedUseCase = GetIt.instance<IsAuthenticatedUseCase>();

  CleanDatabaseMigrations._internal();

  /// Check if the user is authenticated before running migrations
  Future<bool> _checkAuthentication() async {
    try {
      final isAuthenticated = await _isAuthenticatedUseCase.call();
      return isAuthenticated;
    } catch (e) {
      debugPrint('Error checking authentication: $e');
      return false;
    }
  }

  /// Run all migrations in order
  Future<bool> runMigrations() async {
    // Check authentication
    final isAuthenticated = await _checkAuthentication();
    if (!isAuthenticated) {
      debugPrint('Not authenticated. Cannot run migrations.');
      return false;
    }

    try {
      debugPrint('Starting database migrations...');

      // Migration 1: Add location columns to addresses table
      final locationColumnsAdded = await addLocationColumnsToAddresses();
      if (!locationColumnsAdded) {
        debugPrint('⚠️ Warning: Could not add location columns to addresses table');
      }

      // Migration 2: Add full-text search to products table
      final fullTextSearchAdded = await addFullTextSearchToProducts();
      if (!fullTextSearchAdded) {
        debugPrint('⚠️ Warning: Could not add full-text search to products table');
      }

      // Migration 3: Add geospatial functions
      final geospatialFunctionsAdded = await addGeospatialFunctions();
      if (!geospatialFunctionsAdded) {
        debugPrint('⚠️ Warning: Could not add geospatial functions');
      }

      debugPrint('Database migrations completed');
      return true;
    } catch (e) {
      debugPrint('❌ Error running migrations: $e');
      return false;
    }
  }

  /// Migration 1: Add location columns to addresses table
  Future<bool> addLocationColumnsToAddresses() async {
    try {
      debugPrint('Running migration: Add location columns to addresses table');

      // Check if the columns already exist
      bool columnsExist = false;
      try {
        final result = await _client.rpc('exec_sql', params: {
          'sql': "SELECT column_name FROM information_schema.columns WHERE table_name = 'addresses' AND column_name = 'latitude'"
        });
        columnsExist = result.length > 0;
      } catch (e) {
        debugPrint('Error checking if columns exist: $e');
      }

      if (columnsExist) {
        debugPrint('Location columns already exist in addresses table, skipping migration');
        return true;
      }

      // Add the columns
      const sql = '''
      -- Add location columns to addresses table
      ALTER TABLE addresses
      ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION,
      ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION,
      ADD COLUMN IF NOT EXISTS geolocation GEOGRAPHY(POINT);

      -- Add function to update geolocation from lat/long
      CREATE OR REPLACE FUNCTION update_address_geolocation()
      RETURNS TRIGGER AS \$\$
      BEGIN
        IF NEW.latitude IS NOT NULL AND NEW.longitude IS NOT NULL THEN
          NEW.geolocation = ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326)::geography;
        END IF;
        RETURN NEW;
      END;
      \$\$ LANGUAGE plpgsql;

      -- Add trigger to update geolocation
      DROP TRIGGER IF EXISTS update_address_geolocation_trigger ON addresses;
      CREATE TRIGGER update_address_geolocation_trigger
      BEFORE INSERT OR UPDATE ON addresses
      FOR EACH ROW
      EXECUTE FUNCTION update_address_geolocation();
      ''';

      await _client.rpc('exec_sql', params: {'sql': sql});

      debugPrint('✅ Successfully added location columns to addresses table');
      return true;
    } catch (e) {
      debugPrint('❌ Error adding location columns to addresses table: $e');
      return false;
    }
  }

  /// Migration 2: Add full-text search to products table
  Future<bool> addFullTextSearchToProducts() async {
    try {
      debugPrint('Running migration: Add full-text search to products table');

      // Check if the function already exists
      bool functionExists = false;
      try {
        final result = await _client.rpc('exec_sql', params: {
          'sql': "SELECT routine_name FROM information_schema.routines WHERE routine_name = 'search_products_full_text'"
        });
        functionExists = result.length > 0;
      } catch (e) {
        debugPrint('Error checking if function exists: $e');
      }

      if (functionExists) {
        debugPrint('Full-text search function already exists, skipping migration');
        return true;
      }

      // Add the full-text search function
      const sql = '''
      -- Add tsvector column to products table
      ALTER TABLE products
      ADD COLUMN IF NOT EXISTS search_vector tsvector;

      -- Create function to update search vector
      CREATE OR REPLACE FUNCTION update_product_search_vector()
      RETURNS TRIGGER AS \$\$
      BEGIN
        NEW.search_vector =
          setweight(to_tsvector('english', coalesce(NEW.name, '')), 'A') ||
          setweight(to_tsvector('english', coalesce(NEW.description, '')), 'B') ||
          setweight(to_tsvector('english', coalesce(NEW.brand, '')), 'C');
        RETURN NEW;
      END;
      \$\$ LANGUAGE plpgsql;

      -- Add trigger to update search vector
      DROP TRIGGER IF EXISTS update_product_search_vector_trigger ON products;
      CREATE TRIGGER update_product_search_vector_trigger
      BEFORE INSERT OR UPDATE ON products
      FOR EACH ROW
      EXECUTE FUNCTION update_product_search_vector();

      -- Update existing products
      UPDATE products SET search_vector =
        setweight(to_tsvector('english', coalesce(name, '')), 'A') ||
        setweight(to_tsvector('english', coalesce(description, '')), 'B') ||
        setweight(to_tsvector('english', coalesce(brand, '')), 'C');

      -- Create index for search vector
      CREATE INDEX IF NOT EXISTS products_search_vector_idx ON products USING GIN(search_vector);

      -- Create search function
      CREATE OR REPLACE FUNCTION search_products_full_text(
        search_query TEXT,
        category_id_param UUID DEFAULT NULL,
        subcategory_id_param UUID DEFAULT NULL,
        min_price DECIMAL DEFAULT NULL,
        max_price DECIMAL DEFAULT NULL,
        in_stock_only BOOLEAN DEFAULT FALSE,
        on_sale_only BOOLEAN DEFAULT FALSE,
        sort_by TEXT DEFAULT 'relevance',
        page_number INTEGER DEFAULT 1,
        page_size INTEGER DEFAULT 20
      )
      RETURNS SETOF products AS \$\$
      DECLARE
        query_tsquery tsquery;
        offset_val INTEGER;
      BEGIN
        -- Convert search query to tsquery
        IF search_query IS NOT NULL AND search_query <> '' THEN
          query_tsquery = to_tsquery('english', search_query);
        ELSE
          query_tsquery = to_tsquery('english', '');
        END IF;

        -- Calculate offset
        offset_val := (page_number - 1) * page_size;

        -- Return filtered products
        RETURN QUERY
        SELECT p.*
        FROM products p
        WHERE
          (search_query IS NULL OR search_query = '' OR p.search_vector @@ query_tsquery) AND
          (category_id_param IS NULL OR p.category_id = category_id_param) AND
          (subcategory_id_param IS NULL OR p.subcategory_id = subcategory_id_param) AND
          (min_price IS NULL OR p.price >= min_price) AND
          (max_price IS NULL OR p.price <= max_price) AND
          (NOT in_stock_only OR p.in_stock = TRUE) AND
          (NOT on_sale_only OR p.discount_percentage > 0)
        ORDER BY
          CASE
            WHEN sort_by = 'relevance' AND search_query <> '' THEN ts_rank(p.search_vector, query_tsquery)
            WHEN sort_by = 'price_asc' THEN p.price
            WHEN sort_by = 'price_desc' THEN -p.price
            WHEN sort_by = 'name_asc' THEN p.name
            WHEN sort_by = 'name_desc' THEN NULL
            ELSE NULL
          END DESC NULLS LAST,
          CASE WHEN sort_by = 'name_desc' THEN p.name END DESC,
          p.created_at DESC
        LIMIT page_size
        OFFSET offset_val;
      END;
      \$\$ LANGUAGE plpgsql;
      ''';

      await _client.rpc('exec_sql', params: {'sql': sql});

      debugPrint('✅ Successfully added full-text search to products table');
      return true;
    } catch (e) {
      debugPrint('❌ Error adding full-text search to products table: $e');
      return false;
    }
  }

  /// Migration 3: Add geospatial functions
  Future<bool> addGeospatialFunctions() async {
    try {
      debugPrint('Running migration: Add geospatial functions');

      // Check if the function already exists
      bool functionExists = false;
      try {
        final result = await _client.rpc('exec_sql', params: {
          'sql': "SELECT routine_name FROM information_schema.routines WHERE routine_name = 'find_addresses_within_radius'"
        });
        functionExists = result.length > 0;
      } catch (e) {
        debugPrint('Error checking if function exists: $e');
      }

      if (functionExists) {
        debugPrint('Geospatial functions already exist, skipping migration');
        return true;
      }

      // Add the geospatial functions
      const sql = '''
      -- Function to find addresses within a radius
      CREATE OR REPLACE FUNCTION find_addresses_within_radius(
        lat DOUBLE PRECISION,
        lng DOUBLE PRECISION,
        radius_meters DOUBLE PRECISION,
        user_id_param UUID DEFAULT NULL
      )
      RETURNS TABLE (
        id UUID,
        user_id UUID,
        address_line1 TEXT,
        address_line2 TEXT,
        city TEXT,
        state TEXT,
        postal_code TEXT,
        country TEXT,
        is_default BOOLEAN,
        latitude DOUBLE PRECISION,
        longitude DOUBLE PRECISION,
        distance_meters DOUBLE PRECISION
      ) AS \$\$
      BEGIN
        RETURN QUERY
        SELECT
          a.id,
          a.user_id,
          a.address_line1,
          a.address_line2,
          a.city,
          a.state,
          a.postal_code,
          a.country,
          a.is_default,
          a.latitude,
          a.longitude,
          ST_Distance(
            a.geolocation,
            ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography
          ) AS distance_meters
        FROM
          addresses a
        WHERE
          a.geolocation IS NOT NULL AND
          (user_id_param IS NULL OR a.user_id = user_id_param) AND
          ST_DWithin(
            a.geolocation,
            ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography,
            radius_meters
          )
        ORDER BY
          distance_meters ASC;
      END;
      \$\$ LANGUAGE plpgsql;
      ''';

      await _client.rpc('exec_sql', params: {'sql': sql});

      debugPrint('✅ Successfully added geospatial functions');
      return true;
    } catch (e) {
      debugPrint('❌ Error adding geospatial functions: $e');
      return false;
    }
  }
}
