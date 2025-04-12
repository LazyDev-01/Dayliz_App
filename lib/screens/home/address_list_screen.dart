import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dayliz_app/models/address.dart';
import 'package:dayliz_app/theme/app_spacing.dart';
import 'package:dayliz_app/theme/app_theme.dart';
import 'package:dayliz_app/widgets/buttons/dayliz_button.dart';

// Temporary provider for addresses - to be replaced with actual address repository
final addressesProvider = StateProvider<List<Address>>((ref) {
  return [
    Address(
      id: '1',
      name: 'John Doe',
      street: '123 Main Street, Apartment 4B',
      city: 'Mumbai',
      state: 'Maharashtra',
      postalCode: '400001',
      country: 'India',
      phone: '+91 9876543210',
      isDefault: true,
    ),
    Address(
      id: '2',
      name: 'John Doe',
      street: '456 Park Avenue',
      city: 'Bangalore',
      state: 'Karnataka',
      postalCode: '560001',
      country: 'India',
      phone: '+91 9876543210',
      additionalInfo: 'Near Central Park',
    ),
  ];
});

class AddressListScreen extends ConsumerWidget {
  final bool isSelectable;

  const AddressListScreen({
    Key? key,
    this.isSelectable = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addresses = ref.watch(addressesProvider);
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Addresses'),
      ),
      body: addresses.isEmpty
          ? _buildEmptyState(context)
          : ListView.separated(
              padding: AppSpacing.paddingMD,
              itemCount: addresses.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final address = addresses[index];
                return _buildAddressItem(
                  context,
                  ref,
                  address,
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddAddress(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off,
            size: 80,
            color: theme.colorScheme.primary.withOpacity(0.5),
          ),
          AppSpacing.vMD,
          Text(
            'No addresses found',
            style: theme.textTheme.titleLarge,
          ),
          AppSpacing.vSM,
          Padding(
            padding: AppSpacing.paddingHLG,
            child: Text(
              'You haven\'t added any addresses yet. Add a new address to get started.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ),
          AppSpacing.vLG,
          DaylizButton(
            label: 'Add New Address',
            onPressed: () => _navigateToAddAddress(context, null),
            leadingIcon: Icons.add,
            type: DaylizButtonType.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressItem(
    BuildContext context,
    WidgetRef ref,
    Address address,
  ) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: isSelectable
          ? () => Navigator.of(context).pop(address)
          : null,
      child: Padding(
        padding: AppSpacing.paddingVSM,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on),
                AppSpacing.hSM,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            address.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (address.isDefault) ...[
                            AppSpacing.hSM,
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Default',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      AppSpacing.vXS,
                      Text(
                        address.phone ?? '',
                        style: theme.textTheme.bodyMedium,
                      ),
                      AppSpacing.vXS,
                      Text(
                        address.formattedAddress,
                        style: theme.textTheme.bodyMedium,
                      ),
                      if (address.additionalInfo != null) ...[
                        AppSpacing.vXS,
                        Text(
                          address.additionalInfo!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            AppSpacing.vMD,
            if (!isSelectable)
              Row(
                children: [
                  Expanded(
                    child: DaylizButton(
                      label: 'Edit',
                      onPressed: () => _navigateToEditAddress(context, ref, address),
                      leadingIcon: Icons.edit_outlined,
                      type: DaylizButtonType.secondary,
                      size: DaylizButtonSize.small,
                    ),
                  ),
                  AppSpacing.hSM,
                  Expanded(
                    child: DaylizButton(
                      label: 'Delete',
                      onPressed: () => _deleteAddress(context, ref, address),
                      leadingIcon: Icons.delete_outline,
                      type: DaylizButtonType.danger,
                      size: DaylizButtonSize.small,
                    ),
                  ),
                  if (!address.isDefault) ...[
                    AppSpacing.hSM,
                    Expanded(
                      child: DaylizButton(
                        label: 'Set Default',
                        onPressed: () => _setAsDefault(context, ref, address),
                        leadingIcon: Icons.check,
                        type: DaylizButtonType.tertiary,
                        size: DaylizButtonSize.small,
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToAddAddress(BuildContext context, WidgetRef? ref) async {
    final result = await context.push<Address>('/address-form');
    
    if (result != null && ref != null) {
      ref.read(addressesProvider.notifier).state = [
        ...ref.read(addressesProvider),
        result,
      ];
    }
  }

  Future<void> _navigateToEditAddress(
    BuildContext context,
    WidgetRef ref,
    Address address,
  ) async {
    final result = await context.push<Address>('/address-form', extra: address);
    
    if (result != null) {
      final addresses = ref.read(addressesProvider);
      final updatedAddresses = addresses.map((addr) {
        return addr.id == result.id ? result : addr;
      }).toList();
      
      ref.read(addressesProvider.notifier).state = updatedAddresses;
    }
  }

  void _deleteAddress(
    BuildContext context,
    WidgetRef ref,
    Address address,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address'),
        content: const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              // Delete address from list
              final addresses = ref.read(addressesProvider);
              final updatedAddresses = addresses.where(
                (addr) => addr.id != address.id
              ).toList();
              
              ref.read(addressesProvider.notifier).state = updatedAddresses;
              
              Navigator.of(context).pop();
              
              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Address deleted successfully'),
                ),
              );
            },
            child: Text(
              'DELETE',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  void _setAsDefault(
    BuildContext context,
    WidgetRef ref,
    Address address,
  ) {
    final addresses = ref.read(addressesProvider);
    final updatedAddresses = addresses.map((addr) {
      if (addr.id == address.id) {
        return addr.copyWith(isDefault: true);
      } else if (addr.isDefault) {
        return addr.copyWith(isDefault: false);
      }
      return addr;
    }).toList();
    
    ref.read(addressesProvider.notifier).state = updatedAddresses;
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Default address updated'),
      ),
    );
  }
} 