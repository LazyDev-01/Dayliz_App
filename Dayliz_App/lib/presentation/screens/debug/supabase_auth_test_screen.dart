import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// A debug screen to test Supabase authentication and address operations
class SupabaseAuthTestScreen extends ConsumerStatefulWidget {
  const SupabaseAuthTestScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SupabaseAuthTestScreen> createState() => _SupabaseAuthTestScreenState();
}

class _SupabaseAuthTestScreenState extends ConsumerState<SupabaseAuthTestScreen> {
  final _outputController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
  }

  @override
  void dispose() {
    _outputController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkCurrentUser() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      setState(() {
        _currentUserId = session.user.id;
      });
      _log('Already logged in as user: ${session.user.id}');
      _log('Email: ${session.user.email}');
    } else {
      _log('Not logged in. Please sign in or sign up.');
    }
  }

  void _log(String message) {
    setState(() {
      _outputController.text += '$message\n';
    });
    debugPrint(message);
  }

  Future<void> _signUp() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _log('Please enter email and password');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      _log('Signing up with email: ${_emailController.text}');

      final response = await Supabase.instance.client.auth.signUp(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (response.user != null) {
        _log('Sign up successful!');
        _log('User ID: ${response.user!.id}');
        setState(() {
          _currentUserId = response.user!.id;
        });
      } else {
        _log('Sign up failed: No user returned');
      }
    } catch (e) {
      _log('Error signing up: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _log('Please enter email and password');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      _log('Signing in with email: ${_emailController.text}');

      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (response.user != null) {
        _log('Sign in successful!');
        _log('User ID: ${response.user!.id}');
        setState(() {
          _currentUserId = response.user!.id;
        });
      } else {
        _log('Sign in failed: No user returned');
      }
    } catch (e) {
      _log('Error signing in: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Supabase.instance.client.auth.signOut();
      _log('Signed out successfully');
      setState(() {
        _currentUserId = null;
      });
    } catch (e) {
      _log('Error signing out: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testAddressInsertion() async {
    if (_currentUserId == null) {
      _log('Error: You must be logged in to test address insertion');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      _log('Testing address insertion...');

      final client = Supabase.instance.client;
      _log('Supabase client initialized');

      // Make sure _currentUserId is not null before using it
      if (_currentUserId == null) {
        _log('Error: User ID is null');
        return;
      }

      // Use the authenticated user ID
      final userId = _currentUserId!;
      _log('Using authenticated user ID: $userId');

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

  Future<void> _listAddresses() async {
    if (_currentUserId == null) {
      _log('Error: You must be logged in to list addresses');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      _log('Listing addresses for user: $_currentUserId');

      final client = Supabase.instance.client;
      // Make sure _currentUserId is not null before using it
      if (_currentUserId != null) {
        final response = await client
            .from('addresses')
            .select()
            .eq('user_id', _currentUserId!);

        _log('Found ${response.length} addresses:');
        for (var address in response) {
          _log('- ${address['address_line1']}, ${address['city']}, ${address['state']}');
        }
      } else {
        _log('Error: User ID is null');
      }


    } catch (e) {
      _log('Error listing addresses: $e');
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
        title: const Text('Supabase Auth & Address Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Authentication status
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _currentUserId != null ? Colors.green.shade100 : Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _currentUserId != null
                    ? 'Logged in as: $_currentUserId'
                    : 'Not logged in',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _currentUserId != null ? Colors.green.shade800 : Colors.red.shade800,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Authentication form
            if (_currentUserId == null) ...[
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signIn,
                      child: const Text('Sign In'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signUp,
                      child: const Text('Sign Up'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Logged in actions
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _testAddressInsertion,
                      child: const Text('Test Address Insertion'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _listAddresses,
                      child: const Text('List Addresses'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _isLoading ? null : _signOut,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade200,
                ),
                child: const Text('Sign Out'),
              ),
            ],

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
