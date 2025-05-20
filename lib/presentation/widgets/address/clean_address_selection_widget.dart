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
                        Row(
                          children: [
                            Text(
                              address.recipientName ?? 'Recipient',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(width: 8),
                            if (address.isDefault)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Default',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
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
                  if (!address.isDefault)
                    TextButton(
                      onPressed: () => _confirmDeleteAddress(context, ref, address),
                      child: const Text('Delete'),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                      ),
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
            child: const Text('Delete'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      final userId = ref.read(currentUserIdProvider);
      if (userId != null) {
        await ref.read(addressesNotifierProvider.notifier).deleteAddress(userId, address.id);
      }
    }
  }
}
