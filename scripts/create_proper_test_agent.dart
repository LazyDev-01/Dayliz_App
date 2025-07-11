import 'package:supabase_flutter/supabase_flutter.dart';

/// Create a proper test agent using Supabase's auth signup API
/// This ensures the user is created correctly through Supabase's proper flow
Future<void> main() async {
  try {
    // Initialize Supabase
    await Supabase.initialize(
      url: 'https://zdezerezpbeuebnompyj.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpkZXplcmV6cGJldWVibm9tcHlqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQyMDI3MDgsImV4cCI6MjA1OTc3ODcwOH0.VpbFxH9EeSpi-TV6JYUsyQ-nY6C1-KC8_5defc_pMnA',
    );

    final supabase = Supabase.instance.client;
    
    print('🔄 Creating proper test agent using Supabase auth signup...');
    
    // Test credentials
    const agentId = 'DLZ-AG-GHY-00002';
    const email = '$agentId@dayliz.internal';
    const password = 'test123';
    
    // Step 1: Sign up using Supabase's proper auth flow
    print('Step 1: Creating auth user via signup...');
    final authResponse = await supabase.auth.signUp(
      email: email,
      password: password,
    );
    
    if (authResponse.user == null) {
      print('❌ Failed to create auth user');
      return;
    }
    
    print('✅ Auth user created: ${authResponse.user!.id}');
    print('   Email: ${authResponse.user!.email}');
    print('   Email confirmed: ${authResponse.user!.emailConfirmedAt != null}');
    
    // Step 2: Create agent record
    print('Step 2: Creating agent record...');
    
    final agentData = {
      'user_id': authResponse.user!.id,
      'agent_id': agentId,
      'full_name': 'Test Agent 2',
      'phone': '+919876543211',
      'email': 'testagent2@dayliz.com',
      'assigned_zone': 'Guwahati Zone 1',
      'status': 'active',
      'total_deliveries': 0,
      'total_earnings': 0.00,
      'is_verified': true,
    };
    
    await supabase.from('agents').insert(agentData);
    print('✅ Agent record created');
    
    // Step 3: Test authentication immediately
    print('Step 3: Testing authentication...');
    
    // Sign out first
    await supabase.auth.signOut();
    
    // Try to sign in
    final testResponse = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    
    if (testResponse.user != null) {
      print('✅ Authentication test successful!');
      print('   User ID: ${testResponse.user!.id}');
      print('   Email: ${testResponse.user!.email}');
      
      // Test agent data fetch
      final agentRecord = await supabase
          .from('agents')
          .select()
          .eq('user_id', testResponse.user!.id)
          .eq('agent_id', agentId)
          .single();
      
      print('✅ Agent data fetch successful!');
      print('   Agent ID: ${agentRecord['agent_id']}');
      print('   Status: ${agentRecord['status']}');
      
      print('');
      print('🎉 SUCCESS! Test agent created and verified:');
      print('   Agent ID: $agentId');
      print('   Password: $password');
      print('   Ready for testing in the app!');
      
    } else {
      print('❌ Authentication test failed');
    }
    
  } catch (e) {
    print('❌ Error: $e');
    print('   Type: ${e.runtimeType}');
  }
}
