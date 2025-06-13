import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/google_sign_in_tester.dart';
import '../../../core/utils/supabase_config_checker.dart';
import '../../widgets/common/unified_app_bar.dart';
import '../../widgets/common/loading_indicator.dart';

/// A clean architecture debug screen for testing Google Sign-In functionality
class CleanGoogleSignInDebugScreen extends ConsumerStatefulWidget {
  const CleanGoogleSignInDebugScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CleanGoogleSignInDebugScreen> createState() => _CleanGoogleSignInDebugScreenState();
}

class _CleanGoogleSignInDebugScreenState extends ConsumerState<CleanGoogleSignInDebugScreen> {
  bool _isLoading = false;
  final List<String> _logs = [];
  final ScrollController _scrollController = ScrollController();
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  // Configuration status
  bool _isSupabaseConfigured = false;
  bool _isGoogleConfigured = false;
  bool _isDeepLinkConfigured = false;

  @override
  void initState() {
    super.initState();
    _checkConfiguration();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkConfiguration() async {
    setState(() {
      _isLoading = true;
      _logs.clear();
    });

    try {
      _addLog('Checking Supabase configuration...');
      final supabaseConfig = await SupabaseConfigChecker.checkSupabaseConfig();
      _isSupabaseConfigured = supabaseConfig.isConfigured;

      if (_isSupabaseConfigured) {
        _addLog('✅ Supabase is properly configured');
        _addLog('URL: ${supabaseConfig.url?.substring(0, 15)}...');
        _addLog('Anon Key: ${supabaseConfig.anonKey?.substring(0, 10)}...');
      } else {
        _addLog('❌ Supabase is not properly configured');
        if (supabaseConfig.url == null || supabaseConfig.url!.isEmpty) {
          _addLog('  - Missing Supabase URL');
        }
        if (supabaseConfig.anonKey == null || supabaseConfig.anonKey!.isEmpty) {
          _addLog('  - Missing Supabase Anon Key');
        }
      }

      _addLog('\nChecking Google Sign-In configuration...');
      final googleConfig = await GoogleSignInTester.checkGoogleSignInConfig();
      _isGoogleConfigured = googleConfig.isConfigured;

      if (_isGoogleConfigured) {
        _addLog('✅ Google Sign-In is properly configured');
        _addLog('Web Client ID: ${googleConfig.webClientId?.substring(0, 10)}...');
      } else {
        _addLog('❌ Google Sign-In is not properly configured');
        if (googleConfig.webClientId == null || googleConfig.webClientId!.isEmpty) {
          _addLog('  - Missing Web Client ID');
        }
      }

      _addLog('\nChecking Deep Link configuration...');
      final deepLinkConfig = await GoogleSignInTester.checkDeepLinkConfig();
      _isDeepLinkConfigured = deepLinkConfig.isConfigured;

      if (_isDeepLinkConfigured) {
        _addLog('✅ Deep Link is properly configured');
        _addLog('Scheme: ${deepLinkConfig.scheme}');
        _addLog('Host: ${deepLinkConfig.host}');
      } else {
        _addLog('❌ Deep Link is not properly configured');
        _addLog('  - Check AndroidManifest.xml and Info.plist');
      }
    } catch (e) {
      _addLog('❌ Error checking configuration: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testGoogleSignIn() async {
    if (!_isSupabaseConfigured || !_isGoogleConfigured) {
      _addLog('❌ Cannot test Google Sign-In: Configuration issues');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      _addLog('\nTesting Google Sign-In...');

      // This is a placeholder for actual implementation
      _addLog('⚠️ Google Sign-In implementation is currently on hold.');
      _addLog('Using email/password authentication instead.');

      // Show a message to the user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google Sign-In is not currently implemented'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      _addLog('❌ Error testing Google Sign-In: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addLog(String message) {
    setState(() {
      _logs.add(message);
    });

    // Scroll to the bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UnifiedAppBars.withBackButton(
        title: 'Google Sign-In Debug',
        fallbackRoute: '/clean/debug/menu',
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildConfigurationStatus(),
            const SizedBox(height: 16),
            _buildActionButtons(),
            const SizedBox(height: 16),
            Expanded(
              child: _buildLogViewer(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigurationStatus() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configuration Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildStatusItem('Supabase', _isSupabaseConfigured),
            _buildStatusItem('Google Sign-In', _isGoogleConfigured),
            _buildStatusItem('Deep Link', _isDeepLinkConfigured),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Text(
                'Note: Google Sign-In implementation is currently on hold. Using email/password authentication instead.',
                style: TextStyle(color: Colors.amber.shade800, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String name, bool isConfigured) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            isConfigured ? Icons.check_circle : Icons.error,
            color: isConfigured ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Text(
            name,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
          const Spacer(),
          Text(
            isConfigured ? 'Configured' : 'Not Configured',
            style: TextStyle(
              color: isConfigured ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _checkConfiguration,
            child: const Text('Check Configuration'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _testGoogleSignIn,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Test Google Sign-In'),
          ),
        ),
      ],
    );
  }

  Widget _buildLogViewer() {
    if (_isLoading && _logs.isEmpty) {
      return const Center(
        child: LoadingIndicator(message: 'Checking configuration...'),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Logs',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    Color textColor = Colors.white;

                    if (log.contains('✅')) {
                      textColor = Colors.green;
                    } else if (log.contains('❌')) {
                      textColor = Colors.red;
                    } else if (log.contains('⚠️')) {
                      textColor = Colors.yellow;
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Text(
                        log,
                        style: TextStyle(
                          color: textColor,
                          fontFamily: 'monospace',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
