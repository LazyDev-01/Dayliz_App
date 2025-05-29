import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Class that handles database migrations to ensure schema compatibility.
class DatabaseMigrations {
  static final DatabaseMigrations _instance = DatabaseMigrations._internal();
  static DatabaseMigrations get instance => _instance;
  
  late final SupabaseClient _client;
  
  /// Private constructor
  DatabaseMigrations._internal() {
    _client = Supabase.instance.client;
  }
  
  /// Run all migrations in order
  Future<bool> runMigrations() async {
    try {
      debugPrint('Starting database migrations...');
      
      // Migration 1: Add location columns to addresses table
      final locationColumnsAdded = await addLocationColumnsToAddresses();
      if (!locationColumnsAdded) {
        debugPrint('⚠️ Warning: Could not add location columns to addresses table');
      }
      
      debugPrint('Database migrations completed');
      return true;
    } catch (e) {
      debugPrint('❌ Error running migrations: $e');
      return false;
    }
  }
  
  /// Migration 1: Add location columns to the addresses table
  Future<bool> addLocationColumnsToAddresses() async {
    try {
      // First check if the table exists
      final tableExists = await _checkTableExists('addresses');
      if (!tableExists) {
        debugPrint('Addresses table does not exist yet, skipping migration');
        return true; // Not an error, just skip
      }
      
      // Check if column already exists (to avoid errors)
      final latitudeExists = await _checkColumnExists('addresses', 'latitude');
      final longitudeExists = await _checkColumnExists('addresses', 'longitude');
      final zoneExists = await _checkColumnExists('addresses', 'zone');
      
      // Build SQL statements for missing columns
      final alterStatements = <String>[];
      
      if (!latitudeExists) {
        alterStatements.add('ADD COLUMN latitude DECIMAL(10,6)');
      }
      
      if (!longitudeExists) {
        alterStatements.add('ADD COLUMN longitude DECIMAL(10,6)');
      }
      
      if (!zoneExists) {
        alterStatements.add('ADD COLUMN zone TEXT');
      }
      
      // If all columns already exist, we're done
      if (alterStatements.isEmpty) {
        debugPrint('✅ Location columns already exist in addresses table');
        return true;
      }
      
      // Construct and execute the ALTER TABLE statement
      final alterSQL = '''
      ALTER TABLE addresses
      ${alterStatements.join(',\n')};
      ''';
      
      await _client.rpc('execute_sql', params: {'query': alterSQL});
      debugPrint('✅ Added location columns to addresses table');
      
      return true;
    } catch (e) {
      debugPrint('❌ Error adding location columns to addresses: $e');
      return false;
    }
  }
  
  /// Helper to check if a table exists
  Future<bool> _checkTableExists(String tableName) async {
    try {
      final query = '''
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = '$tableName'
      );
      ''';
      
      final result = await _client.rpc('execute_sql', params: {'query': query});
      
      return result?[0]?['exists'] == true;
    } catch (e) {
      debugPrint('Error checking if table $tableName exists: $e');
      return false;
    }
  }
  
  /// Helper to check if a column exists in a table
  Future<bool> _checkColumnExists(String tableName, String columnName) async {
    try {
      final query = '''
      SELECT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = '$tableName' 
        AND column_name = '$columnName'
      );
      ''';
      
      final result = await _client.rpc('execute_sql', params: {'query': query});
      
      return result?[0]?['exists'] == true;
    } catch (e) {
      debugPrint('Error checking if column $columnName exists in $tableName: $e');
      return false;
    }
  }
} 