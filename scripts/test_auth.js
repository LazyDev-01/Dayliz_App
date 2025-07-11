// Test Supabase authentication directly
// Run with: node scripts/test_auth.js

const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = 'https://zdezerezpbeuebnompyj.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpkZXplcmV6cGJldWVibm9tcHlqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQyMDI3MDgsImV4cCI6MjA1OTc3ODcwOH0.VpbFxH9EeSpi-TV6JYUsyQ-nY6C1-KC8_5defc_pMnA';

async function testAuth() {
  const supabase = createClient(supabaseUrl, supabaseKey);
  
  console.log('🔄 Testing Supabase authentication...');
  console.log('URL:', supabaseUrl);
  console.log('Key length:', supabaseKey.length);
  
  // Test credentials
  const testCases = [
    {
      name: 'Agent Email Format',
      email: 'DLZ-AG-GHY-00001@dayliz.internal',
      password: 'test123'
    },
    {
      name: 'Simple Email Format',
      email: 'simple.test@dayliz.com',
      password: 'test123'
    },
    {
      name: 'Existing User',
      email: 'newuser1999@gmail.com',
      password: 'test123'  // This will likely fail, but let's see the error
    }
  ];
  
  for (const testCase of testCases) {
    console.log(`\n--- Testing ${testCase.name} ---`);
    console.log(`Email: ${testCase.email}`);
    console.log(`Password length: ${testCase.password.length}`);
    
    try {
      const { data, error } = await supabase.auth.signInWithPassword({
        email: testCase.email,
        password: testCase.password,
      });
      
      if (error) {
        console.log('❌ Auth Error:', error.message);
        console.log('   Status:', error.status);
        console.log('   Code:', error.code);
      } else if (data.user) {
        console.log('✅ Success!');
        console.log('   User ID:', data.user.id);
        console.log('   Email:', data.user.email);
        console.log('   Email confirmed:', data.user.email_confirmed_at !== null);
        
        // Sign out for next test
        await supabase.auth.signOut();
      } else {
        console.log('❌ No user returned');
      }
    } catch (e) {
      console.log('❌ Exception:', e.message);
      console.log('   Type:', e.constructor.name);
    }
  }
}

testAuth().catch(console.error);
