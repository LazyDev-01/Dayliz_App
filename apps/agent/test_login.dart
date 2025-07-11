import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Simple test script to verify agent login credentials work
/// Run with: dart run test_login.dart

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://zdezerezpbeuebnompyj.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpkZXplcmV6cGJldWVibm9tcHlqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQyMDI3MDgsImV4cCI6MjA1OTc3ODcwOH0.VpbFxH9EeSpi-TV6JYUsyQ-nY6C1-KC8_5defc_pMnA',
  );

  final supabase = Supabase.instance.client;
  
  print('🔄 Testing Agent Login Credentials...');
  print('');
  
  // Test credentials
  const email = 'testuser@gmail.com';
  const password = 'test123';
  
  try {
    print('Step 1: Testing Supabase Auth Login...');
    print('Email: $email');
    print('Password: $password');
    
    // Test authentication
    final authResponse = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    
    if (authResponse.user == null) {
      print('❌ Auth failed: No user returned');
      return;
    }
    
    print('✅ Auth successful!');
    print('User ID: ${authResponse.user!.id}');
    print('User Email: ${authResponse.user!.email}');
    print('');
    
    print('Step 2: Fetching Agent Data...');
    
    // Fetch agent data
    final agentData = await supabase
        .from('agents')
        .select()
        .eq('user_id', authResponse.user!.id)
        .single();
    
    print('✅ Agent data found!');
    print('Agent ID: ${agentData['agent_id']}');
    print('Full Name: ${agentData['full_name']}');
    print('Email: ${agentData['email']}');
    print('Phone: ${agentData['phone']}');
    print('Status: ${agentData['status']}');
    print('Verified: ${agentData['is_verified']}');
    print('Zone: ${agentData['assigned_zone']}');
    print('');
    
    // Check status
    if (agentData['status'] == 'active' && agentData['is_verified'] == true) {
      print('🎉 SUCCESS! Test agent is ready for login.');
      print('');
      print('=== LOGIN CREDENTIALS ===');
      print('Email: $email');
      print('Password: $password');
      print('Agent ID: ${agentData['agent_id']}');
      print('Status: Ready for testing! ✅');
    } else {
      print('⚠️  Agent found but not active/verified');
      print('Status: ${agentData['status']}');
      print('Verified: ${agentData['is_verified']}');
    }
    
    // Sign out
    await supabase.auth.signOut();
    print('');
    print('✅ Test completed successfully!');
    
  } catch (e) {
    print('❌ Test failed: $e');
    print('');
    print('Troubleshooting:');
    print('1. Check if user exists in auth.users table');
    print('2. Check if agent record exists in agents table');
    print('3. Verify password is correct');
    print('4. Check internet connection');
  }
}
