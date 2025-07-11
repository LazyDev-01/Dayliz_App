import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_components/ui_components.dart';

/// Agent Profile Screen
/// Shows agent profile information, document status, and settings
class AgentProfileScreen extends StatefulWidget {
  /// Whether to show bottom navigation bar
  final bool showBottomNav;

  const AgentProfileScreen({
    super.key,
    this.showBottomNav = true,
  });

  @override
  State<AgentProfileScreen> createState() => _AgentProfileScreenState();
}

class _AgentProfileScreenState extends State<AgentProfileScreen> {
  // TODO: Replace with actual agent data from provider
  final Map<String, dynamic> agentData = {
    'full_name': 'John Doe',
    'agent_id': 'DLZ-AG-GHY-00001',
    'phone': '+91 9876543210',
    'email': 'john.doe@example.com',
    'assigned_zone': 'Guwahati Zone 1',
    'status': 'active',
    'join_date': '2024-01-01',
    'total_deliveries': 72,
    'total_earnings': 3200.0,
    'rating': 4.8,
  };

  final Map<String, dynamic> documentStatus = {
    'aadhaar': {'status': 'verified', 'uploaded_at': '2024-01-01'},
    'pan': {'status': 'verified', 'uploaded_at': '2024-01-01'},
    'driving_license': {'status': 'verified', 'uploaded_at': '2024-01-01'},
    'profile_photo': {'status': 'verified', 'uploaded_at': '2024-01-01'},
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editProfile,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            _buildProfileHeader(),
            
            const SizedBox(height: 20),
            
            // Quick Stats
            _buildQuickStats(),
            
            const SizedBox(height: 20),
            
            // Personal Information
            _buildPersonalInformation(),
            
            const SizedBox(height: 20),
            
            // Document Status
            _buildDocumentStatus(),
            
            const SizedBox(height: 20),
            
            // Settings & Actions
            _buildSettingsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
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
        children: [
          // Profile Picture
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: const Color(0xFF2E7D32).withOpacity(0.1),
                child: const Icon(
                  Icons.person,
                  size: 60,
                  color: Color(0xFF2E7D32),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(agentData['status']),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Name and Agent ID
          Text(
            agentData['full_name'],
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            agentData['agent_id'],
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(agentData['status']).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.circle,
                  color: _getStatusColor(agentData['status']),
                  size: 8,
                ),
                const SizedBox(width: 8),
                Text(
                  agentData['status'].toString().toUpperCase(),
                  style: TextStyle(
                    color: _getStatusColor(agentData['status']),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Deliveries',
            agentData['total_deliveries'].toString(),
            Icons.local_shipping,
            const Color(0xFF1976D2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Earnings',
            '₹${agentData['total_earnings'].toStringAsFixed(0)}',
            Icons.currency_rupee,
            const Color(0xFF388E3C),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Rating',
            agentData['rating'].toString(),
            Icons.star,
            const Color(0xFFF57C00),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInformation() {
    return _buildSection(
      title: 'Personal Information',
      icon: Icons.person,
      child: Column(
        children: [
          _buildInfoRow('Phone', agentData['phone']),
          const SizedBox(height: 12),
          _buildInfoRow('Email', agentData['email']),
          const SizedBox(height: 12),
          _buildInfoRow('Zone', agentData['assigned_zone']),
          const SizedBox(height: 12),
          _buildInfoRow('Join Date', agentData['join_date']),
        ],
      ),
    );
  }

  Widget _buildDocumentStatus() {
    return _buildSection(
      title: 'Document Status',
      icon: Icons.description,
      child: Column(
        children: documentStatus.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildDocumentRow(
              _getDocumentDisplayName(entry.key),
              entry.value['status'],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSettingsSection() {
    return _buildSection(
      title: 'Settings & Actions',
      icon: Icons.settings,
      child: Column(
        children: [
          _buildActionRow(
            'Change Password',
            Icons.lock,
            () => _changePassword(),
          ),
          const SizedBox(height: 12),
          _buildActionRow(
            'Notification Settings',
            Icons.notifications,
            () => _notificationSettings(),
          ),
          const SizedBox(height: 12),
          _buildActionRow(
            'Help & Support',
            Icons.help,
            () => _helpSupport(),
          ),
          const SizedBox(height: 12),
          _buildActionRow(
            'About',
            Icons.info,
            () => _about(),
          ),
          const SizedBox(height: 20),
          DaylizButton(
            text: 'Logout',
            onPressed: _logout,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            icon: Icons.logout,
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFF2E7D32),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentRow(String documentName, String status) {
    final statusColor = status == 'verified' ? const Color(0xFF388E3C) : const Color(0xFFF57C00);
    final statusIcon = status == 'verified' ? Icons.check_circle : Icons.schedule;
    
    return Row(
      children: [
        Icon(
          statusIcon,
          color: statusColor,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            documentName,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionRow(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.black54,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            color: Colors.black54,
            size: 16,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return const Color(0xFF388E3C);
      case 'inactive':
        return const Color(0xFFF57C00);
      case 'suspended':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getDocumentDisplayName(String key) {
    switch (key) {
      case 'aadhaar':
        return 'Aadhaar/Govt ID';
      case 'pan':
        return 'PAN Card';
      case 'driving_license':
        return 'Driving License';
      case 'profile_photo':
        return 'Profile Photo';
      default:
        return key;
    }
  }

  void _editProfile() {
    // TODO: Navigate to edit profile screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit Profile (Coming Soon)'),
        backgroundColor: Color(0xFF2E7D32),
      ),
    );
  }

  void _changePassword() {
    // TODO: Implement change password
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Change Password (Coming Soon)'),
        backgroundColor: Color(0xFF2E7D32),
      ),
    );
  }

  void _notificationSettings() {
    // TODO: Navigate to notification settings
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification Settings (Coming Soon)'),
        backgroundColor: Color(0xFF2E7D32),
      ),
    );
  }

  void _helpSupport() {
    // TODO: Navigate to help & support
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Help & Support (Coming Soon)'),
        backgroundColor: Color(0xFF2E7D32),
      ),
    );
  }

  void _about() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Dayliz Agent'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: 1.0.0'),
            SizedBox(height: 8),
            Text('Dayliz Agent App for delivery partners'),
            SizedBox(height: 8),
            Text('© 2024 Dayliz. All rights reserved.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/auth');
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
