import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/address.dart';
import '../../providers/user_providers.dart';
import '../common/error_state.dart';
import '../common/loading_indicator.dart';
import '../common/empty_state.dart';

class CleanAddressSelectionWidget extends ConsumerWidget {
  final bool allowSelection;
  final bool showAddButton;
  final Function(Address)? onAddressSelected;

  const CleanAddressSelectionWidget({
    Key? key,
    this.allowSelection = true,
    this.showAddButton = true,
    this.onAddressSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesState = ref.watch(addressesNotifierProvider);
    final selectedAddressId = ref.watch(selectedAddressIdProvider);

    return addressesState.when(
      loading: () => const LoadingIndicator(),
      error: (error, stackTrace) => ErrorState(
        message: error.toString(),
        onRetry: () => ref.read(addressesNotifierProvider.notifier).refreshAddresses(),
      ),
      data: (addresses) {
        if (addresses.isEmpty) {
          return EmptyState(
            icon: Icons.location_off,
            title: 'No Addresses',
            message: 'You have no saved addresses yet.',
            buttonText: 'Add Address',
            onButtonPressed: () => _navigateToAddAddress(context),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: addresses.length,
              itemBuilder: (context, index) {
                final address = addresses[index];
                final isSelected = selectedAddressId == address.id;

                return _buildAddressCard(context, ref, address, isSelected);
              },
            ),

            if (showAddButton) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _navigateToAddAddress(context),
                icon: const Icon(Icons.add),
                label: const Text('Add New Address'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildAddressCard(BuildContext context, WidgetRef ref, Address address, bool isSelected) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isSelected ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: isSelected
          ? BorderSide(color: theme.colorScheme.primary, width: 2)
          : BorderSide.none,
      ),
      child: InkWell(
        onTap: allowSelection ? () => _selectAddress(ref, address) : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          address.recipientName ?? 'Recipient',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          address.phoneNumber ?? 'No phone number',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${address.addressLine1}, ${address.city}, ${address.state}',
                          style: theme.textTheme.bodyMedium,
                        ),
                        if (address.landmark != null && address.landmark!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Landmark: ${address.landmark}',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: theme.colorScheme.primary,
                    ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _navigateToEditAddress(context, address),
                    child: const Text('Edit'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => _confirmDeleteAddress(context, ref, address),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectAddress(WidgetRef ref, Address address) {
    ref.read(selectedAddressIdProvider.notifier).state = address.id;
    if (onAddressSelected != null) {
      onAddressSelected!(address);
    }
  }

  void _navigateToAddAddress(BuildContext context) {
    context.push('/address/add');
  }

  void _navigateToEditAddress(BuildContext context, Address address) {
    context.push('/address/edit/${address.id}');
  }

  Future<void> _confirmDeleteAddress(BuildContext context, WidgetRef ref, Address address) async {
    final result = await showDialog<bool>(
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
    );

    if (result == true) {
      // Store context for later use
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      // Show loading indicator
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Deleting address...'),
          duration: Duration(seconds: 1),
        ),
      );

      try {
        final userId = ref.read(currentUserIdProvider);
        if (userId == null) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('You must be logged in to delete addresses'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Attempt to delete the address
        await ref.read(addressesNotifierProvider.notifier).deleteAddress(userId, address.id);

        // If we get here, the deletion was successful
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Address deleted successfully'),
          ),
        );
      } catch (e) {
        debugPrint('Error deleting address: $e');
        String errorMessage = 'Error deleting address';

        // Check if the error is related to repository registration
        if (e.toString().contains('not registered') ||
            e.toString().contains('Address service not initialized')) {
          errorMessage = 'The address service is not available at this time. Please try again later.';

          // Try to refresh the provider
          final notifier = ref.refresh(addressesNotifierProvider);
          debugPrint('Refreshed addressesNotifierProvider: ${notifier.hashCode}');
        } else if (e.toString().contains('Permission denied')) {
          errorMessage = 'Permission denied. You may need to log in again.';
        } else if (e.toString().contains('not found')) {
          errorMessage = 'Address not found. It may have been already deleted.';
          // Refresh the addresses
          ref.read(addressesNotifierProvider.notifier).refreshAddresses();
        } else if (e.toString().contains('used as a shipping address') ||
                   e.toString().contains('used as a billing address')) {
          errorMessage = 'This address cannot be deleted because it is used in one or more orders.';
        } else {
          errorMessage = 'Error deleting address: ${e.toString()}';
        }

        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
