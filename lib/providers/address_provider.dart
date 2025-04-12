import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dayliz_app/models/address.dart';
import 'package:dayliz_app/services/address_service.dart';

/// Provider for fetching addresses
final addressesProvider = FutureProvider<List<Address>>((ref) async {
  return await AddressService.instance.getAddresses();
});

/// Provider for the selected address (e.g., for checkout)
final selectedAddressProvider = StateProvider<Address?>((ref) => null);

/// Notifier for managing addresses
class AddressNotifier extends StateNotifier<AsyncValue<List<Address>>> {
  AddressNotifier() : super(const AsyncValue.loading()) {
    loadAddresses();
  }

  Future<void> loadAddresses() async {
    state = const AsyncValue.loading();
    try {
      final addresses = await AddressService.instance.getAddresses();
      state = AsyncValue.data(addresses);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> addAddress(Address address) async {
    try {
      final newAddress = await AddressService.instance.addAddress(address);
      if (newAddress != null) {
        state.whenData((addresses) {
          state = AsyncValue.data([newAddress, ...addresses]);
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateAddress(Address address) async {
    try {
      final updatedAddress = await AddressService.instance.updateAddress(address);
      if (updatedAddress != null) {
        state.whenData((addresses) {
          final index = addresses.indexWhere((a) => a.id == address.id);
          if (index >= 0) {
            final newList = List<Address>.from(addresses);
            newList[index] = updatedAddress;
            state = AsyncValue.data(newList);
          }
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteAddress(String id) async {
    try {
      await AddressService.instance.deleteAddress(id);
      state.whenData((addresses) {
        final newList = addresses.where((a) => a.id != id).toList();
        state = AsyncValue.data(newList);
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> setDefaultAddress(String id) async {
    try {
      final updatedAddress = await AddressService.instance.setDefaultAddress(id);
      if (updatedAddress != null) {
        state.whenData((addresses) {
          final newList = addresses.map((address) {
            if (address.id == id) {
              return updatedAddress;
            } else if (address.isDefault) {
              return address.copyWith(isDefault: false);
            }
            return address;
          }).toList();
          state = AsyncValue.data(newList);
        });
      }
    } catch (e) {
      rethrow;
    }
  }
}

/// Provider for address notifier
final addressNotifierProvider = StateNotifierProvider<AddressNotifier, AsyncValue<List<Address>>>((ref) {
  return AddressNotifier();
}); 