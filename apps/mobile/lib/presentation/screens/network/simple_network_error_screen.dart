import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/services/connectivity_checker.dart';
import '../../widgets/common/inline_error_widget.dart';

/// Simple network error screen that matches the design of NetworkErrorWidgets.connectionProblem()
/// Used during app startup when there's no internet connection
/// Replaces the complex Lottie-based NetworkErrorScreen for consistency
class SimpleNetworkErrorScreen extends StatefulWidget {
  final VoidCallback? onRetrySuccess;

  const SimpleNetworkErrorScreen({
    Key? key,
    this.onRetrySuccess,
  }) : super(key: key);

  @override
  State<SimpleNetworkErrorScreen> createState() => _SimpleNetworkErrorScreenState();
}

class _SimpleNetworkErrorScreenState extends State<SimpleNetworkErrorScreen> {
  bool _isRetrying = false;

  Future<void> _retryConnection() async {
    if (_isRetrying) return;

    setState(() {
      _isRetrying = true;
    });

    HapticFeedback.lightImpact();

    try {
      // Check connectivity using fast mode for better performance
      final hasConnection = await ConnectivityChecker.hasConnection(fastMode: true);
      
      if (hasConnection) {
        // Connection restored
        HapticFeedback.lightImpact();
        
        if (widget.onRetrySuccess != null) {
          widget.onRetrySuccess!();
        } else {
          // Restart the app
          _restartApp();
        }
      } else {
        // Still no connection
        HapticFeedback.heavyImpact();
        _showNoConnectionSnackBar();
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      _showErrorSnackBar();
    } finally {
      if (mounted) {
        setState(() {
          _isRetrying = false;
        });
      }
    }
  }

  void _restartApp() {
    // This will trigger app restart through main.dart
    SystemNavigator.pop(); // Close app - user will reopen
  }

  void _showNoConnectionSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Still no internet connection. Please check your network settings.'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Unable to check connection. Please try again.'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light grey background like other screens
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Use the same error widget design as NetworkErrorWidgets.connectionProblem()
                // but in a full-screen context
                Container(
                  padding: const EdgeInsets.all(32.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Error icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.wifi_off,
                          size: 40,
                          color: Colors.grey[600],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Error message
                      Text(
                        'Connection problem',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Error subtitle
                      Text(
                        'Please check your internet connection and try again',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Retry button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isRetrying ? null : _retryConnection,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isRetrying
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Retry',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // App info
                Text(
                  'Dayliz',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
