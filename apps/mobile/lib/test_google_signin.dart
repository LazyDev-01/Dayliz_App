import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'core/services/google_sign_in_service.dart';

/// Simple test widget to test Google Sign-in functionality
class GoogleSignInTest extends StatefulWidget {
  const GoogleSignInTest({Key? key}) : super(key: key);

  @override
  State<GoogleSignInTest> createState() => _GoogleSignInTestState();
}

class _GoogleSignInTestState extends State<GoogleSignInTest> {
  String _status = 'Ready to test';
  bool _isLoading = false;

  Future<void> _testGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing Google Sign-in...';
    });

    try {
      debugPrint('🧪 [GoogleSignInTest] Starting Google Sign-in test');
      
      final googleService = GoogleSignInService.instance;
      final response = await googleService.signInWithGoogle();
      
      if (response != null && response.user != null) {
        setState(() {
          _status = '✅ Success! User: ${response.user!.email}';
        });
        debugPrint('✅ [GoogleSignInTest] Success: ${response.user!.email}');
      } else {
        setState(() {
          _status = '❌ Failed: No user returned';
        });
        debugPrint('❌ [GoogleSignInTest] Failed: No user returned');
      }
    } catch (e) {
      setState(() {
        _status = '❌ Error: $e';
      });
      debugPrint('❌ [GoogleSignInTest] Error: $e');
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
        title: const Text('Google Sign-In Test'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.science,
              size: 64,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            const Text(
              'Google Sign-In Test',
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
              ),
              child: Text(
                _status,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testGoogleSignIn,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.login),
              label: Text(_isLoading ? 'Testing...' : 'Test Google Sign-In'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'This will test the Google Sign-in configuration\nand show any errors in the console.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
