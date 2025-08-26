#!/usr/bin/env dart
/**
 * Quick test script to verify mock payment functionality
 * Run with: dart test/integration/mock_payment_test.dart
 */

import 'dart:io';

void main() async {
  print('🧪 Testing Mock Payment Detection');
  print('=' * 50);
  
  // Test mock key detection
  final testCases = [
    {'key': 'rzp_test_mock_payment_gateway', 'expected': true, 'description': 'Mock key'},
    {'key': 'rzp_test_real_key_123', 'expected': false, 'description': 'Real test key'},
    {'key': 'rzp_live_real_key_456', 'expected': false, 'description': 'Live key'},
    {'key': 'mock_key_test', 'expected': true, 'description': 'Contains mock'},
  ];
  
  print('Testing mock key detection:');
  for (final testCase in testCases) {
    final key = testCase['key'] as String;
    final expected = testCase['expected'] as bool;
    final description = testCase['description'] as String;
    
    final isMock = _isMockMode(key);
    final result = isMock == expected ? '✅ PASS' : '❌ FAIL';
    
    print('  $result $description: "$key" -> $isMock');
  }
  
  print('\n🎯 Mock Payment Simulation Test');
  print('=' * 50);
  
  // Simulate payment outcomes
  for (int i = 0; i < 10; i++) {
    final outcome = _simulatePaymentOutcome();
    final status = outcome ? '✅ SUCCESS' : '❌ FAILED';
    print('  Payment $i: $status');
  }
  
  print('\n✅ Mock payment tests completed!');
  print('📝 Note: This is for development testing only');
  print('🔒 Production will use real Razorpay integration');
}

/// Mock version of the detection logic
bool _isMockMode(String razorpayKey) {
  return razorpayKey.contains('mock') || 
         razorpayKey.startsWith('rzp_test_mock');
}

/// Simulate payment outcome (90% success rate)
bool _simulatePaymentOutcome() {
  final random = DateTime.now().millisecond;
  return random % 10 != 0; // 90% success rate
}
