import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Simple test script to verify agent login credentials work
/// Run with: dart run test_login.dart

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase - Replace with your credentials
  await Supabase.initialize(
    url: 'https://your-project.supabase.co',  // Replace with your Supabase URL
    anonKey: 'your_supabase_anon_key_here',  // Replace with your Supabase anon key
  );

  final supabase = Supabase.instance.client;
  
  print('🔄 Testing Agent Login Credentials...');
  print('');
  
  // Test credentials - Replace with secure password
  const email = 'testuser@gmail.com';
  const password = 'your_test_password_here';
  
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
