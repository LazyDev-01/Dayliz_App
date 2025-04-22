import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/failures.dart';
import '../../domain/entities/user_profile.dart';

// A simple provider for the current user ID (this would typically come from auth)
final currentUserIdProvider = Provider<String?>((ref) {
  // In a real implementation, this would come from the auth system
  // For now, we'll just return a mock ID
  return 'mock-user-id';
});

/// State representation for user addresses
enum UserAddressesStatus { initial, loading, loaded, error }

class UserAddressesState {
  final UserAddressesStatus status;
  final List<Address> addresses;
  final String? errorMessage;

  const UserAddressesState({
    this.status = UserAddressesStatus.initial,
    this.addresses = const [],
    this.errorMessage,
  });

  UserAddressesState copyWith({
    UserAddressesStatus? status,
    List<Address>? addresses,
    String? errorMessage,
  }) {
    return UserAddressesState(
      status: status ?? this.status,
      addresses: addresses ?? this.addresses,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get isInitial => status == UserAddressesStatus.initial;
  bool get isLoading => status == UserAddressesStatus.loading;
  bool get isLoaded => status == UserAddressesStatus.loaded;
  bool get hasError => status == UserAddressesStatus.error;
}

class UserAddressesNotifier extends StateNotifier<UserAddressesState> {
  final String? _userId;

  UserAddressesNotifier({
    required String? userId,
  })  : _userId = userId,
        super(const UserAddressesState());

  Future<void> getUserAddresses() async {
    if (_userId == null) {
      state = state.copyWith(
        status: UserAddressesStatus.error,
        errorMessage: 'User not logged in',
      );
      return;
    }

    state = state.copyWith(status: UserAddressesStatus.loading);

    // TODO: Implement actual data fetching
    // This is a temporary mock implementation
    await Future.delayed(const Duration(seconds: 1));
    
    try {
      // Mock data
      final mockAddresses = [
        Address(
          id: '1',
          name: 'Home',
          addressLine1: '123 Main St',
          city: 'New York',
          state: 'NY',
          postalCode: '10001',
          country: 'USA',
          isDefault: true,
        ),
        Address(
          id: '2',
          name: 'Work',
          addressLine1: '456 Office Blvd',
          addressLine2: 'Suite 789',
          city: 'New York',
          state: 'NY',
          postalCode: '10002',
          country: 'USA',
        ),
        Address(
          id: '3',
          name: 'Parents',
          addressLine1: '789 Family Rd',
          city: 'Boston',
          state: 'MA',
          postalCode: '02108',
          country: 'USA',
          phoneNumber: '(555) 123-4567',
        ),
      ];
      
      state = state.copyWith(
        status: UserAddressesStatus.loaded,
        addresses: mockAddresses,
      );
    } catch (e) {
      state = state.copyWith(
        status: UserAddressesStatus.error,
        errorMessage: 'Failed to load addresses: $e',
      );
    }
  }

  Future<void> deleteAddress(String addressId) async {
    if (_userId == null) {
      state = state.copyWith(
        status: UserAddressesStatus.error,
        errorMessage: 'User not logged in',
      );
      return;
    }

    state = state.copyWith(status: UserAddressesStatus.loading);

    // TODO: Implement actual delete functionality
    // This is a temporary mock implementation
    await Future.delayed(const Duration(milliseconds: 500));
    
    try {
      // Remove the address from the list
      final updatedAddresses = state.addresses.where((a) => a.id != addressId).toList();
      state = state.copyWith(
        status: UserAddressesStatus.loaded,
        addresses: updatedAddresses,
      );
    } catch (e) {
      state = state.copyWith(
        status: UserAddressesStatus.error,
        errorMessage: 'Failed to delete address: $e',
      );
    }
  }

  Future<void> setDefaultAddress(String addressId) async {
    if (_userId == null) {
      state = state.copyWith(
        status: UserAddressesStatus.error,
        errorMessage: 'User not logged in',
      );
      return;
    }

    state = state.copyWith(status: UserAddressesStatus.loading);

    // TODO: Implement actual functionality
    // This is a temporary mock implementation
    await Future.delayed(const Duration(milliseconds: 500));
    
    try {
      // Update all addresses to reflect the new default
      final updatedAddresses = state.addresses.map((address) {
        return address.copyWith(isDefault: address.id == addressId);
      }).toList();

      state = state.copyWith(
        status: UserAddressesStatus.loaded,
        addresses: updatedAddresses,
      );
    } catch (e) {
      state = state.copyWith(
        status: UserAddressesStatus.error,
        errorMessage: 'Failed to set default address: $e',
      );
    }
  }
}

// Provider for the user addresses notifier
final userAddressesNotifierProvider =
    StateNotifierProvider<UserAddressesNotifier, UserAddressesState>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  
  return UserAddressesNotifier(
    userId: userId,
  );
});

// Provider for accessing all addresses
final allAddressesProvider = Provider<List<Address>>((ref) {
  return ref.watch(userAddressesNotifierProvider).addresses;
});

// Provider for accessing the default address
final defaultAddressProvider = Provider<Address?>((ref) {
  final addresses = ref.watch(allAddressesProvider);
  if (addresses.isEmpty) return null;
  
  return addresses.firstWhere(
    (address) => address.isDefault,
    orElse: () => addresses.first,
  );
});