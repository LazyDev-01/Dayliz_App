import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/user_profile_providers.dart';
import '../../providers/auth_providers.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_state.dart';
import '../../widgets/common/common_app_bar.dart';

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
  String _selectedTheme = 'Light';
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
        _selectedTheme = preferences['theme'] ?? 'Light';
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
      appBar: CommonAppBars.withBackButton(
        title: 'Preferences',
        fallbackRoute: '/profile',
        backButtonTooltip: 'Back to Profile',
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Notifications Section
          _buildSectionHeader('Notifications'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 0),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
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
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Display Section
          _buildSectionHeader('Display'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 0),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                ListTile(
                  title: const Text('Language'),
                  subtitle: Text(_selectedLanguage),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showLanguageDialog,
                ),
                ListTile(
                  title: const Text('Theme'),
                  subtitle: Text(_selectedTheme),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showThemeDialog,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
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

  void _showLanguageDialog() {
    String tempSelectedLanguage = _selectedLanguage;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: const Text('English'),
                    value: 'English',
                    groupValue: tempSelectedLanguage,
                    onChanged: (value) {
                      setState(() => tempSelectedLanguage = value!);
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Spanish'),
                    value: 'Spanish',
                    groupValue: tempSelectedLanguage,
                    onChanged: (value) {
                      setState(() => tempSelectedLanguage = value!);
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('French'),
                    value: 'French',
                    groupValue: tempSelectedLanguage,
                    onChanged: (value) {
                      setState(() => tempSelectedLanguage = value!);
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Arabic'),
                    value: 'Arabic',
                    groupValue: tempSelectedLanguage,
                    onChanged: (value) {
                      setState(() => tempSelectedLanguage = value!);
                    },
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _selectedLanguage = tempSelectedLanguage;
                _changesMade();
              });
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog() {
    String tempSelectedTheme = _selectedTheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: const Text('Light'),
                    value: 'Light',
                    groupValue: tempSelectedTheme,
                    onChanged: (value) {
                      setState(() => tempSelectedTheme = value!);
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Dark'),
                    value: 'Dark',
                    groupValue: tempSelectedTheme,
                    onChanged: (value) {
                      setState(() => tempSelectedTheme = value!);
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('System Default'),
                    value: 'System Default',
                    groupValue: tempSelectedTheme,
                    onChanged: (value) {
                      setState(() => tempSelectedTheme = value!);
                    },
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _selectedTheme = tempSelectedTheme;
                _changesMade();
              });
            },
            child: const Text('Save'),
          ),
        ],
      ),
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


}