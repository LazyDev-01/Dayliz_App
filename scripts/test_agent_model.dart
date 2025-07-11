// Run this from apps/agent directory: dart run ../../scripts/test_agent_model.dart
import 'dart:convert';
import 'package:shared_types/shared_types.dart';

/// Test script to verify AgentModel.fromJson works with our database data
void main() {
  // This is the exact data from our database
  final testData = {
    "id": "e4cc2d72-f1f9-4c5c-a1ab-173c031e73dc",
    "user_id": "08ad4a8f-a2e0-44bc-98e4-14c4e5d8830f",
    "agent_id": "DLZ-AG-GHY-00001",
    "full_name": "Test Agent",
    "phone": "+91-9876543210",
    "email": "test.agent@dayliz.com",
    "assigned_zone": "Guwahati Zone 1",
    "status": "active",
    "total_deliveries": 15,
    "total_earnings": "2500.00",
    "join_date": "2025-06-22 17:25:38.776362",
    "is_verified": true,
    "created_at": "2025-06-22 17:25:38.776362",
    "updated_at": "2025-06-23 11:53:35.240108"
  };

  try {
    print('Testing AgentModel.fromJson with database data...');
    final agent = AgentModel.fromJson(testData);
    print('✅ Success! AgentModel created:');
    print('  Agent ID: ${agent.agentId}');
    print('  Full Name: ${agent.fullName}');
    print('  Status: ${agent.status}');
    print('  Phone: ${agent.phone}');
    print('  Is Verified: ${agent.isVerified}');
  } catch (e) {
    print('❌ Error creating AgentModel: $e');
    print('Stack trace: ${StackTrace.current}');
  }
}
