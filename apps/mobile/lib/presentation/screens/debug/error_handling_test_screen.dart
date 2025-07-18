import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/common/inline_error_widget.dart';
import '../../../core/utils/error_message_mapper.dart';

/// Test screen to validate the new error handling implementation
class ErrorHandlingTestScreen extends ConsumerWidget {
  const ErrorHandlingTestScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error Handling Test'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Error Message Mapping Tests'),
            const SizedBox(height: 16),
            _buildErrorMappingTests(),
            
            const SizedBox(height: 32),
            _buildSectionHeader('Inline Error Widget Tests'),
            const SizedBox(height: 16),
            _buildInlineErrorTests(),
            
            const SizedBox(height: 32),
            _buildSectionHeader('Specialized Error Widgets'),
            const SizedBox(height: 16),
            _buildSpecializedErrorTests(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildErrorMappingTests() {
    final testErrors = [
      'ClientException with SocketException: Failed host lookup: zdezerezpbeuebnompyj.supabase.co',
      'TimeoutException after 0:00:30.000000: Future not completed',
      'FormatException: Unexpected character',
      'Server returned status code 500',
      'Authentication failed',
    ];

    return Column(
      children: testErrors.map((error) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Original: $error',
                  style: const TextStyle(fontSize: 12, color: Colors.red),
                ),
                const SizedBox(height: 8),
                Text(
                  'Mapped: ${ErrorMessageMapper.mapErrorToUserFriendlyMessage(error)}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                Text(
                  'Subtitle: ${ErrorMessageMapper.getErrorSubtitle(error)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInlineErrorTests() {
    return Column(
      children: [
        // Basic inline error
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: InlineErrorWidget(
              message: 'Unable to load content',
              subtitle: 'Please check your connection and try again',
              onRetry: () => _showSnackBar('Retry button pressed!'),
              isCompact: true,
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Full size inline error
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: InlineErrorWidget(
              message: 'Service temporarily unavailable',
              subtitle: 'Our servers are having issues. Please try again in a moment',
              onRetry: () => _showSnackBar('Full size retry pressed!'),
              icon: Icons.cloud_off,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpecializedErrorTests() {
    return Column(
      children: [
        // Categories error
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: NetworkErrorWidgets.loadingFailed(
              dataType: 'categories',
              onRetry: () => _showSnackBar('Categories retry pressed!'),
              isCompact: true,
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Cart error
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: NetworkErrorWidgets.cartOperationFailed(
              onRetry: () => _showSnackBar('Cart retry pressed!'),
              isCompact: true,
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Search error
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: NetworkErrorWidgets.searchFailed(
              onRetry: () => _showSnackBar('Search retry pressed!'),
              isCompact: true,
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Orders error
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: NetworkErrorWidgets.ordersFailed(
              onRetry: () => _showSnackBar('Orders retry pressed!'),
              isCompact: true,
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Network error
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: NetworkErrorWidgets.networkError(
              onRetry: () => _showSnackBar('Network retry pressed!'),
              isCompact: true,
            ),
          ),
        ),
      ],
    );
  }

  void _showSnackBar(String message) {
    // This would show a snackbar in a real implementation
    debugPrint('Test: $message');
  }
}
