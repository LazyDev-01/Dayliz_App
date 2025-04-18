import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dayliz_app/models/address.dart';
import 'package:dayliz_app/services/address_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dayliz_app/providers/auth_provider.dart';
import 'package:flutter/foundation.dart';

// State for address list
class AddressState {
  final List<Address> addresses;
  final bool isLoading;
  final String? error;
  final Address? selectedAddress;

  AddressState({
    this.addresses = const [],
    this.isLoading = false,
    this.error,
    this.selectedAddress,
  });

  AddressState copyWith({
    List<Address>? addresses,
    bool? isLoading,
    String? error,
    Address? selectedAddress,
    bool clearError = false,
    bool clearSelectedAddress = false,
  }) {
    return AddressState(
      addresses: addresses ?? this.addresses,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      selectedAddress: clearSelectedAddress ? null : (selectedAddress ?? this.selectedAddress),
    );
  }
}

class AddressNotifier extends StateNotifier<AddressState> {
  final Ref _ref;
  final AddressService _addressService = AddressService.instance;
  
  AddressNotifier(this._ref) : super(AddressState()) {
    loadAddresses();
  }

  // Initial loading of addresses
  Future<void> loadAddresses() async {
    fetchAddresses();
  }

  Future<void> fetchAddresses() async {
    debugPrint("Starting fetchAddresses");
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      final userId = _ref.read(currentUserProvider)?.id;
      if (userId == null) {
        debugPrint("Error: User not authenticated during fetchAddresses");
        state = state.copyWith(isLoading: false, error: 'User not authenticated');
        return;
      }
      
      debugPrint("Fetching addresses for user: $userId");
      
      // Use the address service to get addresses
      final addresses = await _addressService.getAddresses();
      
      debugPrint("Fetched ${addresses.length} addresses");
      
      if (addresses.isNotEmpty) {
        // Set default address as selected if available
        Address? defaultAddress;
        try {
          defaultAddress = addresses.firstWhere(
            (address) => address.isDefault, 
          );
          debugPrint("Found default address: ${defaultAddress.id}");
        } catch (e) {
          // If no default address, use the first one
          defaultAddress = addresses.first;
          debugPrint("No default address, using first: ${defaultAddress.id}");
        }
        
        state = state.copyWith(
          addresses: addresses,
          isLoading: false,
          selectedAddress: defaultAddress,
          clearError: true
        );
      } else {
        // No addresses found
        state = state.copyWith(
          addresses: [],
          isLoading: false,
          clearError: true
        );
      }
    } catch (e) {
      debugPrint("Exception during fetchAddresses: $e");
      state = state.copyWith(
        isLoading: false,
        error: 'Error fetching addresses: $e'
      );
    }
  }

  Future<Address?> addAddress(Address address) async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      debugPrint("Adding address for user");
      final userId = _ref.read(currentUserProvider)?.id;
      if (userId == null) {
        state = state.copyWith(isLoading: false, error: 'User not authenticated');
        return null;
      }
      
      // Set as default if it's the first address
      final isDefault = state.addresses.isEmpty || address.isDefault;
      
      // Add address using the address service
      final newAddress = await _addressService.addAddress(
        address.addressLine1,
        address.addressLine2,
        address.city,
        address.state,
        address.country,
        address.postalCode,
        isDefault,
        address.addressType,
        address.recipientName,
        address.recipientPhone,
        address.landmark,
        address.latitude,
        address.longitude,
        address.zone,
      );
      
      if (newAddress != null) {
        debugPrint("Address added successfully: ${newAddress.id}");
        
        // Update the state with the new address
        final updatedAddresses = [...state.addresses, newAddress];
        
        // If this is the default address, update any other addresses
        if (isDefault && updatedAddresses.length > 1) {
          for (int i = 0; i < updatedAddresses.length - 1; i++) {
            if (updatedAddresses[i].isDefault) {
              updatedAddresses[i] = updatedAddresses[i].copyWith(isDefault: false);
            }
          }
        }
        
        // Set as selected if it's the first address or is marked as default
        final selectedAddress = isDefault ? newAddress : state.selectedAddress;
        
        state = state.copyWith(
          addresses: updatedAddresses,
          isLoading: false,
          selectedAddress: selectedAddress,
          clearError: true
        );
        
        return newAddress;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to add address: No response from server'
        );
        return null;
      }
    } catch (e) {
      debugPrint("Exception when adding address: $e");
      state = state.copyWith(
        isLoading: false,
        error: 'Error adding address: $e'
      );
      return null;
    }
  }

  Future<void> updateAddress(Address address) async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      if (address.id.isEmpty) {
        state = state.copyWith(isLoading: false, error: 'Address ID is required for update');
        return;
      }
      
      final response = await _addressService.updateAddress(
        address.id,
        addressLine1: address.addressLine1,
        addressLine2: address.addressLine2,
        city: address.city,
        state: address.state,
        country: address.country,
        postalCode: address.postalCode,
        isDefault: address.isDefault,
        addressType: address.addressType,
        recipientName: address.recipientName,
        recipientPhone: address.recipientPhone,
        landmark: address.landmark,
        latitude: address.latitude,
        longitude: address.longitude,
        zone: address.zone,
      );
      
      if (response) {
        // Refetch addresses to get the updated list
        await fetchAddresses();
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to update address: No response from server'
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error updating address: $e'
      );
    }
  }

  Future<void> deleteAddress(String addressId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      final response = await _addressService.deleteAddress(addressId);
      
      if (response) {
        // Refetch addresses to get the updated list
        await fetchAddresses();
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to delete address: No response from server'
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error deleting address: $e'
      );
    }
  }
  
  Future<void> setDefaultAddress(String addressId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      // Update the specified address to be default
      final response = await _addressService.setDefaultAddress(addressId);
      
      if (response) {
        // Refetch addresses to get the updated list
        await fetchAddresses();
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to set default address: No response from server'
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error setting default address: $e'
      );
    }
  }

  void selectAddress(Address address) {
    state = state.copyWith(selectedAddress: address);
  }

  // Get address by ID from the current state
  Address? getAddressById(String id) {
    try {
      return state.addresses.firstWhere(
        (address) => address.id == id,
      );
    } catch (e) {
      return null;
    }
  }
}

final addressNotifierProvider = StateNotifierProvider<AddressNotifier, AddressState>((ref) {
  return AddressNotifier(ref);
});

// For backwards compatibility with older code
final addressProvider = addressNotifierProvider;

final apiServiceProvider = Provider<AddressService>((ref) {
  // Return the singleton instance directly
  return AddressService.instance;
});

// Provider for the selected address
final selectedAddressProvider = StateProvider<Address?>((ref) {
  return ref.watch(addressProvider).selectedAddress;
});

// Provider to get a specific address by ID
final addressByIdProvider = Provider.family<Address?, String>((ref, addressId) {
  final addressState = ref.watch(addressNotifierProvider);
  try {
    return addressState.addresses.firstWhere((address) => address.id == addressId);
  } catch (e) {
    debugPrint('Address with ID $addressId not found');
    return null;
  }
}); 