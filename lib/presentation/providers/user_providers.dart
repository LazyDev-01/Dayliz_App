import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/failures.dart';
import '../../core/network/network_info.dart';
import '../../domain/entities/address.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_profile_repository.dart';
import '../../domain/usecases/user_profile/get_user_addresses_usecase.dart';
import '../../domain/usecases/user_profile/add_address_usecase.dart';
import '../../domain/usecases/user_profile/update_address_usecase.dart';
import '../../domain/usecases/user_profile/delete_address_usecase.dart';
import '../../domain/usecases/user_profile/set_default_address_usecase.dart';
import '../../domain/usecases/user_profile/get_user_profile_usecase.dart';
import '../../data/datasources/user_profile_datasource.dart';
import '../../di/dependency_injection.dart';
import '../providers/user_profile_providers.dart';

// Provider for the current user ID from Supabase auth
final currentUserIdProvider = StateProvider<String?>((ref) {
  // Get the current authenticated user ID from Supabase
  final currentUser = Supabase.instance.client.auth.currentUser;
  if (currentUser != null) {
    return currentUser.id;
  }
  // Return null if not authenticated
  return null;
});

// Helper function to ensure UserProfileRepository is registered
void _ensureUserProfileRepositoryRegistered() {
  if (!sl.isRegistered<UserProfileRepository>()) {
    debugPrint('UserProfileRepository not registered, registering now...');

    // Register the repository with a simpler implementation that doesn't depend on other services
    sl.registerLazySingleton<UserProfileRepository>(
      () => TempUserProfileRepositoryImpl(
        remoteDataSource: UserProfileDataSourceImpl(client: Supabase.instance.client),
        networkInfo: NetworkInfoImpl(InternetConnectionChecker()),
      ),
    );

    debugPrint('UserProfileRepository registered successfully with temporary implementation');
  }
}

// Provider for the user profile repository
final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  try {
    // Try to get the repository
    return sl<UserProfileRepository>();
  } catch (e) {
    // If it's not registered, register it
    debugPrint('Error getting UserProfileRepository: $e');
    _ensureUserProfileRepositoryRegistered();
    return sl<UserProfileRepository>();
  }
});

// Provider for the GetUserAddressesUseCase
final getUserAddressesUseCaseProvider = Provider<GetUserAddressesUseCase>((ref) {
  final repository = ref.watch(userProfileRepositoryProvider);
  return GetUserAddressesUseCase(repository);
});

// Provider for the AddAddressUseCase
final addAddressUseCaseProvider = Provider<AddAddressUseCase>((ref) {
  final repository = ref.watch(userProfileRepositoryProvider);
  return AddAddressUseCase(repository);
});

// Provider for the UpdateAddressUseCase
final updateAddressUseCaseProvider = Provider<UpdateAddressUseCase>((ref) {
  final repository = ref.watch(userProfileRepositoryProvider);
  return UpdateAddressUseCase(repository);
});

// Provider for the DeleteAddressUseCase
final deleteAddressUseCaseProvider = Provider<DeleteAddressUseCase>((ref) {
  final repository = ref.watch(userProfileRepositoryProvider);
  return DeleteAddressUseCase(repository);
});

// Provider for the SetDefaultAddressUseCase
final setDefaultAddressUseCaseProvider = Provider<SetDefaultAddressUseCase>((ref) {
  final repository = ref.watch(userProfileRepositoryProvider);
  return SetDefaultAddressUseCase(repository);
});

// Provider for the GetUserProfileUseCase
final getUserProfileUseCaseProvider = Provider<GetUserProfileUseCase>((ref) {
  final repository = ref.watch(userProfileRepositoryProvider);
  return GetUserProfileUseCase(repository);
});

// State for addresses
class AddressesState {
  final List<Address> addresses;
  final bool isLoading;
  final String? error;

  AddressesState({
    required this.addresses,
    required this.isLoading,
    this.error,
  });

  AddressesState copyWith({
    List<Address>? addresses,
    bool? isLoading,
    String? error,
  }) {
    return AddressesState(
      addresses: addresses ?? this.addresses,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Notifier for addresses
class AddressesNotifier extends StateNotifier<AsyncValue<List<Address>>> {
  final GetUserAddressesUseCase? _getUserAddressesUseCase;
  final AddAddressUseCase? _addAddressUseCase;
  final UpdateAddressUseCase? _updateAddressUseCase;
  final DeleteAddressUseCase? _deleteAddressUseCase;
  final SetDefaultAddressUseCase? _setDefaultAddressUseCase;
  final String? _errorMessage;

  AddressesNotifier({
    required GetUserAddressesUseCase getUserAddressesUseCase,
    required AddAddressUseCase addAddressUseCase,
    required UpdateAddressUseCase updateAddressUseCase,
    required DeleteAddressUseCase deleteAddressUseCase,
    required SetDefaultAddressUseCase setDefaultAddressUseCase,
  })  : _getUserAddressesUseCase = getUserAddressesUseCase,
        _addAddressUseCase = addAddressUseCase,
        _updateAddressUseCase = updateAddressUseCase,
        _deleteAddressUseCase = deleteAddressUseCase,
        _setDefaultAddressUseCase = setDefaultAddressUseCase,
        _errorMessage = null,
        super(const AsyncValue.loading());

  // Constructor for error state
  AddressesNotifier.withError(String errorMessage)
      : _getUserAddressesUseCase = null,
        _addAddressUseCase = null,
        _updateAddressUseCase = null,
        _deleteAddressUseCase = null,
        _setDefaultAddressUseCase = null,
        _errorMessage = errorMessage,
        super(AsyncValue.error(errorMessage, StackTrace.current));

  Future<void> getAddresses(String userId) async {
    if (_errorMessage != null) {
      // If we're in error state, don't try to fetch addresses
      return;
    }

    if (_getUserAddressesUseCase == null) {
      state = AsyncValue.error('Address service not initialized', StackTrace.current);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final result = await _getUserAddressesUseCase!(GetUserAddressesParams(userId: userId));
      result.fold(
        (failure) => state = AsyncValue.error(_mapFailureToMessage(failure), StackTrace.current),
        (addresses) => state = AsyncValue.data(addresses),
      );
    } catch (e) {
      state = AsyncValue.error('Failed to load addresses: $e', StackTrace.current);
    }
  }

  Future<void> addAddress(String userId, Address address) async {
    if (_errorMessage != null || _addAddressUseCase == null) {
      state = AsyncValue.error('Address service not initialized', StackTrace.current);
      return;
    }

    try {
      final result = await _addAddressUseCase!(AddAddressParams(userId: userId, address: address));
      result.fold(
        (failure) => throw Exception(_mapFailureToMessage(failure)),
        (newAddress) {
          final currentAddresses = state.value ?? [];
          state = AsyncValue.data([...currentAddresses, newAddress]);
        },
      );
    } catch (e) {
      state = AsyncValue.error('Failed to add address: $e', StackTrace.current);
    }
  }

  Future<void> updateAddress(String userId, Address address) async {
    if (_errorMessage != null || _updateAddressUseCase == null) {
      state = AsyncValue.error('Address service not initialized', StackTrace.current);
      return;
    }

    try {
      final result = await _updateAddressUseCase!(UpdateAddressParams(userId: userId, address: address));
      result.fold(
        (failure) => throw Exception(_mapFailureToMessage(failure)),
        (updatedAddress) {
          final currentAddresses = state.value ?? [];
          final updatedAddresses = currentAddresses.map((a) {
            return a.id == address.id ? updatedAddress : a;
          }).toList();
          state = AsyncValue.data(updatedAddresses);
        },
      );
    } catch (e) {
      state = AsyncValue.error('Failed to update address: $e', StackTrace.current);
    }
  }

  Future<void> deleteAddress(String userId, String addressId) async {
    if (_errorMessage != null || _deleteAddressUseCase == null) {
      state = AsyncValue.error('Address service not initialized', StackTrace.current);
      return;
    }

    // Set state to loading to indicate operation in progress
    state = const AsyncValue.loading();

    try {
      debugPrint('Deleting address $addressId for user $userId');
      final result = await _deleteAddressUseCase!(DeleteAddressParams(userId: userId, addressId: addressId));

      return result.fold(
        (failure) {
          final errorMessage = _mapFailureToMessage(failure);
          debugPrint('Failed to delete address: $errorMessage');

          // Check for specific error messages
          if (errorMessage.contains('used as a shipping address') ||
              errorMessage.contains('used as a billing address') ||
              errorMessage.contains('used in one or more orders')) {
            state = AsyncValue.error('This address cannot be deleted because it is used in one or more orders.', StackTrace.current);
            throw Exception('This address cannot be deleted because it is used in one or more orders.');
          } else if (errorMessage.contains('not found')) {
            state = AsyncValue.error('Address not found or already deleted.', StackTrace.current);
            throw Exception('Address not found or already deleted.');
          } else {
            state = AsyncValue.error(errorMessage, StackTrace.current);
            throw Exception(errorMessage); // Throw to be caught by UI
          }
        },
        (success) {
          if (success) {
            debugPrint('Address deleted successfully, updating state');
            final currentAddresses = state.valueOrNull ?? [];
            final updatedAddresses = currentAddresses.where((a) => a.id != addressId).toList();
            state = AsyncValue.data(updatedAddresses);
          } else {
            debugPrint('Delete operation returned false');
            state = AsyncValue.error('Failed to delete address', StackTrace.current);
            throw Exception('Failed to delete address'); // Throw to be caught by UI
          }
        },
      );
    } catch (e) {
      debugPrint('Exception in deleteAddress: $e');

      // Format the error message for better readability
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring('Exception: '.length);
      }

      state = AsyncValue.error('Failed to delete address: $errorMessage', StackTrace.current);
      rethrow; // Rethrow to be caught by UI
    }
  }

  Future<void> setDefaultAddress(String userId, String addressId) async {
    if (_errorMessage != null || _setDefaultAddressUseCase == null) {
      state = AsyncValue.error('Address service not initialized', StackTrace.current);
      return;
    }

    try {
      final result = await _setDefaultAddressUseCase!(SetDefaultAddressParams(userId: userId, addressId: addressId));
      result.fold(
        (failure) => throw Exception(_mapFailureToMessage(failure)),
        (success) {
          if (success) {
            final currentAddresses = state.value ?? [];
            final updatedAddresses = currentAddresses.map((a) {
              return a.copyWith(isDefault: a.id == addressId);
            }).toList();
            state = AsyncValue.data(updatedAddresses);
          }
        },
      );
    } catch (e) {
      state = AsyncValue.error('Failed to set default address: $e', StackTrace.current);
    }
  }

  /// Get a specific address by ID
  Future<Address?> getAddressById(String userId, String addressId) async {
    if (_errorMessage != null) {
      throw Exception('Address service not initialized');
    }

    // First, ensure we have the latest addresses
    if (state is AsyncLoading || state.value == null) {
      await getAddresses(userId);
    }

    try {
      // Find the address in the current state
      final addresses = state.value ?? [];
      if (addresses.isEmpty) {
        return null;
      }

      return addresses.firstWhere(
        (a) => a.id == addressId,
        orElse: () => throw Exception('Address not found'),
      );
    } catch (e) {
      throw Exception('Failed to get address: $e');
    }
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure && failure.message.isNotEmpty) {
      return failure.message;
    }

    switch (failure.runtimeType) {
      case ServerFailure:
        return 'Server error occurred';
      case NetworkFailure:
        return 'Network error occurred. Please check your connection.';
      case CacheFailure:
        return 'Cache error occurred';
      default:
        return 'An unexpected error occurred';
    }
  }
}

// Provider for the addresses notifier
final addressesNotifierProvider = StateNotifierProvider<AddressesNotifier, AsyncValue<List<Address>>>((ref) {
  try {
    // Ensure the repository is registered
    if (!sl.isRegistered<UserProfileRepository>()) {
      debugPrint('addressesNotifierProvider: UserProfileRepository not registered, registering now...');
      _ensureUserProfileRepositoryRegistered();
    }

    return AddressesNotifier(
      getUserAddressesUseCase: ref.watch(getUserAddressesUseCaseProvider),
      addAddressUseCase: ref.watch(addAddressUseCaseProvider),
      updateAddressUseCase: ref.watch(updateAddressUseCaseProvider),
      deleteAddressUseCase: ref.watch(deleteAddressUseCaseProvider),
      setDefaultAddressUseCase: ref.watch(setDefaultAddressUseCaseProvider),
    );
  } catch (e) {
    debugPrint('addressesNotifierProvider: Error creating AddressesNotifier: $e');
    // Return a notifier with a mock implementation that shows an error
    return AddressesNotifier.withError('Failed to initialize address services. Please try again later.');
  }
});

// State for user profile
class UserProfileState {
  final UserProfile? userProfile;
  final bool isLoading;
  final String? error;

  UserProfileState({
    this.userProfile,
    required this.isLoading,
    this.error,
  });

  UserProfileState copyWith({
    UserProfile? userProfile,
    bool? isLoading,
    String? error,
  }) {
    return UserProfileState(
      userProfile: userProfile ?? this.userProfile,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Notifier for user profile
class UserProfileNotifier extends StateNotifier<AsyncValue<UserProfile?>> {
  final GetUserProfileUseCase _getUserProfileUseCase;

  UserProfileNotifier({
    required GetUserProfileUseCase getUserProfileUseCase,
  })  : _getUserProfileUseCase = getUserProfileUseCase,
        super(const AsyncValue.loading());

  Future<void> getUserProfile(String userId) async {
    state = const AsyncValue.loading();
    final result = await _getUserProfileUseCase(userId);
    result.fold(
      (failure) => state = AsyncValue.error(_mapFailureToMessage(failure), StackTrace.current),
      (userProfile) => state = AsyncValue.data(userProfile),
    );
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure && failure.message.isNotEmpty) {
      return failure.message;
    }

    switch (failure.runtimeType) {
      case ServerFailure:
        return 'Server error occurred';
      case NetworkFailure:
        return 'Network error occurred. Please check your connection.';
      case CacheFailure:
        return 'Cache error occurred';
      default:
        return 'An unexpected error occurred';
    }
  }
}

// Provider for the user profile notifier
final userProfileNotifierProvider = StateNotifierProvider<UserProfileNotifier, AsyncValue<UserProfile?>>((ref) {
  return UserProfileNotifier(
    getUserProfileUseCase: ref.watch(getUserProfileUseCaseProvider),
  );
});

// Provider for the selected address ID
final selectedAddressIdProvider = StateProvider<String?>((ref) {
  final addressesState = ref.watch(addressesNotifierProvider);
  return addressesState.maybeWhen(
    data: (addresses) {
      if (addresses.isEmpty) return null;

      // Try to find a default address first
      final defaultAddress = addresses.firstWhere(
        (address) => address.isDefault,
        orElse: () => addresses.first,
      );

      return defaultAddress.id;
    },
    orElse: () => null,
  );
});

// Provider to get the selected address
final selectedAddressProvider = Provider<Address?>((ref) {
  final selectedId = ref.watch(selectedAddressIdProvider);
  final addressesState = ref.watch(addressesNotifierProvider);

  return addressesState.maybeWhen(
    data: (addresses) {
      if (selectedId == null || addresses.isEmpty) return null;

      try {
        return addresses.firstWhere((address) => address.id == selectedId);
      } catch (_) {
        return null;
      }
    },
    orElse: () => null,
  );
});

// Provider to refresh addresses
extension AddressesNotifierExtension on AddressesNotifier {
  Future<void> refreshAddresses() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      await getAddresses(userId);
    }
  }
}