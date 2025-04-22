import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dayliz_app/providers/auth_provider.dart';
import 'package:dayliz_app/providers/theme_provider.dart';
import 'package:dayliz_app/screens/home/address_list_screen.dart';
import 'package:dayliz_app/theme/app_theme.dart';
import 'package:dayliz_app/theme/app_spacing.dart';
import 'package:dayliz_app/widgets/buttons/dayliz_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeModeProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Navigate to edit profile
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Edit profile feature coming soon!'),
                ),
              );
            },
          ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: AppSpacing.paddingLG,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileHeader(context, user),
                    AppSpacing.vLG,
                    _buildSectionTitle(context, 'Account'),
                    _buildSettingsItem(
                      context,
                      icon: Icons.shopping_bag_outlined,
                      title: 'My Orders',
                      onTap: () {
                        // TODO: Navigate to orders
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Orders feature coming soon!'),
                          ),
                        );
                      },
                    ),
                    _buildSettingsItem(
                      context,
                      icon: Icons.location_on_outlined,
                      title: 'My Addresses',
                      onTap: () {
                        context.go('/addresses');
                      },
                    ),
                    _buildSettingsItem(
                      context,
                      icon: Icons.payment_outlined,
                      title: 'Payment Methods',
                      onTap: () {
                        // TODO: Navigate to payment methods
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Payment methods feature coming soon!'),
                          ),
                        );
                      },
                    ),
                    const Divider(),
                    _buildSectionTitle(context, 'Settings'),
                    _buildSettingsItem(
                      context,
                      icon: Icons.dark_mode_outlined,
                      title: 'Dark Mode',
                      trailing: Switch(
                        value: themeMode == ThemeMode.dark,
                        onChanged: (value) {
                          ref.read(themeModeProvider.notifier).toggleThemeMode();
                        },
                      ),
                      onTap: () {
                        ref.read(themeModeProvider.notifier).toggleThemeMode();
                      },
                    ),
                    _buildSettingsItem(
                      context,
                      icon: Icons.language_outlined,
                      title: 'Language',
                      value: 'English',
                      onTap: () {
                        // TODO: Navigate to language settings
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Language settings coming soon!'),
                          ),
                        );
                      },
                    ),
                    _buildSettingsItem(
                      context,
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      onTap: () {
                        // TODO: Navigate to notification settings
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Notification settings coming soon!'),
                          ),
                        );
                      },
                    ),
                    const Divider(),
                    _buildSectionTitle(context, 'Support'),
                    _buildSettingsItem(
                      context,
                      icon: Icons.help_outline,
                      title: 'Help Center',
                      onTap: () {
                        // TODO: Navigate to help center
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Help center coming soon!'),
                          ),
                        );
                      },
                    ),
                    _buildSettingsItem(
                      context,
                      icon: Icons.info_outline,
                      title: 'About Us',
                      onTap: () {
                        // TODO: Navigate to about us
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('About us coming soon!'),
                          ),
                        );
                      },
                    ),
                    const Divider(),
                    AppSpacing.vMD,
                    _buildLogoutButton(context, ref),
                    AppSpacing.vLG,
                    // Developer tools section - only visible in debug mode
                    if (kDebugMode) 
                      _buildSectionTitle(context, 'Developer Tools'),
                    if (kDebugMode)
                      _buildSettingsItem(
                        context,
                        icon: Icons.storage,
                        title: 'Database Seeder',
                        onTap: () {
                          context.go('/dev/database-seeder');
                        },
                      ),
                    if (kDebugMode)
                      _buildSettingsItem(
                        context,
                        icon: Icons.architecture,
                        title: 'Clean Architecture Demo',
                        subtitle: 'Test the new product feature implementation',
                        onTap: () {
                          context.push('/test/product-feature');
                        },
                      ),
                    if (kDebugMode)
                      const Divider(),
                    if (kDebugMode)
                      AppSpacing.vLG,
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, User user) {
    final theme = Theme.of(context);
    final metadata = user.userMetadata;
    final fullName = metadata?['full_name'] as String? ?? 'User';
    
    return Column(
      children: [
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  fullName.isNotEmpty ? fullName.substring(0, 1).toUpperCase() : 'U',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              AppSpacing.vMD,
              Text(
                fullName,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppSpacing.vXS,
              Text(
                user.email ?? '',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              if (user.phone != null) ...[
                AppSpacing.vXS,
                Text(
                  user.phone!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: AppSpacing.paddingVSM,
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? value,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    
    return ListTile(
      leading: Icon(
        icon,
        color: theme.colorScheme.primary,
      ),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing ?? (value != null
          ? Text(
              value,
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
              ),
            )
          : const Icon(Icons.chevron_right)),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: DaylizButton(
        label: 'Log Out',
        onPressed: () {
          _showLogoutDialog(context, ref);
        },
        leadingIcon: Icons.logout,
        type: DaylizButtonType.danger,
        size: DaylizButtonSize.large,
        isFullWidth: true,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Log Out', style: theme.textTheme.titleLarge),
        content: Text(
          'Are you sure you want to log out?',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('CANCEL', style: theme.textTheme.labelLarge),
          ),
          TextButton(
            onPressed: () {
              _logout(context, ref);
            },
            child: Text(
              'LOG OUT',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _logout(BuildContext context, WidgetRef ref) {
    Navigator.of(context).pop(); // Close dialog
    
    // Sign out using AuthNotifier
    ref.read(authNotifierProvider.notifier).signOut();
    
    // Navigation will be handled by the router's redirect
  }
} 