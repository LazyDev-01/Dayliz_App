import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/address.dart';
import '../../providers/user_profile_providers.dart';
import '../../providers/auth_providers.dart';
import '../../widgets/common/unified_app_bar.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/skeleton_loaders.dart';
import '../../widgets/address/address_form_bottom_sheet.dart';
import 'location_picker_screen_v2.dart';

class CleanAddressListScreen extends ConsumerStatefulWidget {
  static const routeName = '/addresses';

  const CleanAddressListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CleanAddressListScreen> createState() => _CleanAddressListScreenState();
}

class _CleanAddressListScreenState extends ConsumerState<CleanAddressListScreen> {
  @override
  void initState() {
    super.initState();
    // Load user addresses when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAddresses();
    });
  }

  Future<void> _fetchAddresses() async {
    try {
      final user = ref.read(currentUserProvider);
      final userId = user?.id;
      if (userId == null) {
        debugPrint('Cannot fetch addresses: User ID is null');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be logged in to view addresses'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await ref.read(userProfileNotifierProvider.notifier).loadAddresses(userId);
    } catch (e, stack) {
      debugPrint('Error fetching addresses: $e\n$stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load addresses: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToAddAddress() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LocationPickerScreen(),
      ),
    );
  }

  void _navigateToEditAddress(Address address) {
    AddressFormBottomSheet.show(context, address: address);
  }

  Future<void> _deleteAddress(String addressId) async {
    // Show confirmation dialog before deleting
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address'),
        content: const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;

    if (!shouldDelete) return;

    // Show loading indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deleting address...'),
          duration: Duration(seconds: 1),
        ),
      );
    }

    try {
      final user = ref.read(currentUserProvider);
      final userId = user?.id;
      if (userId == null) {
        if (mounted) {
          // User not logged in - silently return for early launch
          debugPrint('User must be logged in to delete addresses');
        }
        return;
      }

      // Attempt to delete the address
      await ref.read(userProfileNotifierProvider.notifier).deleteAddress(userId, addressId);

      // If we get here, the deletion was successful
      if (mounted) {
        debugPrint('Address deleted successfully');
        // Success feedback disabled for early launch
      }
    } catch (e) {
      debugPrint('Error deleting address: $e');
      if (mounted) {
        String errorMessage = 'Error deleting address';

        // Check if the error is related to repository registration
        if (e.toString().contains('not registered') ||
            e.toString().contains('Address service not initialized')) {
          errorMessage = 'The address service is not available at this time. Please try again later.';

          // Try to refresh the provider
          final notifier = ref.refresh(userProfileNotifierProvider);
          debugPrint('Refreshed addressesNotifierProvider: ${notifier.hashCode}');
        } else if (e.toString().contains('Permission denied')) {
          errorMessage = 'Permission denied. You may need to log in again.';
        } else if (e.toString().contains('not found')) {
          errorMessage = 'Address not found. It may have been already deleted.';
          // Refresh the address list
          _fetchAddresses();
        } else if (e.toString().contains('used as a shipping address') ||
                   e.toString().contains('used as a billing address')) {
          errorMessage = 'This address cannot be deleted because it is used in one or more orders.';
        } else {
          errorMessage = 'Error deleting address: ${e.toString()}';
        }

        debugPrint('Error deleting address: $errorMessage');
        // Error notifications disabled for early launch
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(userProfileNotifierProvider);
    final addresses = profileState.addresses ?? [];

    return Scaffold(
      backgroundColor: Colors.grey[50], // Light grey background
      appBar: UnifiedAppBars.withBackButton(
        title: 'Manage Address',
        fallbackRoute: '/home',
      ),
      body: profileState.isAddressesLoading
        ? const ListSkeleton(
            itemSkeleton: AddressSkeleton(),
            itemCount: 3,
          )
        : profileState.addressErrorMessage != null
          ? ErrorState(
              message: profileState.addressErrorMessage!,
              onRetry: () async {
                final notifier = ref.refresh(userProfileNotifierProvider);
                debugPrint('Refreshed userProfileNotifierProvider: ${notifier.hashCode}');
                await _fetchAddresses();
              },
            )
          : _buildAddressContent(addresses),
    );
  }

  Widget _buildAddressContent(List<Address> addresses) {
    if (addresses.isEmpty) {
      return Column(
        children: [
          // Add New Address button at the top
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _navigateToAddAddress,
              icon: const Icon(Icons.add, color: Colors.green, size: 20),
              label: const Text(
                'Add New Address',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.green,
                elevation: 0, // Remove shadow
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          // Empty state
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_off,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Addresses',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You have no saved addresses yet.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchAddresses,
      child: Column(
        children: [
          // Add New Address button at the top
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _navigateToAddAddress,
              icon: const Icon(Icons.add, color: Colors.green, size: 20),
              label: const Text(
                'Add New Address',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.green,
                elevation: 0, // Remove shadow
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          // Address list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: addresses.length,
              itemBuilder: (context, index) {
                final address = addresses[index];
                return AddressCard(
                  address: address,
                  onEdit: () => _navigateToEditAddress(address),
                  onDelete: () => _deleteAddress(address.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AddressCard extends StatelessWidget {
  final Address address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AddressCard({
    Key? key,
    required this.address,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0, // Remove shadow
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  address.addressType == 'home'
                    ? Icons.home_outlined
                    : address.addressType == 'work'
                      ? Icons.work_outline
                      : Icons.place_outlined,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  address.addressType?.toUpperCase() ?? 'ADDRESS',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              address.country.toLowerCase(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            Text(
              '${address.addressLine1}, ${address.city}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (address.phoneNumber != null) ...[
              const SizedBox(height: 4),
              Text(
                'mobile : ${address.phoneNumber!}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ] else ...[
              const SizedBox(height: 4),
              Text(
                'mobile : NA',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: onEdit,
                  tooltip: 'Edit Address',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                  tooltip: 'Delete Address',
                  color: Theme.of(context).colorScheme.error,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}