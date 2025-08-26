import 'package:supabase_flutter/supabase_flutter.dart';

/// Test Supabase authentication directly to isolate the issue
Future<void> main() async {
  try {
    // Initialize Supabase - Replace with your credentials
    await Supabase.initialize(
      url: 'https://your-project.supabase.co',  // Replace with your Supabase URL
      anonKey: 'your_supabase_anon_key_here',  // Replace with your Supabase anon key
      debug: true,
    );

    final supabase = Supabase.instance.client;
    
    print('🔄 Testing Supabase authentication...');
    
    // Test credentials - Replace with secure password
    const email = 'simple.test@dayliz.com';
    const password = 'your_test_password_here';
    
    print('Email: $email');
    print('Password length: ${password.length}');
    
    // Test authentication
    print('\n🔄 Attempting authentication...');
    final response = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    
    if (response.user != null) {
      print('✅ Authentication successful!');
      print('User ID: ${response.user!.id}');
      print('Email: ${response.user!.email}');
      print('Email confirmed: ${response.user!.emailConfirmedAt != null}');
      
      // Test agent data fetch
      print('\n🔄 Fetching agent data...');
      final agentData = await supabase
          .from('agents')
          .select()
          .eq('user_id', response.user!.id)
          .single();
      
      print('✅ Agent data fetched successfully!');
      print('Agent ID: ${agentData['agent_id']}');
      print('Full Name: ${agentData['full_name']}');
      print('Status: ${agentData['status']}');
      print('Phone: ${agentData['phone']}');
      
      print('\n🎉 All tests passed! The credentials work correctly.');
      
    } else {
      print('❌ Authentication failed - no user returned');
    }
    
  } catch (e) {
    print('❌ Error: $e');
    print('Type: ${e.runtimeType}');
    
    if (e.toString().contains('Invalid login credentials')) {
      print('\n💡 This suggests the email/password combination is incorrect.');
      print('   The user might not exist or the password is wrong.');
    }
  }
}
