import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// A debug screen to test Supabase connection and database operations
class SupabaseConnectionTestScreen extends ConsumerStatefulWidget {
  const SupabaseConnectionTestScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SupabaseConnectionTestScreen> createState() => _SupabaseConnectionTestScreenState();
}

class _SupabaseConnectionTestScreenState extends ConsumerState<SupabaseConnectionTestScreen> {
  final _outputController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _outputController.dispose();
    super.dispose();
  }

  void _log(String message) {
    setState(() {
      _outputController.text += '$message\n';
    });
    debugPrint(message);
  }

  Future<void> _testSupabaseConnection() async {
    setState(() {
      _isLoading = true;
      _outputController.clear();
    });

    try {
      _log('Testing Supabase connection...');

      final client = Supabase.instance.client;
      _log('Supabase client initialized');

      // Test basic query
      _log('Testing basic query...');
      final response = await client.from('addresses').select();
      _log('Query successful: ${response.length} addresses found');

      // Get table structure
      _log('\nGetting table structure...');
      try {
        final tableInfo = await client.rpc('get_table_info', params: {'table_name': 'addresses'});
        _log('Table structure: $tableInfo');
      } catch (e) {
        _log('Could not get table structure: $e');
        _log('This is normal if the RPC function is not defined');
      }

      _log('Connection test passed!');
    } catch (e) {
      _log('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testAddressInsertion() async {
    setState(() {
      _isLoading = true;
      _outputController.clear();
    });

    try {
      _log('Testing address insertion...');

      final client = Supabase.instance.client;
      _log('Supabase client initialized');

      // Use a test UUID instead of relying on authenticated user
      final userId = const Uuid().v4();
      _log('Using test user ID (UUID): $userId');

      // Create test address data
      final addressId = const Uuid().v4();
      _log('Generated address ID: $addressId');

      final addressData = {
        'id': addressId,
        'user_id': userId,
        'address_line1': 'Test Address Line 1',
        'city': 'Tura',
        'state': 'Meghalaya',
        'postal_code': '794101',
        'country': 'India',
        'is_default': false,
        'label': 'Test',
      };

      _log('Inserting address with data: $addressData');

      // Insert the address
      final response = await client
          .from('addresses')
          .insert(addressData)
          .select();

      _log('Insertion successful!');
      _log('Response: $response');

      // Verify the address was inserted
      final verifyResponse = await client
          .from('addresses')
          .select()
          .eq('id', addressId)
          .single();

      _log('Verification successful!');
      _log('Retrieved address: $verifyResponse');
    } catch (e) {
      _log('Error: $e');
      if (e is PostgrestException) {
        _log('PostgrestException details:');
        _log('Message: ${e.message}');
        _log('Details: ${e.details}');
        _log('Hint: ${e.hint}');
        _log('Code: ${e.code}');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supabase Connection Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _testSupabaseConnection,
              child: const Text('Test Supabase Connection'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _testAddressInsertion,
              child: const Text('Test Address Insertion'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _outputController,
                  maxLines: null,
                  readOnly: true,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Output will appear here...',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
