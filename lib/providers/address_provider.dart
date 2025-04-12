import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dayliz_app/models/address.dart';
import 'package:dayliz_app/services/api_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dayliz_app/providers/auth_provider.dart';

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
  final ApiService _apiService;
  
  AddressNotifier(this._ref, this._apiService) : super(AddressState()) {
    fetchAddresses();
  }

  Future<void> fetchAddresses() async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      final userId = _ref.read(currentUserProvider)?.id;
      if (userId == null) {
        state = state.copyWith(isLoading: false, error: 'User not authenticated');
        return;
      }
      
      final response = await _apiService.get('user_addresses?user_id=eq.$userId');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        final addresses = data.map((json) => Address.fromJson(json)).toList();
        
        // Set default address as selected if available
        final defaultAddress = addresses.firstWhere(
          (address) => address.isDefault, 
          orElse: () => addresses.isNotEmpty ? addresses.first : Address(
            id: '',
            userId: userId,
            name: '',
            addressLine1: '',
            city: '',
            state: '',
            country: '',
            postalCode: '',
            phoneNumber: '',
          )
        );
        
        state = state.copyWith(
          addresses: addresses,
          isLoading: false,
          selectedAddress: defaultAddress
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to fetch addresses: ${response.statusMessage}'
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error fetching addresses: $e'
      );
    }
  }

  Future<void> addAddress(Address address) async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      final userId = _ref.read(currentUserProvider)?.id;
      if (userId == null) {
        state = state.copyWith(isLoading: false, error: 'User not authenticated');
        return;
      }
      
      // Set as default if it's the first address
      final isDefault = state.addresses.isEmpty || address.isDefault;
      
      final addressData = {
        ...address.toJson(),
        'user_id': userId,
        'is_default': isDefault,
      };
      
      final response = await _apiService.post('user_addresses', addressData);
      
      if (response.statusCode == 201) {
        // Refetch addresses to get the updated list
        await fetchAddresses();
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to add address: ${response.statusMessage}'
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error adding address: $e'
      );
    }
  }

  Future<void> updateAddress(Address address) async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      if (address.id == null) {
        state = state.copyWith(isLoading: false, error: 'Address ID is required for update');
        return;
      }
      
      final response = await _apiService.patch(
        'user_addresses?id=eq.${address.id}',
        address.toJson()
      );
      
      if (response.statusCode == 200) {
        // If updating the default address, need to update other addresses too
        if (address.isDefault) {
          await _updateDefaultAddress(address.id!);
        }
        
        // Refetch addresses to get the updated list
        await fetchAddresses();
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to update address: ${response.statusMessage}'
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
      final response = await _apiService.delete('user_addresses?id=eq.$addressId');
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        // Refetch addresses to get the updated list
        await fetchAddresses();
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to delete address: ${response.statusMessage}'
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
      await _apiService.patch(
        'user_addresses?id=eq.$addressId',
        {'is_default': true}
      );
      
      // Update all other addresses to not be default
      await _updateDefaultAddress(addressId);
      
      // Refetch to update the state
      await fetchAddresses();
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

  // Helper method to ensure only one default address exists
  Future<void> _updateDefaultAddress(String newDefaultId) async {
    try {
      // Update all other addresses to not be default
      await _apiService.patch(
        'user_addresses?id=neq.$newDefaultId',
        {'is_default': false}
      );
    } catch (e) {
      print('Error updating default addresses: $e');
    }
  }
}

final addressNotifierProvider = StateNotifierProvider<AddressNotifier, AddressState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AddressNotifier(ref, apiService);
});

// For backwards compatibility with older code
final addressProvider = addressNotifierProvider;

final apiServiceProvider = Provider<ApiService>((ref) {
  final supabase = Supabase.instance.client;
  return ApiService(supabase);
});

// Provider for the selected address
final selectedAddressProvider = StateProvider<Address?>((ref) {
  return ref.watch(addressProvider).selectedAddress;
}); 