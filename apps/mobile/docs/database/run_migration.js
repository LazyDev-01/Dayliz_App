/**
 * Script to run the MCP server migrations
 * This script simplifies the user_profiles table to match the UserProfile entity
 */

const { runMigrations } = require('./mcp_server');

// Get Supabase credentials from environment variables or command line arguments
const getSupabaseCredentials = () => {
  let supabaseUrl = process.env.SUPABASE_URL;
  let supabaseKey = process.env.SUPABASE_SERVICE_KEY;
  
  // Check for command line arguments
  process.argv.forEach((arg, index) => {
    if (arg === '--url' && process.argv[index + 1]) {
      supabaseUrl = process.argv[index + 1];
    }
    if (arg === '--key' && process.argv[index + 1]) {
      supabaseKey = process.argv[index + 1];
    }
  });
  
  return { supabaseUrl, supabaseKey };
};

// Main function
const main = async () => {
  console.log('Starting user_profiles simplification migration...');
  
  const { supabaseUrl, supabaseKey } = getSupabaseCredentials();
  
  if (!supabaseUrl || !supabaseKey) {
    console.error('Error: Supabase URL and service key are required.');
    console.error('Set them as environment variables SUPABASE_URL and SUPABASE_SERVICE_KEY');
    console.error('Or provide them as command line arguments: --url <url> --key <key>');
    process.exit(1);
  }
  
  try {
    const result = await runMigrations(supabaseUrl, supabaseKey);
    
    if (result.success) {
      console.log('Migration completed successfully!');
      process.exit(0);
    } else {
      console.error('Migration failed:', result.error);
      process.exit(1);
    }
  } catch (error) {
    console.error('Unexpected error during migration:', error);
    process.exit(1);
  }
};

// Run the main function
main();
