import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_providers.dart';
import '../../../core/utils/cart_sync_helper.dart';

/// Test screen for cart synchronization diagnostics
class CartSyncTestScreen extends ConsumerStatefulWidget {
  const CartSyncTestScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CartSyncTestScreen> createState() => _CartSyncTestScreenState();
}

class _CartSyncTestScreenState extends ConsumerState<CartSyncTestScreen> {
  Map<String, bool>? _diagnosticsResults;
  List<String> _recommendations = [];
  bool _isRunningDiagnostics = false;

  @override
  void initState() {
    super.initState();
    // Run diagnostics automatically when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runDiagnostics();
    });
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _isRunningDiagnostics = true;
      _diagnosticsResults = null;
      _recommendations = [];
    });

    try {
      final results = await CartSyncHelper.runDiagnostics();
      final recommendations = CartSyncHelper.getAuthenticationRecommendations(results);

      setState(() {
        _diagnosticsResults = results;
        _recommendations = recommendations;
        _isRunningDiagnostics = false;
      });
    } catch (e) {
      setState(() {
        _isRunningDiagnostics = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Diagnostics failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart Sync Diagnostics'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Auth Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Authentication Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          authState.isAuthenticated ? Icons.check_circle : Icons.cancel,
                          color: authState.isAuthenticated ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          authState.isAuthenticated ? 'Authenticated' : 'Not Authenticated',
                          style: TextStyle(
                            color: authState.isAuthenticated ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    if (authState.user != null) ...[
                      const SizedBox(height: 8),
                      Text('User: ${authState.user!.email}'),
                      Text('ID: ${authState.user!.id}'),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Diagnostics Results Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'System Diagnostics',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _isRunningDiagnostics ? null : _runDiagnostics,
                          child: _isRunningDiagnostics
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Run Test'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    if (_diagnosticsResults != null) ...[
                      ..._diagnosticsResults!.entries.map((entry) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              entry.value ? Icons.check_circle : Icons.cancel,
                              color: entry.value ? Colors.green : Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                entry.key.replaceAll('_', ' ').toUpperCase(),
                                style: TextStyle(
                                  color: entry.value ? Colors.green : Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )).toList(),
                    ] else if (_isRunningDiagnostics) ...[
                      const Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 8),
                            Text('Running diagnostics...'),
                          ],
                        ),
                      ),
                    ] else ...[
                      const Text('Tap "Run Test" to check system status'),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Recommendations Card
            if (_recommendations.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recommendations',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._recommendations.map((recommendation) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                            Expanded(child: Text(recommendation)),
                          ],
                        ),
                      )).toList(),
                    ],
                  ),
                ),
              ),

            const Spacer(),

            // Action Buttons
            if (!authState.isAuthenticated)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/auth');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Go to Login'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
