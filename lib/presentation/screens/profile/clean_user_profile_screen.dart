import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/user_profile_providers.dart';
import '../../providers/auth_providers.dart';
import '../../../domain/entities/user_profile.dart';
import '../../widgets/common/common_app_bar.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_state.dart';

/// A Clean Architecture implementation of the user profile screen
/// This is currently a placeholder for future implementation
class CleanUserProfileScreen extends ConsumerStatefulWidget {
  const CleanUserProfileScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CleanUserProfileScreen> createState() => _CleanUserProfileScreenState();
}

class _CleanUserProfileScreenState extends ConsumerState<CleanUserProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  String? _selectedGender;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();

    // Initialize auto-load provider (registers listener)
    ref.read(autoLoadUserProfileProvider);

    // Load user profile data
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final authState = ref.read(authStateProvider);
    if (authState.isAuthenticated && authState.user != null) {
      // Load user profile
      debugPrint('Loading user profile for user ID: ${authState.user!.id}');
      ref.read(userProfileNotifierProvider.notifier).loadUserProfile(authState.user!.id);
    }
  }

  void _populateFormFields(UserProfile profile) {
    final currentUser = ref.read(currentUserProvider);

    debugPrint('Populating form fields with profile data:');
    debugPrint('Profile object: $profile');
    debugPrint('Profile runtimeType: ${profile.runtimeType}');
    debugPrint('Full Name from profile: ${profile.fullName}');
    debugPrint('Name from currentUser: ${currentUser?.name}');
    debugPrint('Gender: ${profile.gender}');
    debugPrint('Date of Birth: ${profile.dateOfBirth}');

    // Use name from currentUser if available, otherwise use profile.fullName
    _nameController.text = currentUser?.name ?? profile.fullName ?? '';
    _selectedGender = profile.gender;
    _selectedDate = profile.dateOfBirth;
  }

  @override
  Widget build(BuildContext context) {
    final userProfileState = ref.watch(userProfileNotifierProvider);
    final currentUser = ref.watch(currentUserProvider);

    // If profile loaded, populate form fields
    if (userProfileState.profile != null) {
      _populateFormFields(userProfileState.profile!);
    }

    return Scaffold(
      appBar: CommonAppBars.withBackButton(
        title: 'Profile',
        centerTitle: true,
        fallbackRoute: '/home',
        backButtonTooltip: 'Back to Home',
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // TODO: Navigate to settings
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings coming soon')),
              );
            },
          ),
        ],
      ),
      body: userProfileState.isLoading
          ? const LoadingIndicator(message: 'Loading profile...')
          : userProfileState.errorMessage != null
              ? ErrorState(
                  message: userProfileState.errorMessage!,
                  onRetry: _loadUserData,
                )
              : _buildProfileContent(userProfileState, currentUser),
    );
  }

  Widget _buildProfileContent(UserProfileState state, dynamic currentUser) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile image and user info section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildProfileImageSection(state, currentUser),
            ),

            // Space after the profile section
            const SizedBox(height: 16),

            // Hidden user info section (maintains functionality)
            _buildUserInfoSection(state, currentUser),

            // Action buttons - no extra padding needed as it's handled within the method
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImageSection(UserProfileState state, dynamic currentUser) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Profile image (smaller and on the left)
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).primaryColor,
              width: 2,
            ),
          ),
          child: ClipOval(
            child: state.profile?.profileImageUrl != null
                ? Image.network(
                    state.profile!.profileImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.person,
                        size: 36,
                        color: Colors.grey,
                      );
                    },
                  )
                : const Icon(
                    Icons.person,
                    size: 36,
                    color: Colors.grey,
                  ),
          ),
        ),

        const SizedBox(width: 16),

        // User info next to the profile image
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Full Name
              Builder(
                builder: (context) {
                  // Debug the values
                  debugPrint('Building name text with:');
                  debugPrint('Controller text: "${_nameController.text}"');
                  debugPrint('Profile fullName: "${state.profile?.fullName}"');
                  debugPrint('Current user name: "${currentUser?.name}"');

                  // First try to use the name from currentUser, then fall back to profile's fullName
                  final displayName = currentUser?.name ?? state.profile?.fullName ?? 'User';
                  return Text(
                    displayName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  );
                },
              ),

              const SizedBox(height: 4),

              // Email
              Text(
                currentUser?.email ?? 'No email',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        if (state.isImageUploading)
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 4),
                Text(
                  'Uploading...',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildUserInfoSection(UserProfileState state, dynamic currentUser) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // Hidden fields - these are not visible but still functional
        // Full Name - hidden but still functional
        Visibility(
          visible: false, // Hide this field
          maintainState: true, // Keep the state to maintain functionality
          maintainAnimation: true,
          maintainSize: false,
          maintainInteractivity: false,
          child: Column(
            children: [
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                enabled: false,
              ),
            ],
          ),
        ),

        // Gender - hidden but still functional
        Visibility(
          visible: false, // Hide this field
          maintainState: true, // Keep the state to maintain functionality
          maintainAnimation: true,
          maintainSize: false,
          maintainInteractivity: false,
          child: Column(
            children: [
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.people_outline),
                ),
                value: _selectedGender,
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Male')),
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                  DropdownMenuItem(value: 'prefer_not_to_say', child: Text('Prefer not to say')),
                ],
                onChanged: null,
              ),
            ],
          ),
        ),

        // Date of Birth - hidden but still functional
        Visibility(
          visible: false, // Hide this field
          maintainState: true, // Keep the state to maintain functionality
          maintainAnimation: true,
          maintainSize: false,
          maintainInteractivity: false,
          child: Column(
            children: [
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Date of Birth',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                controller: TextEditingController(
                  text: _selectedDate != null
                      ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                      : '',
                ),
                enabled: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Wallet Button
          _buildQuickActionButton(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Wallet',
            onTap: () {
              _showFeatureComingSoonDialog('Wallet');
            },
          ),

          // Support Button
          _buildQuickActionButton(
            icon: Icons.chat_outlined,
            label: 'Support',
            onTap: () {
              _showFeatureComingSoonDialog('Support');
            },
          ),

          // Wishlist Button
          _buildQuickActionButton(
            icon: Icons.favorite_border_outlined,
            label: 'Wishlist',
            onTap: () {
              _showFeatureComingSoonDialog('Wishlist');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final primaryColor = Theme.of(context).primaryColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 70,
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final primaryColor = Theme.of(context).primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Quick Action Buttons
        _buildQuickActionButtons(),

        // Your Account Section
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0, left: 16.0, top: 8.0),
          child: Text(
            'Account',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Account Section List
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 0),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // My Orders
              ListTile(
                onTap: () => context.push('/orders'),
                leading: Icon(Icons.shopping_bag_outlined, color: primaryColor),
                title: const Text('My Orders'),
                trailing: const Icon(Icons.chevron_right),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
              ),

              // My Addresses
              ListTile(
                onTap: () => context.push('/addresses'),
                leading: Icon(Icons.location_on_outlined, color: primaryColor),
                title: const Text('My Addresses'),
                trailing: const Icon(Icons.chevron_right),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
              ),

              // Payment Methods
              ListTile(
                onTap: () => context.push('/payment-methods'),
                leading: Icon(Icons.payment_outlined, color: primaryColor),
                title: const Text('Payment Methods'),
                trailing: const Icon(Icons.chevron_right),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Settings & Preferences Section
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0, left: 16.0, top: 8.0),
          child: Text(
            'Settings & Preferences',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Settings Section List
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 0),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Notifications
              ListTile(
                onTap: () => context.push('/preferences'),
                leading: Icon(Icons.notifications_outlined, color: primaryColor),
                title: const Text('Notifications'),
                trailing: const Icon(Icons.chevron_right),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
              ),

              // Hidden Language and Theme items - functionality maintained
              Visibility(
                visible: false,
                maintainState: true,
                child: Column(
                  children: [
                    // Language
                    ListTile(
                      onTap: () => _showLanguageDialog(),
                      leading: Icon(Icons.language_outlined, color: primaryColor),
                      title: const Text('Language'),
                      trailing: const Icon(Icons.chevron_right),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
                    ),

                    // Theme
                    ListTile(
                      onTap: () => _showThemeDialog(),
                      leading: Icon(Icons.palette_outlined, color: primaryColor),
                      title: const Text('Theme'),
                      trailing: const Icon(Icons.chevron_right),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
                    ),
                  ],
                ),
              ),

              // Privacy Policy
              ListTile(
                onTap: () {
                  _showFeatureComingSoonDialog('Privacy Policy');
                },
                leading: Icon(Icons.privacy_tip_outlined, color: primaryColor),
                title: const Text('Privacy Policy'),
                trailing: const Icon(Icons.chevron_right),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
              ),

              // About
              ListTile(
                onTap: () => _showAboutDialog(),
                leading: Icon(Icons.info_outline, color: primaryColor),
                title: const Text('About'),
                trailing: const Icon(Icons.chevron_right),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
              ),

              // Debug Menu (for development)
              ListTile(
                onTap: () => context.push('/clean/debug'),
                leading: Icon(Icons.bug_report_outlined, color: primaryColor),
                title: const Text('Debug Menu'),
                trailing: const Icon(Icons.chevron_right),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
              ),

              // Delete Account
              ListTile(
                onTap: () => _showDeleteAccountDialog(),
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
                trailing: const Icon(Icons.chevron_right, color: Colors.red),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Sign Out
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: TextButton.icon(
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
            label: const Text('Sign Out'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              alignment: Alignment.center,
              foregroundColor: Colors.red,
            ),
          ),
        ),
      ],
    );
  }



  void _signOut() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleSignOut();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSignOut() async {
    await ref.read(authNotifierProvider.notifier).logout();
    if (mounted) {
      // Use a separate method to navigate after async operation
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    context.go('/login');
  }

  void _showLanguageDialog() {
    final userProfileState = ref.read(userProfileNotifierProvider);
    final preferences = userProfileState.profile?.preferences;
    String selectedLanguage = preferences?['language'] ?? 'English';

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
                    groupValue: selectedLanguage,
                    onChanged: (value) {
                      setState(() => selectedLanguage = value!);
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Spanish'),
                    value: 'Spanish',
                    groupValue: selectedLanguage,
                    onChanged: (value) {
                      setState(() => selectedLanguage = value!);
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('French'),
                    value: 'French',
                    groupValue: selectedLanguage,
                    onChanged: (value) {
                      setState(() => selectedLanguage = value!);
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('German'),
                    value: 'German',
                    groupValue: selectedLanguage,
                    onChanged: (value) {
                      setState(() => selectedLanguage = value!);
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Arabic'),
                    value: 'Arabic',
                    groupValue: selectedLanguage,
                    onChanged: (value) {
                      setState(() => selectedLanguage = value!);
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
              _savePreference('language', selectedLanguage);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog() {
    final userProfileState = ref.read(userProfileNotifierProvider);
    final preferences = userProfileState.profile?.preferences;
    String selectedTheme = preferences?['theme'] ?? 'Light';

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
                    title: const Text('System Default'),
                    value: 'System Default',
                    groupValue: selectedTheme,
                    onChanged: (value) {
                      setState(() => selectedTheme = value!);
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Light'),
                    value: 'Light',
                    groupValue: selectedTheme,
                    onChanged: (value) {
                      setState(() => selectedTheme = value!);
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Dark'),
                    value: 'Dark',
                    groupValue: selectedTheme,
                    onChanged: (value) {
                      setState(() => selectedTheme = value!);
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
              _savePreference('theme', selectedTheme);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
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

  void _showFeatureComingSoonDialog(String featureName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$featureName Coming Soon'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.construction,
              size: 64,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'The $featureName feature is currently under development and will be available soon.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Dayliz App',
      applicationVersion: '1.0.0',
      applicationIcon: Image.asset(
        'assets/images/logo.png',
        width: 48,
        height: 48,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'Dayliz',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          );
        },
      ),
      applicationLegalese: '© 2023 Dayliz App',
      children: [
        const SizedBox(height: 16),
        const Text(
          'Dayliz is a q-commerce grocery delivery application with a zone-based delivery system.',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}