import 'dart:io';
import 'dart:convert';

/// Create a proper test agent using Supabase REST API
/// This ensures the user is created correctly through Supabase's proper flow
///
/// Note: This script uses HTTP requests instead of Supabase client library
/// to avoid Flutter dependencies in a standalone Dart script.
Future<void> main() async {
  // Supabase configuration - Replace with your credentials
  const supabaseUrl = 'https://your-project.supabase.co';  // Replace with your Supabase URL
  const anonKey = 'your_supabase_anon_key_here';  // Replace with your Supabase anon key

  final httpClient = HttpClient();

  try {
    
    print('🔄 Creating proper test agent using Supabase REST API...');

    // Test credentials - Replace with secure password
    const agentId = 'DLZ-AG-GHY-00002';
    const email = '$agentId@dayliz.internal';
    const password = 'your_test_password_here';

    // Step 1: Sign up using Supabase's auth API
    print('Step 1: Creating auth user via signup...');

    final signupRequest = await httpClient.postUrl(
      Uri.parse('$supabaseUrl/auth/v1/signup'),
    );
    signupRequest.headers.set('Content-Type', 'application/json');
    signupRequest.headers.set('apikey', anonKey);
    signupRequest.headers.set('Authorization', 'Bearer $anonKey');

    final signupBody = jsonEncode({
      'email': email,
      'password': password,
    });
    signupRequest.write(signupBody);

    final signupResponse = await signupRequest.close();
    final signupResponseBody = await signupResponse.transform(utf8.decoder).join();

    if (signupResponse.statusCode != 200) {
      print('❌ Failed to create auth user: ${signupResponse.statusCode}');
      print('   Response: $signupResponseBody');
      return;
    }

    final signupData = jsonDecode(signupResponseBody);
    final userId = signupData['user']['id'];
    final userEmail = signupData['user']['email'];

    print('✅ Auth user created: $userId');
    print('   Email: $userEmail');
    print('   Email confirmed: ${signupData['user']['email_confirmed_at'] != null}');
    
    // Step 2: Create agent record
    print('Step 2: Creating agent record...');

    final agentData = {
      'user_id': userId,
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

    final insertRequest = await httpClient.postUrl(
      Uri.parse('$supabaseUrl/rest/v1/agents'),
    );
    insertRequest.headers.set('Content-Type', 'application/json');
    insertRequest.headers.set('apikey', anonKey);
    insertRequest.headers.set('Authorization', 'Bearer $anonKey');
    insertRequest.headers.set('Prefer', 'return=minimal');

    final insertBody = jsonEncode(agentData);
    insertRequest.write(insertBody);

    final insertResponse = await insertRequest.close();

    if (insertResponse.statusCode == 201) {
      print('✅ Agent record created');
    } else {
      final insertResponseBody = await insertResponse.transform(utf8.decoder).join();
      print('❌ Failed to create agent record: ${insertResponse.statusCode}');
      print('   Response: $insertResponseBody');
      return;
    }
    
    // Step 3: Test authentication immediately
    print('Step 3: Testing authentication...');

    // Try to sign in
    final signinRequest = await httpClient.postUrl(
      Uri.parse('$supabaseUrl/auth/v1/token?grant_type=password'),
    );
    signinRequest.headers.set('Content-Type', 'application/json');
    signinRequest.headers.set('apikey', anonKey);
    signinRequest.headers.set('Authorization', 'Bearer $anonKey');

    final signinBody = jsonEncode({
      'email': email,
      'password': password,
    });
    signinRequest.write(signinBody);

    final signinResponse = await signinRequest.close();
    final signinResponseBody = await signinResponse.transform(utf8.decoder).join();

    if (signinResponse.statusCode == 200) {
      final signinData = jsonDecode(signinResponseBody);
      final accessToken = signinData['access_token'];
      final testUserId = signinData['user']['id'];
      final testUserEmail = signinData['user']['email'];

      print('✅ Authentication test successful!');
      print('   User ID: $testUserId');
      print('   Email: $testUserEmail');

      // Test agent data fetch
      final fetchRequest = await httpClient.getUrl(
        Uri.parse('$supabaseUrl/rest/v1/agents?user_id=eq.$testUserId&agent_id=eq.$agentId'),
      );
      fetchRequest.headers.set('apikey', anonKey);
      fetchRequest.headers.set('Authorization', 'Bearer $accessToken');

      final fetchResponse = await fetchRequest.close();
      final fetchResponseBody = await fetchResponse.transform(utf8.decoder).join();

      if (fetchResponse.statusCode == 200) {
        final agentRecords = jsonDecode(fetchResponseBody) as List;
        if (agentRecords.isNotEmpty) {
          final agentRecord = agentRecords.first;
          print('✅ Agent data fetch successful!');
          print('   Agent ID: ${agentRecord['agent_id']}');
          print('   Status: ${agentRecord['status']}');

          print('');
          print('🎉 SUCCESS! Test agent created and verified:');
          print('   Agent ID: $agentId');
          print('   Password: $password');
          print('   Ready for testing in the app!');
        } else {
          print('❌ Agent record not found');
        }
      } else {
        print('❌ Failed to fetch agent data: ${fetchResponse.statusCode}');
        print('   Response: $fetchResponseBody');
      }

    } else {
      print('❌ Authentication test failed: ${signinResponse.statusCode}');
      print('   Response: $signinResponseBody');
    }
    
  } catch (e) {
    print('❌ Error: $e');
    print('   Type: ${e.runtimeType}');
  } finally {
    httpClient.close();
  }
}
