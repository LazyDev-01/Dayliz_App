import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../providers/user_profile_providers.dart';
import '../../providers/auth_providers.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../domain/entities/user.dart' as domain;
import '../../../core/constants/app_colors.dart';
import '../../widgets/common/unified_app_bar.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_state.dart';

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

    // Reset any stuck loading state and load user profile data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureProfileLoaded();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _ensureProfileLoaded() {
    final authState = ref.read(authNotifierProvider);
    final profileState = ref.read(userProfileNotifierProvider);

    debugPrint('CleanUserProfileScreen: _ensureProfileLoaded called');
    debugPrint('CleanUserProfileScreen: Auth state - isAuthenticated: ${authState.isAuthenticated}, hasUser: ${authState.user != null}');
    debugPrint('CleanUserProfileScreen: Profile state - isLoading: ${profileState.isLoading}, hasProfile: ${profileState.profile != null}, hasError: ${profileState.errorMessage != null}');

    if (authState.isAuthenticated && authState.user != null) {
      // If stuck in loading state, reset it first
      if (profileState.isLoading && profileState.profile == null) {
        debugPrint('CleanUserProfileScreen: Resetting stuck loading state');
        ref.read(userProfileNotifierProvider.notifier).resetLoadingState();
      }

      // If no profile or error state, trigger load
      if (profileState.profile == null) {
        debugPrint('CleanUserProfileScreen: Loading user profile for user ID: ${authState.user!.id}');
        ref.read(userProfileNotifierProvider.notifier).loadUserProfile(authState.user!.id);
      } else {
        debugPrint('CleanUserProfileScreen: Profile already loaded');
      }
    } else {
      debugPrint('CleanUserProfileScreen: User not authenticated - Auth: ${authState.isAuthenticated}, User: ${authState.user?.id}');
    }
  }

  void _loadUserData() {
    _ensureProfileLoaded();
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
    // Only watch the auto-load provider once when the screen is first built
    // This prevents infinite rebuilds when other screens modify the profile state
    ref.read(autoLoadUserProfileProvider);

    final userProfileState = ref.watch(userProfileNotifierProvider);
    final currentUser = ref.watch(currentUserProvider);
    final authState = ref.watch(authNotifierProvider);

    // Removed debug logging to prevent log spam

    // Enhanced fallback: Always ensure profile is loaded when screen is accessed
    if (authState.isAuthenticated && authState.user != null) {
      // If no profile and not loading and no error, trigger load
      if (userProfileState.profile == null &&
          !userProfileState.isLoading &&
          userProfileState.errorMessage == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _loadUserData();
        });
      }
    }

    // If profile loaded, populate form fields
    if (userProfileState.profile != null) {
      _populateFormFields(userProfileState.profile!);
    }

    return Scaffold(
      backgroundColor: Colors.grey[50], // Light grey background color
      appBar: UnifiedAppBars.withBackButton(
        title: 'Profile',
        fallbackRoute: '/home',
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

  Widget _buildProfileContent(UserProfileState state, domain.User? currentUser) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Combined profile and quick actions section
            _buildCombinedProfileSection(state, currentUser),

            // Hidden user info section (maintains functionality)
            _buildUserInfoSection(state, currentUser),

            // Account and settings sections
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildCombinedProfileSection(UserProfileState state, domain.User? currentUser) {
    final primaryColor = Theme.of(context).primaryColor;
    final displayName = currentUser?.name ?? state.profile?.fullName ?? 'User';
    final email = currentUser?.email ?? 'No email';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Profile avatar section (reduced size)
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        primaryColor.withOpacity(0.7),
                        primaryColor.withOpacity(0.9),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // User info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 4),

                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider between profile and action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Divider(
              color: Colors.grey[300],
              thickness: 1,
              height: 24,
            ),
          ),

          // Quick action buttons
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
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

                // Gift Button
                _buildQuickActionButton(
                  icon: Icons.card_giftcard_outlined,
                  label: 'Gifts',
                  onTap: () {
                    // Navigate to gifts screen
                    final authState = ref.read(authNotifierProvider);
                    if (authState.isAuthenticated && authState.user != null) {
                      context.push('/coupons');
                    } else {
                      _showAuthRequiredDialog('Gifts & Offers');
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Keep the original method for backward compatibility
  Widget _buildProfileImageSection(UserProfileState state, dynamic currentUser) {
    final primaryColor = Theme.of(context).primaryColor;
    final displayName = currentUser?.name ?? state.profile?.fullName ?? 'User';
    final email = currentUser?.email ?? 'No email';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Profile image section
            GestureDetector(
              onTap: _pickAndUploadImage,
              child: Stack(
                children: [
                  // Profile image (reduced size)
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: primaryColor.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: state.profile?.profileImageUrl != null
                          ? Image.network(
                              state.profile!.profileImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.person,
                                    size: 24,
                                    color: Colors.white,
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.person,
                                size: 24,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),

                  // Camera icon
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.grey[200]!,
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        size: 14,
                        color: primaryColor,
                      ),
                    ),
                  ),

                  // Uploading indicator
                  if (state.isImageUploading)
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  if (state.isImageUploading)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoSection(UserProfileState state, domain.User? currentUser) {
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
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

            // Gift Button
            _buildQuickActionButton(
              icon: Icons.card_giftcard_outlined,
              label: 'Gifts',
              onTap: () {
                // Navigate to gifts screen
                final authState = ref.read(authNotifierProvider);
                if (authState.isAuthenticated && authState.user != null) {
                  context.push('/coupons');
                } else {
                  _showAuthRequiredDialog('Gifts & Offers');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final primaryColor = Theme.of(context).primaryColor;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon without container
              Icon(
                icon,
                color: primaryColor,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final primaryColor = Theme.of(context).primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [

        // Your Account Section
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0, left: 24.0, top: 8.0),
          child: Text(
            'Account',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ),

        // Account Section List
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Your Orders (renamed from My Orders)
              ListTile(
                leading: Icon(Icons.shopping_bag_outlined, color: primaryColor),
                title: const Text('Your Orders'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/orders'),
              ),

              Divider(height: 1, thickness: 1, color: Colors.grey.withOpacity(0.1)),

              // Address Book (renamed from My Addresses)
              ListTile(
                leading: Icon(Icons.location_on_outlined, color: primaryColor),
                title: const Text('Address Book'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/addresses'),
              ),

              Divider(height: 1, thickness: 1, color: Colors.grey.withOpacity(0.1)),

              // Your Wishlist
              ListTile(
                leading: Icon(Icons.favorite_border_outlined, color: primaryColor),
                title: const Text('Your Wishlist'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/wishlist'),
              ),

              Divider(height: 1, thickness: 1, color: Colors.grey.withOpacity(0.1)),

              // Payment Methods
              ListTile(
                leading: Icon(Icons.payment_outlined, color: primaryColor),
                title: const Text('Payment Methods'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  final authState = ref.read(authNotifierProvider);
                  if (authState.isAuthenticated && authState.user != null) {
                    context.push('/payment-methods');
                  } else {
                    _showAuthRequiredDialog('Payment Methods');
                  }
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Settings & Preferences Section
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0, left: 16.0, top: 16.0),
          child: Text(
            'Settings & Preferences',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ),

        // Settings Section List
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Notifications
              ListTile(
                leading: Icon(Icons.notifications_outlined, color: primaryColor),
                title: const Text('Notifications'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/preferences'),
              ),

              Divider(height: 1, thickness: 1, color: Colors.grey.withOpacity(0.1)),

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
                leading: Icon(Icons.privacy_tip_outlined, color: primaryColor),
                title: const Text('Privacy Policy'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showFeatureComingSoonDialog('Privacy Policy');
                },
              ),

              Divider(height: 1, thickness: 1, color: Colors.grey.withOpacity(0.1)),

              // About
              ListTile(
                leading: Icon(Icons.info_outline, color: primaryColor),
                title: const Text('About'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showAboutDialog(),
              ),

              Divider(height: 1, thickness: 1, color: Colors.grey.withOpacity(0.1)),

              // Debug Menu (for development)
              ListTile(
                leading: Icon(Icons.bug_report_outlined, color: primaryColor),
                title: const Text('Debug Menu'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/clean/debug'),
              ),

              Divider(height: 1, thickness: 1, color: Colors.grey.withOpacity(0.1)),

              // Delete Account - special styling for warning action
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Delete Account',
                  style: TextStyle(
                    color: Colors.red,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.red),
                onTap: () => _showDeleteAccountDialog(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Sign Out
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: ElevatedButton(
            onPressed: _signOut,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.white,
              foregroundColor: Colors.red,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.red.withOpacity(0.5), width: 1.5),
              ),
              shadowColor: Colors.transparent,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.logout, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Sign Out',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
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

  Future<void> _pickAndUploadImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final authState = ref.read(authNotifierProvider);
        if (authState.isAuthenticated && authState.user != null) {
          // Pass the path as a String instead of a File object
          await ref.read(userProfileNotifierProvider.notifier).uploadProfileImage(
            authState.user!.id,
            pickedFile.path,
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking/uploading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
    }
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
      applicationLegalese: '© 2025 Dayliz App',
      children: [
        const SizedBox(height: 16),
        const Text(
          'Dayliz is a q-commerce grocery delivery application with a zone-based delivery system.',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _showAuthRequiredDialog(String featureName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Authentication Required'),
        content: Text('Please log in to access $featureName.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/login');
            },
            child: const Text('Log In'),
          ),
        ],
      ),
    );
  }
}