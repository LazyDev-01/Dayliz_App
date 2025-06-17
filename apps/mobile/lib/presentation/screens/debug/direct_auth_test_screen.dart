import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Direct access screen for testing premium auth screens
/// Use this when debug menu isn't working
class DirectAuthTestScreen extends StatelessWidget {
  const DirectAuthTestScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🚀 Direct Auth Testing'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green, Colors.green.shade700],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.rocket_launch,
                    color: Colors.white,
                    size: 48,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Premium Auth Testing',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Direct access to premium authentication screens',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Test Buttons
            _buildTestButton(
              context,
              title: '🎨 Premium Auth Landing',
              subtitle: 'Beautiful animated auth screen with 3 options',
              color: Colors.blue,
              onTap: () => context.push('/test-premium-auth'),
            ),
            
            const SizedBox(height: 16),
            
            _buildTestButton(
              context,
              title: '📱 Phone Authentication',
              subtitle: 'International phone input with validation',
              color: Colors.orange,
              onTap: () => context.push('/test-phone-auth'),
            ),
            
            const SizedBox(height: 16),
            
            _buildTestButton(
              context,
              title: '🔢 OTP Verification',
              subtitle: '6-digit PIN input with auto-focus',
              color: Colors.purple,
              onTap: () => context.push('/test-otp'),
            ),
            
            const SizedBox(height: 32),
            
            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📋 Testing Instructions:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '1. Tap any button above to test that screen\n'
                    '2. Check animations and UI design\n'
                    '3. Test interactions and navigation\n'
                    '4. Use back button to return here\n'
                    '5. Report any issues or feedback',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            
            const Spacer(),
            
            // Back to Profile
            TextButton(
              onPressed: () => context.go('/profile'),
              child: const Text(
                'Back to Profile',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
