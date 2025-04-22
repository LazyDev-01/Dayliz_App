import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../../domain/entities/address.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_profile_repository.dart';
import '../../domain/usecases/user_profile/get_user_addresses_usecase.dart';
import '../../domain/usecases/user_profile/add_address_usecase.dart';
import '../../domain/usecases/user_profile/update_address_usecase.dart';
import '../../domain/usecases/user_profile/delete_address_usecase.dart';
import '../../domain/usecases/user_profile/set_default_address_usecase.dart';
import '../../domain/usecases/user_profile/get_user_profile_usecase.dart';
import '../../di/dependency_injection.dart';

// Provider for the current user ID (this would normally come from auth)
final currentUserIdProvider = StateProvider<String?>((ref) {
  // For testing, return a dummy user ID
  return 'test-user-123';
});

// Provider for the user profile repository
final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  return sl<UserProfileRepository>();
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
  final GetUserAddressesUseCase _getUserAddressesUseCase;
  final AddAddressUseCase _addAddressUseCase;
  final UpdateAddressUseCase _updateAddressUseCase;
  final DeleteAddressUseCase _deleteAddressUseCase;
  final SetDefaultAddressUseCase _setDefaultAddressUseCase;

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
        super(const AsyncValue.loading());

  Future<void> getAddresses(String userId) async {
    state = const AsyncValue.loading();
    final result = await _getUserAddressesUseCase(GetUserAddressesParams(userId: userId));
    result.fold(
      (failure) => state = AsyncValue.error(_mapFailureToMessage(failure), StackTrace.current),
      (addresses) => state = AsyncValue.data(addresses),
    );
  }

  Future<void> addAddress(String userId, Address address) async {
    final result = await _addAddressUseCase(AddAddressParams(userId: userId, address: address));
    result.fold(
      (failure) => throw Exception(_mapFailureToMessage(failure)),
      (newAddress) {
        final currentAddresses = state.value ?? [];
        state = AsyncValue.data([...currentAddresses, newAddress]);
      },
    );
  }

  Future<void> updateAddress(String userId, Address address) async {
    final result = await _updateAddressUseCase(UpdateAddressParams(userId: userId, address: address));
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
  }

  Future<void> deleteAddress(String userId, String addressId) async {
    final result = await _deleteAddressUseCase(DeleteAddressParams(userId: userId, addressId: addressId));
    result.fold(
      (failure) => throw Exception(_mapFailureToMessage(failure)),
      (success) {
        if (success) {
          final currentAddresses = state.value ?? [];
          final updatedAddresses = currentAddresses.where((a) => a.id != addressId).toList();
          state = AsyncValue.data(updatedAddresses);
        }
      },
    );
  }

  Future<void> setDefaultAddress(String userId, String addressId) async {
    final result = await _setDefaultAddressUseCase(SetDefaultAddressParams(userId: userId, addressId: addressId));
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
  }

  String _mapFailureToMessage(Failure failure) {
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
  return AddressesNotifier(
    getUserAddressesUseCase: ref.watch(getUserAddressesUseCaseProvider),
    addAddressUseCase: ref.watch(addAddressUseCaseProvider),
    updateAddressUseCase: ref.watch(updateAddressUseCaseProvider),
    deleteAddressUseCase: ref.watch(deleteAddressUseCaseProvider),
    setDefaultAddressUseCase: ref.watch(setDefaultAddressUseCaseProvider),
  );
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