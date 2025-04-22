import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/user_profile_providers.dart';
import '../../providers/auth_providers.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_state.dart';

/// A Clean Architecture implementation of the user preferences screen
class CleanPreferencesScreen extends ConsumerStatefulWidget {
  const CleanPreferencesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CleanPreferencesScreen> createState() => _CleanPreferencesScreenState();
}

class _CleanPreferencesScreenState extends ConsumerState<CleanPreferencesScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _orderUpdates = true;
  bool _promotionalNotifications = false;
  String _selectedLanguage = 'English';
  String _selectedTheme = 'System Default';
  bool _saveChangesEnabled = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Load preferences when screen initializes
    _loadUserPreferences();
  }

  void _loadUserPreferences() {
    final profile = ref.read(userProfileNotifierProvider).profile;
    if (profile?.preferences != null) {
      final preferences = profile!.preferences!;
      
      setState(() {
        _pushNotifications = preferences['push_notifications'] ?? true;
        _emailNotifications = preferences['email_notifications'] ?? true;
        _orderUpdates = preferences['order_updates'] ?? true;
        _promotionalNotifications = preferences['promotional_notifications'] ?? false;
        _selectedLanguage = preferences['language'] ?? 'English';
        _selectedTheme = preferences['theme'] ?? 'System Default';
      });
    }
  }

  void _changesMade() {
    setState(() {
      _saveChangesEnabled = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProfileState = ref.watch(userProfileNotifierProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preferences'),
      ),
      body: userProfileState.isLoading || _isLoading
          ? const LoadingIndicator(message: 'Loading preferences...')
          : userProfileState.errorMessage != null
              ? ErrorState(
                  message: userProfileState.errorMessage!,
                  onRetry: _loadUserPreferences,
                )
              : _buildPreferencesContent(userProfileState),
      bottomNavigationBar: _saveChangesEnabled
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _savePreferences,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Save Changes'),
              ),
            )
          : null,
    );
  }

  Widget _buildPreferencesContent(UserProfileState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Notifications'),
          _buildSwitchTile(
            title: 'Push Notifications',
            subtitle: 'Receive push notifications for important updates',
            value: _pushNotifications,
            onChanged: (value) {
              setState(() {
                _pushNotifications = value;
                _changesMade();
              });
            },
          ),
          _buildSwitchTile(
            title: 'Email Notifications',
            subtitle: 'Receive email notifications for account updates',
            value: _emailNotifications,
            onChanged: (value) {
              setState(() {
                _emailNotifications = value;
                _changesMade();
              });
            },
          ),
          _buildSwitchTile(
            title: 'Order Updates',
            subtitle: 'Get notified about status changes to your orders',
            value: _orderUpdates,
            onChanged: (value) {
              setState(() {
                _orderUpdates = value;
                _changesMade();
              });
            },
          ),
          _buildSwitchTile(
            title: 'Promotional Notifications',
            subtitle: 'Receive notifications about deals and offers',
            value: _promotionalNotifications,
            onChanged: (value) {
              setState(() {
                _promotionalNotifications = value;
                _changesMade();
              });
            },
          ),
          const Divider(),
          _buildSectionHeader('App Settings'),
          _buildDropdownTile(
            title: 'Language',
            value: _selectedLanguage,
            items: const ['English', 'Spanish', 'French', 'German', 'Arabic'],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedLanguage = value;
                  _changesMade();
                });
              }
            },
          ),
          _buildDropdownTile(
            title: 'Theme',
            value: _selectedTheme,
            items: const ['System Default', 'Light', 'Dark'],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedTheme = value;
                  _changesMade();
                });
              }
            },
          ),
          const Divider(),
          _buildSectionHeader('Privacy'),
          _buildPrivacyOptions(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).primaryColor,
      ),
      onTap: () {
        onChanged(!value);
      },
    );
  }

  Widget _buildDropdownTile({
    required String title,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return ListTile(
      title: Text(title),
      trailing: DropdownButton<String>(
        value: value,
        onChanged: onChanged,
        underline: const SizedBox(),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildPrivacyOptions() {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: const Text('Privacy Policy'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // Navigate to privacy policy
          },
        ),
        ListTile(
          leading: const Icon(Icons.security_outlined),
          title: const Text('Data Usage'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // Navigate to data usage
          },
        ),
        ListTile(
          leading: const Icon(Icons.delete_outline),
          title: const Text('Delete Account'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            _showDeleteAccountDialog();
          },
        ),
      ],
    );
  }

  Future<void> _savePreferences() async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Create preferences map
      final preferences = {
        'push_notifications': _pushNotifications,
        'email_notifications': _emailNotifications,
        'order_updates': _orderUpdates,
        'promotional_notifications': _promotionalNotifications,
        'language': _selectedLanguage,
        'theme': _selectedTheme,
        'last_updated': DateTime.now().toIso8601String(),
      };

      // Update preferences using the provider
      await ref.read(userProfileNotifierProvider.notifier).updateUserPreferences(
            userId,
            preferences,
          );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _saveChangesEnabled = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preferences saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving preferences: ${e.toString()}')),
        );
      }
    }
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement account deletion
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion is not implemented yet'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
} 