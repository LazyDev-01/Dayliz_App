import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/user_profile_providers.dart';
import '../../providers/auth_providers.dart';
import '../../widgets/common/common_app_bar.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_state.dart';

/// Screen for managing user preferences
class PreferencesScreen extends ConsumerStatefulWidget {
  const PreferencesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends ConsumerState<PreferencesScreen> {
  bool _notificationsEnabled = true;
  bool _emailNotificationsEnabled = true;
  bool _pushNotificationsEnabled = true;
  bool _orderUpdatesEnabled = true;
  bool _promotionsEnabled = true;
  String _selectedLanguage = 'English';
  String _selectedTheme = 'Light';

  @override
  void initState() {
    super.initState();
    // Load user preferences
    _loadPreferences();
  }

  void _loadPreferences() {
    final userProfileState = ref.read(userProfileNotifierProvider);
    if (userProfileState.profile != null && userProfileState.profile!.preferences != null) {
      final preferences = userProfileState.profile!.preferences!;
      
      setState(() {
        _notificationsEnabled = preferences['notifications_enabled'] ?? true;
        _emailNotificationsEnabled = preferences['email_notifications_enabled'] ?? true;
        _pushNotificationsEnabled = preferences['push_notifications_enabled'] ?? true;
        _orderUpdatesEnabled = preferences['order_updates_enabled'] ?? true;
        _promotionsEnabled = preferences['promotions_enabled'] ?? true;
        _selectedLanguage = preferences['language'] ?? 'English';
        _selectedTheme = preferences['theme'] ?? 'Light';
      });
    }
  }

  Future<void> _savePreference(String key, dynamic value) async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;

    try {
      // Get current preferences
      final userProfileState = ref.read(userProfileNotifierProvider);
      final currentPreferences = userProfileState.profile?.preferences ?? {};

      // Update the specific preference
      final updatedPreferences = Map<String, dynamic>.from(currentPreferences);
      updatedPreferences[key] = value;
      updatedPreferences['last_updated'] = DateTime.now().toIso8601String();

      // Save to database
      await ref.read(userProfileNotifierProvider.notifier).updateUserPreferences(
        userId,
        updatedPreferences,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preference saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving preference: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfileState = ref.watch(userProfileNotifierProvider);

    return Scaffold(
      appBar: CommonAppBars.withBackButton(
        title: 'Preferences',
        centerTitle: true,
      ),
      body: userProfileState.isLoading
          ? const LoadingIndicator(message: 'Loading preferences...')
          : userProfileState.errorMessage != null
              ? ErrorState(
                  message: userProfileState.errorMessage!,
                  onRetry: _loadPreferences,
                )
              : _buildPreferencesContent(),
    );
  }

  Widget _buildPreferencesContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Notifications Section
          _buildSectionHeader('Notifications'),
          _buildNotificationsSection(),

          const SizedBox(height: 24),

          // Language & Theme Section
          _buildSectionHeader('Display'),
          _buildDisplaySection(),
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

  Widget _buildNotificationsSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Main notifications toggle
          SwitchListTile(
            title: const Text('Enable Notifications'),
            subtitle: const Text('Receive notifications from Dayliz'),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
              _savePreference('notifications_enabled', value);
            },
          ),

          // Email notifications
          SwitchListTile(
            title: const Text('Email Notifications'),
            subtitle: const Text('Receive notifications via email'),
            value: _emailNotificationsEnabled && _notificationsEnabled,
            onChanged: _notificationsEnabled
                ? (value) {
                    setState(() {
                      _emailNotificationsEnabled = value;
                    });
                    _savePreference('email_notifications_enabled', value);
                  }
                : null,
          ),

          // Push notifications
          SwitchListTile(
            title: const Text('Push Notifications'),
            subtitle: const Text('Receive notifications on your device'),
            value: _pushNotificationsEnabled && _notificationsEnabled,
            onChanged: _notificationsEnabled
                ? (value) {
                    setState(() {
                      _pushNotificationsEnabled = value;
                    });
                    _savePreference('push_notifications_enabled', value);
                  }
                : null,
          ),

          // Order updates
          SwitchListTile(
            title: const Text('Order Updates'),
            subtitle: const Text('Get notified about your order status'),
            value: _orderUpdatesEnabled && _notificationsEnabled,
            onChanged: _notificationsEnabled
                ? (value) {
                    setState(() {
                      _orderUpdatesEnabled = value;
                    });
                    _savePreference('order_updates_enabled', value);
                  }
                : null,
          ),

          // Promotions
          SwitchListTile(
            title: const Text('Promotions & Offers'),
            subtitle: const Text('Receive notifications about deals and offers'),
            value: _promotionsEnabled && _notificationsEnabled,
            onChanged: _notificationsEnabled
                ? (value) {
                    setState(() {
                      _promotionsEnabled = value;
                    });
                    _savePreference('promotions_enabled', value);
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDisplaySection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Language
          ListTile(
            title: const Text('Language'),
            subtitle: Text(_selectedLanguage),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showLanguageDialog,
          ),

          // Theme
          ListTile(
            title: const Text('Theme'),
            subtitle: Text(_selectedTheme),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showThemeDialog,
          ),
        ],
      ),
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
              });
              _savePreference('language', tempSelectedLanguage);
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
              });
              _savePreference('theme', tempSelectedTheme);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
