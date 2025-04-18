import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dayliz_app/models/address.dart';
import 'package:dayliz_app/providers/address_provider.dart';
import 'package:dayliz_app/theme/dayliz_theme.dart';
import 'package:dayliz_app/widgets/dayliz_button.dart';

class AddressSelectionWidget extends ConsumerWidget {
  final bool allowSelection;
  final bool showAddButton;
  
  const AddressSelectionWidget({
    Key? key,
    this.allowSelection = true,
    this.showAddButton = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(addressProvider);
    final selectedAddress = ref.watch(selectedAddressProvider);
    
    // Loading state
    if (addressesAsync.isLoading) {
      return _buildLoadingState();
    }
    
    // Error state
    if (addressesAsync.error != null) {
      return _buildErrorState(context, ref, addressesAsync.error!);
    }
    
    final addresses = addressesAsync.addresses;
    
    // Empty state
    if (addresses.isEmpty) {
      return _buildEmptyState(context, ref);
    }
    
    // Address list
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: addresses.length,
          itemBuilder: (context, index) {
            final address = addresses[index];
            final isSelected = selectedAddress?.id == address.id;
            
            return _buildAddressCard(context, ref, address, isSelected);
          },
        ),
        
        if (showAddButton) ...[
          AppSpacing.vMD,
          DaylizButton(
            label: 'Add New Address',
            onPressed: () => _navigateToAddAddress(context, ref),
            leadingIcon: Icons.add,
            type: DaylizButtonType.outlined,
            fullWidth: true,
          ),
        ],
      ],
    );
  }
  
  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: CircularProgressIndicator(),
      ),
    );
  }
  
  Widget _buildErrorState(BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            AppSpacing.vMD,
            Text(
              'Failed to load addresses',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            AppSpacing.vSM,
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            AppSpacing.vLG,
            DaylizButton(
              label: 'Try Again',
              onPressed: () => ref.refresh(addressProvider),
              leadingIcon: Icons.refresh,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off, size: 48, color: Colors.grey),
            AppSpacing.vMD,
            Text(
              'No addresses found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            AppSpacing.vSM,
            Text(
              'Add a new address to continue with checkout',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            AppSpacing.vLG,
            DaylizButton(
              label: 'Add New Address',
              onPressed: () => _navigateToAddAddress(context, ref),
              leadingIcon: Icons.add,
            ),
          ],
        ),
      ),
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
                                  ),
                                ),
                              ),
                            ],
                            if (address.addressType != null) ...[
                              AppSpacing.hSM,
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  address.addressType!,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.secondary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        AppSpacing.vXS,
                        Text(
                          address.recipientPhone ?? 'No phone number',
                          style: theme.textTheme.bodyMedium,
                        ),
                        AppSpacing.vXS,
                        Text(
                          address.formattedAddress,
                          style: theme.textTheme.bodyMedium,
                        ),
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
              
              AppSpacing.vMD,
              
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  DaylizButton(
                    label: 'Edit',
                    onPressed: () => _navigateToEditAddress(context, ref, address),
                    type: DaylizButtonType.text,
                    size: DaylizButtonSize.small,
                  ),
                  AppSpacing.hSM,
                  if (!address.isDefault)
                    DaylizButton(
                      label: 'Delete',
                      onPressed: () => _confirmDeleteAddress(context, ref, address),
                      type: DaylizButtonType.text,
                      size: DaylizButtonSize.small,
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
    ref.read(selectedAddressProvider.notifier).state = address;
  }
  
  Future<void> _navigateToAddAddress(BuildContext context, WidgetRef ref) async {
    // A mock implementation since we don't have the actual navigation
    // In the real app, you would navigate to the AddAddressScreen
    // and handle the result
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Add Address')),
          body: const Center(child: Text('Mock Add Address Screen')),
        ),
      ),
    );
    
    if (result != null && result is Address) {
      await ref.read(addressProvider.notifier).addAddress(result);
    }
  }
  
  Future<void> _navigateToEditAddress(BuildContext context, WidgetRef ref, Address address) async {
    // A mock implementation since we don't have the actual navigation
    // In the real app, you would navigate to the EditAddressScreen
    // and handle the result
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Edit Address')),
          body: Center(child: Text('Mock Edit Address Screen for ${address.recipientName ?? "Address"}')),
        ),
      ),
    );
    
    if (result != null && result is Address) {
      await ref.read(addressProvider.notifier).updateAddress(result);
    }
  }
  
  Future<void> _confirmDeleteAddress(BuildContext context, WidgetRef ref, Address address) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address'),
        content: Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (result == true && address.id != null) {
      await ref.read(addressProvider.notifier).deleteAddress(address.id!);
    }
  }
} 