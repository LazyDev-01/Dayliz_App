import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../providers/user_profile_providers.dart';
import '../../providers/auth_providers.dart';
import '../../../domain/entities/user_profile.dart';
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
  late TextEditingController _displayNameController;
  late TextEditingController _bioController;
  String? _selectedGender;
  DateTime? _selectedDate;
  File? _profileImage;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _displayNameController = TextEditingController();
    _bioController = TextEditingController();
    
    // Initialize auto-load provider (registers listener)
    ref.read(autoLoadUserProfileProvider);
    
    // Load user profile data
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final authState = ref.read(authStateProvider);
    if (authState.isAuthenticated && authState.user != null) {
      // Load user profile
      ref.read(userProfileNotifierProvider.notifier).loadUserProfile(authState.user!.id);
    }
  }

  void _populateFormFields(UserProfile profile) {
    _nameController.text = profile.fullName ?? '';
    _displayNameController.text = profile.displayName ?? '';
    _bioController.text = profile.bio ?? '';
    _selectedGender = profile.gender;
    _selectedDate = profile.dateOfBirth;
  }

  @override
  Widget build(BuildContext context) {
    final userProfileState = ref.watch(userProfileNotifierProvider);
    final currentUser = ref.watch(currentUserProvider);
    
    // If profile loaded, populate form fields
    if (userProfileState.profile != null && !_isEditing) {
      _populateFormFields(userProfileState.profile!);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveProfile,
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
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile image section
            _buildProfileImageSection(state),
            
            const SizedBox(height: 24),
            
            // User info section
            _buildUserInfoSection(state, currentUser),
            
            const SizedBox(height: 32),
            
            // Action buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImageSection(UserProfileState state) {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              // Profile image
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).primaryColor,
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: _profileImage != null
                      ? Image.file(
                          _profileImage!,
                          fit: BoxFit.cover,
                        )
                      : state.profile?.profileImageUrl != null
                          ? Image.network(
                              state.profile!.profileImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.person,
                                  size: 80,
                                  color: Colors.grey,
                                );
                              },
                            )
                          : const Icon(
                              Icons.person,
                              size: 80,
                              color: Colors.grey,
                            ),
                ),
              ),
              
              // Edit button
              if (_isEditing)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: _selectProfileImage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          
          if (state.isImageUploading)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Uploading...',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserInfoSection(UserProfileState state, dynamic currentUser) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Email (non-editable)
        if (currentUser != null)
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('Email'),
            subtitle: Text(currentUser.email),
          ),
        
        const SizedBox(height: 16),
        
        // Full Name
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person_outline),
          ),
          enabled: _isEditing,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your name';
            }
            return null;
          },
        ),
        
        const SizedBox(height: 16),
        
        // Display Name
        TextFormField(
          controller: _displayNameController,
          decoration: const InputDecoration(
            labelText: 'Display Name',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.badge_outlined),
          ),
          enabled: _isEditing,
        ),
        
        const SizedBox(height: 16),
        
        // Bio
        TextFormField(
          controller: _bioController,
          decoration: const InputDecoration(
            labelText: 'Bio',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.info_outline),
          ),
          maxLines: 3,
          enabled: _isEditing,
        ),
        
        const SizedBox(height: 16),
        
        // Gender
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
          onChanged: _isEditing
              ? (value) {
                  setState(() {
                    _selectedGender = value;
                  });
                }
              : null,
        ),
        
            const SizedBox(height: 16),
        
        // Date of Birth
        GestureDetector(
          onTap: _isEditing ? _selectDate : null,
          child: AbsorbPointer(
            child: TextFormField(
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
              enabled: _isEditing,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Manage Addresses
            ElevatedButton.icon(
              onPressed: () => context.push('/clean/addresses'),
              icon: const Icon(Icons.location_on_outlined),
              label: const Text('Manage Addresses'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // My Wishlist
        ElevatedButton.icon(
          onPressed: () => context.push('/clean-wishlist'),
          icon: const Icon(Icons.favorite_border),
          label: const Text('My Wishlist'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // View Orders
        ElevatedButton.icon(
          onPressed: () => context.push('/clean/orders'),
          icon: const Icon(Icons.shopping_bag_outlined),
          label: const Text('View Orders'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Edit Preferences
        ElevatedButton.icon(
          onPressed: () => context.push('/clean/preferences'),
          icon: const Icon(Icons.settings_outlined),
          label: const Text('Edit Preferences'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Sign Out
        if (!_isEditing)
          OutlinedButton.icon(
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
            label: const Text('Sign Out'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        
        // Cancel Edit
        if (_isEditing)
          OutlinedButton(
            onPressed: () {
              setState(() {
                _isEditing = false;
                _profileImage = null;
                
                // Reset form fields
                if (ref.read(userProfileNotifierProvider).profile != null) {
                  _populateFormFields(ref.read(userProfileNotifierProvider).profile!);
                }
              });
            },
            child: const Text('Cancel'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
      ],
    );
  }

  Future<void> _selectProfileImage() async {
    final imagePicker = ImagePicker();
    final pickedImage = await imagePicker.pickImage(source: ImageSource.gallery);
    
    if (pickedImage != null) {
      setState(() {
        _profileImage = File(pickedImage.path);
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final authState = ref.read(authStateProvider);
      if (authState.user == null) return;
      
      final userId = authState.user!.id;
      final currentProfile = ref.read(userProfileNotifierProvider).profile;
      
      if (currentProfile == null) return;
      
      // First, upload profile image if selected
      if (_profileImage != null) {
        await ref.read(userProfileNotifierProvider.notifier).uploadProfileImage(
          userId,
          _profileImage!.path,
        );
      }
      
      // Then update profile data
      final updatedProfile = currentProfile.copyWith(
        fullName: _nameController.text,
        displayName: _displayNameController.text.isNotEmpty 
            ? _displayNameController.text 
            : null,
        bio: _bioController.text.isNotEmpty 
            ? _bioController.text 
            : null,
        gender: _selectedGender,
        dateOfBirth: _selectedDate,
        lastUpdated: DateTime.now(),
      );
      
      await ref.read(userProfileNotifierProvider.notifier).updateProfile(updatedProfile);
      
      if (mounted) {
        setState(() {
          _isEditing = false;
          _profileImage = null;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    }
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
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authNotifierProvider.notifier).logout();
              if (mounted) {
                context.go('/clean/login');
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
} 