import 'package:supabase_flutter/supabase_flutter.dart';

/// Script to create a test agent for the Dayliz Agent App
/// This creates a test agent with ID: DLZ-AG-GHY-00001 and password: test123
/// 
/// Usage: dart run scripts/create_test_agent.dart

Future<void> main() async {
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://zdezerezpbeuebnompyj.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpkZXplcmV6cGJldWVibm9tcHlqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQyMDI3MDgsImV4cCI6MjA1OTc3ODcwOH0.VpbFxH9EeSpi-TV6JYUsyQ-nY6C1-KC8_5defc_pMnA',
  );

  final supabase = Supabase.instance.client;
  
  try {
    print('Creating test agent...');
    
    // Test agent details
    const agentId = 'DLZ-AG-GHY-00001';
    const password = 'test123';
    const email = '$agentId@dayliz.internal';
    
    // Step 1: Create auth user
    print('Step 1: Creating auth user with email: $email');
    final authResponse = await supabase.auth.signUp(
      email: email,
      password: password,
    );
    
    if (authResponse.user == null) {
      print('❌ Failed to create auth user');
      return;
    }
    
    print('✅ Auth user created with ID: ${authResponse.user!.id}');
    
    // Step 2: Create agents table if it doesn't exist
    print('Step 2: Ensuring agents table exists...');
    
    // First create the enum type if it doesn't exist
    try {
      await supabase.rpc('create_agent_status_enum');
    } catch (e) {
      // Enum might already exist, that's okay
      print('Note: agent_status enum might already exist');
    }
    
    // Create the agents table
    await supabase.rpc('create_agents_table');
    
    // Step 3: Insert agent record
    print('Step 3: Creating agent record...');
    
    final agentData = {
      'user_id': authResponse.user!.id,
      'agent_id': agentId,
      'full_name': 'Test Agent',
      'phone': '+91 9876543210',
      'email': 'testagent@dayliz.com',
      'assigned_zone': 'Guwahati Zone 1',
      'status': 'active',
      'total_deliveries': 0,
      'total_earnings': 0.00,
      'is_verified': true,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    await supabase.from('agents').insert(agentData);
    
    print('✅ Agent record created successfully!');
    
    // Step 4: Verify the agent was created
    print('Step 4: Verifying agent creation...');
    
    final agentRecord = await supabase
        .from('agents')
        .select()
        .eq('agent_id', agentId)
        .single();
    
    print('✅ Test agent created successfully!');
    print('');
    print('=== Test Agent Details ===');
    print('Agent ID: $agentId');
    print('Password: $password');
    print('Full Name: ${agentRecord['full_name']}');
    print('Phone: ${agentRecord['phone']}');
    print('Status: ${agentRecord['status']}');
    print('Zone: ${agentRecord['assigned_zone']}');
    print('');
    print('You can now use these credentials to login to the agent app!');
    
  } catch (e) {
    print('❌ Error creating test agent: $e');
    
    // If the error is about user already existing, that's okay
    if (e.toString().contains('already registered')) {
      print('');
      print('ℹ️  User already exists. Trying to create agent record only...');
      
      try {
        // Get the existing user
        final existingUser = await supabase.auth.signInWithPassword(
          email: 'DLZ-AG-GHY-00001@dayliz.internal',
          password: 'test123',
        );
        
        if (existingUser.user != null) {
          // Try to create/update the agent record
          final agentData = {
            'user_id': existingUser.user!.id,
            'agent_id': 'DLZ-AG-GHY-00001',
            'full_name': 'Test Agent',
            'phone': '+91 9876543210',
            'email': 'testagent@dayliz.com',
            'assigned_zone': 'Guwahati Zone 1',
            'status': 'active',
            'total_deliveries': 0,
            'total_earnings': 0.00,
            'is_verified': true,
            'updated_at': DateTime.now().toIso8601String(),
          };
          
          await supabase.from('agents').upsert(agentData);
          print('✅ Agent record updated successfully!');
          print('');
          print('=== Test Agent Details ===');
          print('Agent ID: DLZ-AG-GHY-00001');
          print('Password: test123');
          print('Status: Ready for testing!');
        }
      } catch (updateError) {
        print('❌ Error updating agent record: $updateError');
      }
    }
  }
}
