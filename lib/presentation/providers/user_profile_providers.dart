import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import '../../core/errors/failures.dart';
import '../../core/errors/exceptions.dart';
import '../../core/network/network_info.dart';
import '../../di/dependency_injection.dart' as di;
import '../../domain/entities/user_profile.dart';
import '../../domain/usecases/user_profile/get_user_profile_usecase.dart';
import '../../domain/usecases/upload_profile_image_usecase.dart';
import '../../domain/usecases/update_preferences_usecase.dart';
import '../../domain/repositories/user_profile_repository.dart';
import '../providers/auth_providers.dart';
import '../../data/datasources/user_profile_datasource.dart';
import '../../data/models/user_profile_model.dart';
import '../../domain/entities/address.dart';
import '../../domain/usecases/user_profile/add_address_usecase.dart';
import '../../domain/usecases/user_profile/delete_address_usecase.dart';
import '../../domain/usecases/user_profile/get_user_addresses_usecase.dart';
import '../../domain/usecases/user_profile/set_default_address_usecase.dart';
import '../../domain/usecases/user_profile/update_address_usecase.dart';
import '../../domain/usecases/user_profile/update_user_profile_usecase.dart';
import '../services/supabase_client.dart';
import 'network_providers.dart';

/// State for user profile
class UserProfileState extends Equatable {
  final bool isLoading;
  final UserProfile? profile;
  final String? errorMessage;
  final bool isImageUploading;
  final bool isAddressesLoading;
  final List<Address>? addresses;
  final String? addressErrorMessage;

  const UserProfileState({
    this.isLoading = false,
    this.profile,
    this.errorMessage,
    this.isImageUploading = false,
    this.isAddressesLoading = false,
    this.addresses,
    this.addressErrorMessage,
  });

  /// Create a copy of this state with updated fields
  UserProfileState copyWith({
    bool? isLoading,
    UserProfile? profile,
    String? errorMessage,
    bool clearError = false,
    bool? isImageUploading,
    bool? isAddressesLoading,
    List<Address>? addresses,
    String? addressErrorMessage,
    bool clearAddressError = false,
  }) {
    return UserProfileState(
      isLoading: isLoading ?? this.isLoading,
      profile: profile ?? this.profile,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      isImageUploading: isImageUploading ?? this.isImageUploading,
      isAddressesLoading: isAddressesLoading ?? this.isAddressesLoading,
      addresses: addresses ?? this.addresses,
      addressErrorMessage: clearAddressError ? null : addressErrorMessage ?? this.addressErrorMessage,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        profile,
        errorMessage,
        isImageUploading,
        isAddressesLoading,
        addresses,
        addressErrorMessage,
      ];
}

/// Notifier for managing user profile state
class UserProfileNotifier extends StateNotifier<UserProfileState> {
  final GetUserProfileUseCase getUserProfileUseCase;
  final UpdateUserProfileUseCase updateUserProfileUseCase;
  final UploadProfileImageUseCase uploadProfileImageUseCase;
  final GetUserAddressesUseCase getUserAddressesUseCase;
  final AddAddressUseCase addAddressUseCase;
  final UpdateAddressUseCase updateAddressUseCase;
  final DeleteAddressUseCase deleteAddressUseCase;
  final SetDefaultAddressUseCase setDefaultAddressUseCase;
  final UpdatePreferencesUseCase updatePreferencesUseCase;
  final Ref ref;

  UserProfileNotifier({
    required this.getUserProfileUseCase,
    required this.updateUserProfileUseCase,
    required this.uploadProfileImageUseCase,
    required this.getUserAddressesUseCase,
    required this.addAddressUseCase,
    required this.updateAddressUseCase,
    required this.deleteAddressUseCase,
    required this.setDefaultAddressUseCase,
    required this.updatePreferencesUseCase,
    required this.ref,
  }) : super(const UserProfileState());

  /// Load user profile
  Future<void> loadUserProfile(String userId) async {
    debugPrint('UserProfileNotifier: Loading profile for user ID: $userId');
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await getUserProfileUseCase(userId);

    result.fold(
      (failure) {
        debugPrint('UserProfileNotifier: Failed to load profile: ${_mapFailureToMessage(failure)}');
        state = state.copyWith(
          isLoading: false,
          errorMessage: _mapFailureToMessage(failure),
        );
      },
      (profile) {
        debugPrint('UserProfileNotifier: Profile loaded successfully');
        debugPrint('UserProfileNotifier: Profile data - fullName: ${profile.fullName}, gender: ${profile.gender}');
        state = state.copyWith(
          isLoading: false,
          profile: profile,
        );
      },
    );
  }

  /// Update user profile
  Future<void> updateProfile(UserProfile profile) async {
    state = state.copyWith(isLoading: true, clearError: true);

    // Ensure the profile's fullName is synchronized with the User's name
    final currentUser = ref.read(currentUserProvider);
    UserProfile profileToUpdate = profile;

    if (currentUser != null && (profile.fullName == null || profile.fullName!.isEmpty)) {
      debugPrint('UserProfileNotifier: Synchronizing profile fullName with user name: ${currentUser.name}');
      profileToUpdate = profile.copyWith(fullName: currentUser.name);
    }

    final result = await updateUserProfileUseCase(UpdateUserProfileParams(profile: profileToUpdate));

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: _mapFailureToMessage(failure),
      ),
      (updatedProfile) => state = state.copyWith(
        isLoading: false,
        profile: updatedProfile,
      ),
    );
  }

  /// Upload profile image
  Future<void> uploadProfileImage(String userId, String imagePath) async {
    state = state.copyWith(isImageUploading: true, clearError: true);

    final result = await uploadProfileImageUseCase(
      UploadProfileImageParams(userId: userId, imagePath: imagePath),
    );

    result.fold(
      (failure) => state = state.copyWith(
        isImageUploading: false,
        errorMessage: _mapFailureToMessage(failure),
      ),
      (imageUrl) {
        // If profile exists, update it with the new image URL
        if (state.profile != null) {
          final updatedProfile = state.profile!.copyWith(
            profileImageUrl: imageUrl,
          );

          state = state.copyWith(
            isImageUploading: false,
            profile: updatedProfile,
          );
        } else {
          state = state.copyWith(isImageUploading: false);
        }
      },
    );
  }

  /// Load user addresses
  Future<void> loadAddresses(String userId) async {
    state = state.copyWith(isAddressesLoading: true, clearAddressError: true);

    final result = await getUserAddressesUseCase(GetUserAddressesParams(userId: userId));

    result.fold(
      (failure) => state = state.copyWith(
        isAddressesLoading: false,
        addressErrorMessage: _mapFailureToMessage(failure),
      ),
      (addresses) => state = state.copyWith(
        isAddressesLoading: false,
        addresses: addresses,
      ),
    );
  }

  /// Add a new address
  Future<void> addAddress(String userId, Address address) async {
    state = state.copyWith(isAddressesLoading: true, clearAddressError: true);

    final result = await addAddressUseCase(
      AddAddressParams(userId: userId, address: address),
    );

    result.fold(
      (failure) => state = state.copyWith(
        isAddressesLoading: false,
        addressErrorMessage: _mapFailureToMessage(failure),
      ),
      (newAddress) {
        final updatedAddresses = List<Address>.from(state.addresses ?? []);
        updatedAddresses.add(newAddress);

        // If this is the default address, update other addresses
        if (newAddress.isDefault) {
          for (var i = 0; i < updatedAddresses.length - 1; i++) {
            if (updatedAddresses[i].isDefault) {
              updatedAddresses[i] = updatedAddresses[i].copyWith(isDefault: false);
            }
          }
        }

        state = state.copyWith(
          isAddressesLoading: false,
          addresses: updatedAddresses,
        );
      },
    );
  }

  /// Update an existing address
  Future<void> updateAddress(String userId, Address address) async {
    state = state.copyWith(isAddressesLoading: true, clearAddressError: true);

    final result = await updateAddressUseCase(
      UpdateAddressParams(userId: userId, address: address),
    );

    result.fold(
      (failure) => state = state.copyWith(
        isAddressesLoading: false,
        addressErrorMessage: _mapFailureToMessage(failure),
      ),
      (updatedAddress) {
        if (state.addresses != null) {
          final updatedAddresses = List<Address>.from(state.addresses!);
          final index = updatedAddresses.indexWhere((a) => a.id == updatedAddress.id);

          if (index != -1) {
            updatedAddresses[index] = updatedAddress;

            // If this address is now the default, update other addresses
            if (updatedAddress.isDefault) {
              for (var i = 0; i < updatedAddresses.length; i++) {
                if (i != index && updatedAddresses[i].isDefault) {
                  updatedAddresses[i] = updatedAddresses[i].copyWith(isDefault: false);
                }
              }
            }
          }

          state = state.copyWith(
            isAddressesLoading: false,
            addresses: updatedAddresses,
          );
        } else {
          state = state.copyWith(isAddressesLoading: false);
        }
      },
    );
  }

  /// Delete an address
  Future<void> deleteAddress(String userId, String addressId) async {
    state = state.copyWith(isAddressesLoading: true, clearAddressError: true);

    final result = await deleteAddressUseCase(
      DeleteAddressParams(userId: userId, addressId: addressId),
    );

    result.fold(
      (failure) => state = state.copyWith(
        isAddressesLoading: false,
        addressErrorMessage: _mapFailureToMessage(failure),
      ),
      (success) {
        if (state.addresses != null) {
          final updatedAddresses = state.addresses!
              .where((address) => address.id != addressId)
              .toList();

          state = state.copyWith(
            isAddressesLoading: false,
            addresses: updatedAddresses,
          );
        } else {
          state = state.copyWith(isAddressesLoading: false);
        }
      },
    );
  }

  /// Set an address as default
  Future<void> setDefaultAddress(String userId, String addressId) async {
    state = state.copyWith(isAddressesLoading: true, clearAddressError: true);

    final result = await setDefaultAddressUseCase(
      SetDefaultAddressParams(userId: userId, addressId: addressId),
    );

    result.fold(
      (failure) => state = state.copyWith(
        isAddressesLoading: false,
        addressErrorMessage: _mapFailureToMessage(failure),
      ),
      (success) {
        if (state.addresses != null) {
          final updatedAddresses = state.addresses!.map((address) {
            return address.copyWith(isDefault: address.id == addressId);
          }).toList();

          state = state.copyWith(
            isAddressesLoading: false,
            addresses: updatedAddresses,
          );
        } else {
          state = state.copyWith(isAddressesLoading: false);
        }
      },
    );
  }

  /// Update user preferences
  Future<void> updateUserPreferences(String userId, Map<String, dynamic> preferences) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await updatePreferencesUseCase(
      UpdatePreferencesParams(userId: userId, preferences: preferences),
    );

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: _mapFailureToMessage(failure),
      ),
      (updatedPreferences) {
        // If we have a profile, update it with the new preferences
        if (state.profile != null) {
          final updatedProfile = state.profile!.copyWith(
            preferences: updatedPreferences,
            lastUpdated: DateTime.now(),
          );

          state = state.copyWith(
            isLoading: false,
            profile: updatedProfile,
          );
        } else {
          state = state.copyWith(isLoading: false);
        }
      },
    );
  }

  /// Helper method to map failure to message
  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return failure.message ?? 'Server error occurred';
      case NetworkFailure:
        return 'Network connection error. Please check your internet connection.';
      case CacheFailure:
        return failure.message ?? 'Cache error occurred';
      default:
        return 'Unexpected error occurred';
    }
  }
}

/// Repository provider - temporary implementation for testing
final userProfileRepositoryProvider = Provider<UserProfileRepository>(
  (ref) => TempUserProfileRepositoryImpl(
    remoteDataSource: ref.read(userProfileDataSourceProvider),
    networkInfo: ref.read(networkInfoProvider),
  ),
);

/// A temporary repository implementation that doesn't rely on the local data source
class TempUserProfileRepositoryImpl implements UserProfileRepository {
  final UserProfileDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  TempUserProfileRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, UserProfile>> getUserProfile(String userId) async {
    if (await networkInfo.isConnected) {
      try {
        final userProfile = await remoteDataSource.getUserProfile(userId);
        return Right(userProfile);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<Address>>> getUserAddresses(String userId) async {
    if (await networkInfo.isConnected) {
      try {
        final addresses = await remoteDataSource.getUserAddresses(userId);
        return Right(addresses);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, Address>> addAddress(String userId, Address address) async {
    if (await networkInfo.isConnected) {
      try {
        final newAddress = await remoteDataSource.addAddress(userId, address);
        return Right(newAddress);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, Address>> updateAddress(String userId, Address address) async {
    if (await networkInfo.isConnected) {
      try {
        final updatedAddress = await remoteDataSource.updateAddress(userId, address);
        return Right(updatedAddress);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteAddress(String userId, String addressId) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.deleteAddress(userId, addressId);
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, bool>> setDefaultAddress(String userId, String addressId) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.setDefaultAddress(userId, addressId);
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, UserProfile>> updateUserProfile(UserProfile profile) async {
    if (await networkInfo.isConnected) {
      try {
        // Convert to UserProfileModel
        final profileModel = UserProfileModel(
          id: profile.id,
          userId: profile.userId,
          fullName: profile.fullName,
          profileImageUrl: profile.profileImageUrl,
          dateOfBirth: profile.dateOfBirth,
          gender: profile.gender,
          lastUpdated: profile.lastUpdated,
          preferences: profile.preferences,
        );

        final updatedProfile = await remoteDataSource.updateUserProfile(profileModel);
        return Right(updatedProfile);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(const NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, String>> updateProfileImage(String userId, File imageFile) async {
    if (await networkInfo.isConnected) {
      try {
        final imagePath = await remoteDataSource.updateProfileImage(userId, imageFile);
        return Right(imagePath);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(const NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteProfileImage(String userId) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.deleteProfileImage(userId);
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(const NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> updateUserPreferences(
    String userId,
    Map<String, dynamic> preferences,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.updatePreferences(userId, preferences);
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(const NetworkFailure(message: 'No internet connection'));
    }
  }
}

/// Data source provider
final userProfileDataSourceProvider = Provider<UserProfileDataSource>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return UserProfileDataSourceImpl(client: supabaseClient);
});

/// Use case providers
final getUserProfileUseCaseProvider = Provider(
  (ref) => GetUserProfileUseCase(ref.watch(userProfileRepositoryProvider)),
);

final updateUserProfileUseCaseProvider = Provider(
  (ref) => UpdateUserProfileUseCase(ref.watch(userProfileRepositoryProvider)),
);

final uploadProfileImageUseCaseProvider = Provider(
  (ref) => di.sl<UploadProfileImageUseCase>(),
);

final getUserAddressesUseCaseProvider = Provider(
  (ref) => GetUserAddressesUseCase(ref.watch(userProfileRepositoryProvider)),
);

final addAddressUseCaseProvider = Provider(
  (ref) => AddAddressUseCase(ref.watch(userProfileRepositoryProvider)),
);

final updateAddressUseCaseProvider = Provider(
  (ref) => UpdateAddressUseCase(ref.watch(userProfileRepositoryProvider)),
);

final deleteAddressUseCaseProvider = Provider(
  (ref) => DeleteAddressUseCase(ref.watch(userProfileRepositoryProvider)),
);

final setDefaultAddressUseCaseProvider = Provider(
  (ref) => SetDefaultAddressUseCase(ref.watch(userProfileRepositoryProvider)),
);

final updatePreferencesUseCaseProvider = Provider(
  (ref) => di.sl<UpdatePreferencesUseCase>(),
);

/// Main provider for user profile
final userProfileNotifierProvider = StateNotifierProvider<UserProfileNotifier, UserProfileState>(
  (ref) => UserProfileNotifier(
    getUserProfileUseCase: ref.watch(getUserProfileUseCaseProvider),
    updateUserProfileUseCase: ref.watch(updateUserProfileUseCaseProvider),
    uploadProfileImageUseCase: ref.watch(uploadProfileImageUseCaseProvider),
    getUserAddressesUseCase: ref.watch(getUserAddressesUseCaseProvider),
    addAddressUseCase: ref.watch(addAddressUseCaseProvider),
    updateAddressUseCase: ref.watch(updateAddressUseCaseProvider),
    deleteAddressUseCase: ref.watch(deleteAddressUseCaseProvider),
    setDefaultAddressUseCase: ref.watch(setDefaultAddressUseCaseProvider),
    updatePreferencesUseCase: ref.watch(updatePreferencesUseCaseProvider),
    ref: ref,
  ),
);

/// Convenience providers for accessing state
final userProfileProvider = Provider<UserProfile?>(
  (ref) => ref.watch(userProfileNotifierProvider).profile,
);

final userAddressesProvider = Provider<List<Address>?>(
  (ref) => ref.watch(userProfileNotifierProvider).addresses,
);

final defaultAddressProvider = Provider<Address?>(
  (ref) {
    final addresses = ref.watch(userAddressesProvider);
    if (addresses != null && addresses.isNotEmpty) {
      return addresses.firstWhere(
        (address) => address.isDefault,
        orElse: () => addresses.first,
      );
    }
    return null;
  },
);

/// Auto-load user profile when authenticated
final autoLoadUserProfileProvider = Provider<void>(
  (ref) {
    final authState = ref.watch(authStateProvider);

    ref.listen(authStateProvider, (previous, current) {
      if (current.isAuthenticated && current.user != null &&
          (previous == null || !previous.isAuthenticated || previous.user == null)) {
        ref.read(userProfileNotifierProvider.notifier).loadUserProfile(current.user!.id);
      }
    });

    if (authState.isAuthenticated && authState.user != null) {
      Future.microtask(() {
        ref.read(userProfileNotifierProvider.notifier).loadUserProfile(authState.user!.id);
      });
    }

    return;
  },
);

