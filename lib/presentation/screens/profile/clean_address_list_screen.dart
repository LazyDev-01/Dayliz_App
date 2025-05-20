import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/address.dart';
import '../../../domain/usecases/user_profile/get_user_addresses_usecase.dart';
import '../../../domain/usecases/user_profile/delete_address_usecase.dart';
import '../../../domain/usecases/user_profile/set_default_address_usecase.dart';
import '../../providers/user_providers.dart';
import '../../widgets/common/common_app_bar.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/empty_state.dart';
import 'clean_address_form_screen.dart';

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
    final userId = ref.read(currentUserIdProvider);
    if (userId != null) {
      await ref.read(addressesNotifierProvider.notifier).getAddresses(userId);
    }
  }

  void _navigateToAddAddress() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CleanAddressFormScreen(),
      ),
    );
  }

  void _navigateToEditAddress(Address address) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CleanAddressFormScreen(address: address),
      ),
    );
  }

  Future<void> _deleteAddress(String addressId) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId != null) {
      await ref.read(addressesNotifierProvider.notifier).deleteAddress(userId, addressId);
    }
  }

  Future<void> _setDefaultAddress(String addressId) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId != null) {
      await ref.read(addressesNotifierProvider.notifier).setDefaultAddress(userId, addressId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final addressesState = ref.watch(addressesNotifierProvider);

    return Scaffold(
      appBar: CommonAppBars.withBackButton(
        title: 'My Addresses',
        fallbackRoute: '/profile',
        backButtonTooltip: 'Back to Profile',
      ),
      body: addressesState.when(
        loading: () => const LoadingIndicator(),
        error: (error, _) => ErrorState(
          message: 'Error loading addresses: $error',
          onRetry: _fetchAddresses,
        ),
        data: (addresses) {
          if (addresses.isEmpty) {
            return EmptyState(
              icon: Icons.location_off,
              title: 'No Addresses',
              message: 'You have no saved addresses yet.',
              buttonText: 'Add Address',
              onButtonPressed: _navigateToAddAddress,
            );
          }

          return RefreshIndicator(
            onRefresh: _fetchAddresses,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: addresses.length,
              itemBuilder: (context, index) {
                final address = addresses[index];
                return AddressCard(
                  address: address,
                  onEdit: () => _navigateToEditAddress(address),
                  onDelete: () => _deleteAddress(address.id),
                  onSetDefault: address.isDefault ? null : () => _setDefaultAddress(address.id),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddAddress,
        tooltip: 'Add Address',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddressCard extends StatelessWidget {
  final Address address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onSetDefault;

  const AddressCard({
    Key? key,
    required this.address,
    required this.onEdit,
    required this.onDelete,
    this.onSetDefault,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
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
                Text(
                  address.addressType?.toUpperCase() ?? 'ADDRESS',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                if (address.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Default',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${address.addressLine1}, ${address.city}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              '${address.state}, ${address.postalCode}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              address.country,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (address.phoneNumber != null) ...[
              const SizedBox(height: 4),
              Text(
                address.phoneNumber!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onSetDefault != null)
                  TextButton(
                    onPressed: onSetDefault,
                    child: const Text('Set as Default'),
                  ),
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