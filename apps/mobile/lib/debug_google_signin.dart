import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

/// Minimal Google Sign-In test to isolate the issue
class DebugGoogleSignIn extends StatefulWidget {
  const DebugGoogleSignIn({Key? key}) : super(key: key);

  @override
  State<DebugGoogleSignIn> createState() => _DebugGoogleSignInState();
}

class _DebugGoogleSignInState extends State<DebugGoogleSignIn> {
  String _status = 'Ready to test';
  bool _isLoading = false;
  GoogleSignIn? _googleSignIn;

  @override
  void initState() {
    super.initState();
    _initializeGoogleSignIn();
  }

  void _initializeGoogleSignIn() {
    try {
      debugPrint('🔄 [DebugGoogleSignIn] Initializing Google Sign-In...');
      
      // Initialize without any clientId for Android (should use google-services.json)
      _googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile', 'openid'],
      );
      
      setState(() {
        _status = 'Google Sign-In initialized';
      });
      
      debugPrint('✅ [DebugGoogleSignIn] Google Sign-In initialized successfully');
    } catch (e) {
      debugPrint('❌ [DebugGoogleSignIn] Error initializing Google Sign-In: $e');
      setState(() {
        _status = 'Initialization failed: $e';
      });
    }
  }

  Future<void> _testBasicGoogleSignIn() async {
    if (_googleSignIn == null) {
      setState(() {
        _status = 'Google Sign-In not initialized';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _status = 'Testing basic Google Sign-In...';
    });

    try {
      debugPrint('🔄 [DebugGoogleSignIn] Starting basic Google Sign-In test');
      
      // Step 1: Check if already signed in
      final currentUser = _googleSignIn!.currentUser;
      debugPrint('🔍 [DebugGoogleSignIn] Current user: ${currentUser?.email ?? 'None'}');
      
      // Step 2: Sign out first to ensure clean state
      await _googleSignIn!.signOut();
      debugPrint('🔍 [DebugGoogleSignIn] Signed out from previous session');
      
      // Step 3: Attempt sign in
      debugPrint('🔍 [DebugGoogleSignIn] Calling signIn()...');
      final GoogleSignInAccount? user = await _googleSignIn!.signIn();
      
      if (user == null) {
        debugPrint('❌ [DebugGoogleSignIn] User is null - cancelled or failed');
        setState(() {
          _status = 'Sign-in cancelled or failed';
        });
        return;
      }
      
      debugPrint('✅ [DebugGoogleSignIn] User signed in: ${user.email}');
      debugPrint('🔍 [DebugGoogleSignIn] User ID: ${user.id}');
      debugPrint('🔍 [DebugGoogleSignIn] Display Name: ${user.displayName}');
      
      // Step 4: Get authentication details
      debugPrint('🔍 [DebugGoogleSignIn] Getting authentication...');
      final GoogleSignInAuthentication auth = await user.authentication;
      
      debugPrint('🔍 [DebugGoogleSignIn] Access Token: ${auth.accessToken != null ? 'Present (${auth.accessToken!.length} chars)' : 'NULL'}');
      debugPrint('🔍 [DebugGoogleSignIn] ID Token: ${auth.idToken != null ? 'Present (${auth.idToken!.length} chars)' : 'NULL'}');
      
      if (auth.idToken != null) {
        setState(() {
          _status = '✅ SUCCESS!\nUser: ${user.email}\nID Token: ${auth.idToken!.substring(0, 50)}...';
        });
      } else {
        setState(() {
          _status = '❌ FAILED: ID Token is null\nAccess Token: ${auth.accessToken != null ? 'Present' : 'Also null'}';
        });
      }
      
    } catch (e) {
      debugPrint('❌ [DebugGoogleSignIn] Error during sign-in: $e');
      debugPrint('🔍 [DebugGoogleSignIn] Error type: ${e.runtimeType}');
      
      setState(() {
        _status = '❌ ERROR: $e';
      });
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
        title: const Text('Debug Google Sign-In'),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.bug_report,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Google Sign-In Debug Test',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                _status,
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testBasicGoogleSignIn,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.login),
              label: Text(_isLoading ? 'Testing...' : 'Test Basic Google Sign-In'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'This bypasses all Supabase integration\nand tests Google Sign-In directly.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
