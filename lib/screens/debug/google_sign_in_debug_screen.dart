import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/google_sign_in_tester.dart';
import '../../utils/supabase_config_checker.dart';
import '../../services/direct_google_sign_in_service.dart';

class GoogleSignInDebugScreen extends StatefulWidget {
  const GoogleSignInDebugScreen({Key? key}) : super(key: key);

  @override
  State<GoogleSignInDebugScreen> createState() => _GoogleSignInDebugScreenState();
}

class _GoogleSignInDebugScreenState extends State<GoogleSignInDebugScreen> {
  bool _isLoading = false;
  String _resultText = '';
  Map<String, dynamic> _configResult = {};
  Map<String, dynamic> _testResult = {};
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkConfig();
  }

  Future<void> _checkConfig() async {
    setState(() {
      _isLoading = true;
      _resultText = 'Checking configuration...';
    });

    try {
      // Check Supabase configuration
      final configResult = await SupabaseConfigChecker.checkSupabaseConfig();

      // Test Google Sign-In configuration
      final testResult = await GoogleSignInTester.testGoogleSignInConfig();

      setState(() {
        _configResult = configResult;
        _testResult = testResult;
        _resultText = 'Configuration check complete';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error checking configuration: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _resultText = 'Testing Google Sign-In...';
      _errorMessage = '';
    });

    try {
      // Try the direct approach first
      final directService = DirectGoogleSignInService.instance;

      // Show a message to the user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google Sign-In window will open. Please complete the sign-in process.'),
            duration: Duration(seconds: 5),
          ),
        );
      }

      final response = await directService.signIn();

      setState(() {
        _resultText = 'Google Sign-In successful!';
        _isLoading = false;
      });

      // Show success dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Success'),
            content: Text('Successfully signed in as ${response?.user?.email}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ [GoogleSignInDebugScreen] Error: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _enableGoogleProvider() async {
    setState(() {
      _isLoading = true;
      _resultText = 'Enabling Google provider...';
      _errorMessage = '';
    });

    try {
      final client = Supabase.instance.client;

      // Get the Google client ID and secret from environment variables
      final googleClientId = _testResult['googleClientId'] ?? '';
      const googleClientSecret = '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'; // This should be stored securely

      if (googleClientId.isEmpty) {
        throw Exception('Google Client ID not found in environment variables');
      }

      // Call the Edge Function to enable the Google provider
      final response = await client.functions.invoke(
        'enable-google-provider',
        body: {
          'clientId': googleClientId,
          'clientSecret': googleClientSecret,
          'redirectUrl': 'com.dayliz.dayliz_app://login',
        },
      );

      debugPrint('🔍 [GoogleSignInDebugScreen] Enable Google provider response: ${response.data}');

      if (response.data != null && response.data['success'] == true) {
        setState(() {
          _resultText = 'Google provider enabled successfully!';
          _isLoading = false;
        });

        // Refresh the configuration
        await _checkConfig();

        // Show success dialog
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Success'),
              content: const Text('Google provider has been enabled. Please restart the app and try signing in again.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } else {
        throw Exception('Failed to enable Google provider');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error enabling Google provider: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Sign-In Debug'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Configuration section
            const Text(
              'Supabase Configuration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildConfigItem('Supabase Initialized', _configResult['isInitialized'] == true ? '✅ Yes' : '❌ No'),
            _buildConfigItem('Has Supabase Client', _configResult['hasClient'] == true ? '✅ Yes' : '❌ No'),
            _buildConfigItem('Current User', _configResult['currentUser'] ?? 'None'),
            _buildConfigItem('Google Provider Configured', _configResult['googleProviderConfigured'] == true ? '✅ Yes' : '❌ No'),

            const SizedBox(height: 16),
            const Text(
              'Google Sign-In Configuration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildConfigItem('Supabase URL', _testResult['supabaseUrl'] ?? 'Not found'),
            _buildConfigItem('Supabase Anon Key', _testResult['supabaseAnonKey'] ?? 'Not found'),
            _buildConfigItem('Google Client ID', _testResult['googleClientId'] ?? 'Not found'),
            _buildConfigItem('Google Redirect URI', _testResult['googleRedirectUri'] ?? 'Not found'),
            _buildConfigItem('Google Provider Enabled', _testResult['isGoogleProviderEnabled'] == true ? '✅ Yes' : '❌ No'),

            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Error',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red.shade800),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Detailed Error Information'),
                      content: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Error Message:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(_errorMessage),
                            const SizedBox(height: 16),
                            const Text('Troubleshooting Steps:', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            const Text('1. Check that the Google provider is enabled in Supabase'),
                            const Text('2. Verify that the redirect URL is set correctly in both Supabase and Google Cloud Console'),
                            const Text('3. Make sure your app\'s Site URL is set to com.dayliz.dayliz_app://login'),
                            const Text('4. Check that your Google client ID and secret are correct'),
                            const Text('5. Try clearing app data and cache, then restart'),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.info_outline),
                label: const Text('Show Troubleshooting Steps'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ],

            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: _isLoading ? null : _checkConfig,
                    child: const Text('Refresh Configuration'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _testGoogleSignIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Test Google Sign-In'),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: const Text(
                      'Note: Google Sign-In implementation is currently on hold. Using email/password authentication instead.',
                      style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : () {
                      // Test the deep link handling directly
                      final uri = Uri.parse('com.dayliz.dayliz_app://login');
                      debugPrint('🔍 [GoogleSignInDebugScreen] Testing deep link: $uri');

                      // Show a message to the user
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Testing deep link handling...'),
                          duration: Duration(seconds: 3),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Test Deep Link'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : () {
                      // Show the Android manifest check dialog
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Android Manifest Check'),
                          content: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('Check your AndroidManifest.xml for the following:', style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                const Text('1. Intent filter for deep links:'),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
'''<intent-filter>
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="com.dayliz.dayliz_app" android:host="login" />
</intent-filter>''',
                                    style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text('2. Make sure your package name matches:'),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('package="com.dayliz.dayliz_app"',
                                    style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Check Android Manifest'),
                  ),
                  const SizedBox(height: 16),
                  if (_testResult['isGoogleProviderEnabled'] == false) ...[
                    ElevatedButton(
                      onPressed: _isLoading ? null : _enableGoogleProvider,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Enable Google Provider'),
                    ),
                  ],
                ],
              ),
            ),

            if (_isLoading) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 8),
              Center(child: Text(_resultText)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConfigItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
