import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

import '../../core/errors/failures.dart';
import '../../core/errors/exceptions.dart';
import '../../core/network/network_info.dart';
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

  /// Reset loading state when needed
  void resetLoadingState() {
    debugPrint('UserProfileNotifier: Resetting loading state');
    state = state.copyWith(isLoading: false);
  }

  /// NOTE: Manual profile creation removed as database trigger handles this automatically
  /// The handle_new_user() trigger creates profiles when users sign up via Google Sign-In

  /// Load user profile with timeout
  Future<void> loadUserProfile(String userId) async {
    debugPrint('UserProfileNotifier: Loading profile for user ID: $userId');
    debugPrint('UserProfileNotifier: Current state - isLoading: ${state.isLoading}, hasProfile: ${state.profile != null}');

    // If already loading, don't start another load operation
    if (state.isLoading) {
      debugPrint('UserProfileNotifier: Already loading, skipping duplicate load request');
      return;
    }

    // Set loading state
    state = state.copyWith(isLoading: true, clearError: true);

    // Create a timeout to prevent infinite loading
    bool hasCompleted = false;
    Timer? timeoutTimer;

    timeoutTimer = Timer(const Duration(seconds: 10), () {
      if (!hasCompleted) {
        debugPrint('UserProfileNotifier: Loading profile timed out after 10 seconds');
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Loading profile timed out. Please try again.',
        );
        hasCompleted = true;
      }
    });

    try {
      debugPrint('UserProfileNotifier: Calling getUserProfileUseCase');
      final result = await getUserProfileUseCase(userId);

      // Cancel timeout timer since we got a response
      timeoutTimer.cancel();

      // If the timeout already triggered, don't update state again
      if (hasCompleted) {
        debugPrint('UserProfileNotifier: Request completed but timeout already triggered, ignoring result');
        return;
      }

      hasCompleted = true;
      debugPrint('UserProfileNotifier: getUserProfileUseCase returned ${result.isRight() ? "Right" : "Left"}');

      result.fold(
        (failure) {
          debugPrint('UserProfileNotifier: Failed to load profile: ${_mapFailureToMessage(failure)}');
          debugPrint('UserProfileNotifier: Failure type: ${failure.runtimeType}');
          debugPrint('UserProfileNotifier: Failure message: ${failure.message}');

          state = state.copyWith(
            isLoading: false,
            errorMessage: _mapFailureToMessage(failure),
          );
        },
        (profile) {
          debugPrint('UserProfileNotifier: Profile loaded successfully');
          debugPrint('UserProfileNotifier: Profile data - id: ${profile.id}, userId: ${profile.userId}');
          debugPrint('UserProfileNotifier: Profile data - fullName: ${profile.fullName}, gender: ${profile.gender}');
          debugPrint('UserProfileNotifier: Profile data - dateOfBirth: ${profile.dateOfBirth}, lastUpdated: ${profile.lastUpdated}');

          state = state.copyWith(
            isLoading: false,
            profile: profile,
          );

          debugPrint('UserProfileNotifier: State updated with profile');
        },
      );
    } catch (e, stackTrace) {
      // Cancel timeout timer since we got an error
      timeoutTimer.cancel();

      // If the timeout already triggered, don't update state again
      if (hasCompleted) return;

      hasCompleted = true;
      debugPrint('UserProfileNotifier: Unexpected error in loadUserProfile: $e');
      debugPrint('UserProfileNotifier: Stack trace: $stackTrace');

      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unexpected error: $e',
      );
    }

    debugPrint('UserProfileNotifier: loadUserProfile completed. isLoading: ${state.isLoading}, hasProfile: ${state.profile != null}');
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
        return failure.message.isNotEmpty ? failure.message : 'Server error occurred';
      case NetworkFailure:
        return 'Network connection error. Please check your internet connection.';
      case CacheFailure:
        return failure.message.isNotEmpty ? failure.message : 'Cache error occurred';
      default:
        return 'Unexpected error occurred';
    }
  }
}

/// Repository provider - uses the properly registered repository from the service locator
final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  try {
    // Get the repository from the service locator
    final repository = sl<UserProfileRepository>();
    debugPrint('UserProfileRepositoryProvider: Successfully retrieved repository from service locator');
    return repository;
  } catch (e) {
    // If there's an error getting the repository from the service locator,
    // log it and fall back to a temporary implementation
    debugPrint('UserProfileRepositoryProvider: Error retrieving repository from service locator: $e');
    debugPrint('UserProfileRepositoryProvider: Falling back to temporary implementation');

    return TempUserProfileRepositoryImpl(
      remoteDataSource: ref.read(userProfileDataSourceProvider),
      networkInfo: ref.read(networkInfoProvider),
    );
  }
});

/// A temporary repository implementation that doesn't rely on the local data source
/// Only used as a fallback if the service locator fails
class TempUserProfileRepositoryImpl implements UserProfileRepository {
  final UserProfileDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  TempUserProfileRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, UserProfile>> getUserProfile(String userId) async {
    debugPrint('TempUserProfileRepositoryImpl: Getting user profile for user ID: $userId');
    if (await networkInfo.isConnected) {
      try {
        debugPrint('TempUserProfileRepositoryImpl: Network connected, fetching from remote data source');
        final userProfile = await remoteDataSource.getUserProfile(userId);
        debugPrint('TempUserProfileRepositoryImpl: Successfully fetched user profile');
        return Right(userProfile as UserProfile);
      } on ServerException catch (e) {
        debugPrint('TempUserProfileRepositoryImpl: Server exception: ${e.message}');
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        debugPrint('TempUserProfileRepositoryImpl: Unexpected error: $e');
        return Left(ServerFailure(message: 'Unexpected error: $e'));
      }
    } else {
      debugPrint('TempUserProfileRepositoryImpl: No network connection');
      return Left(const NetworkFailure(message: 'No internet connection'));
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
      return Left(const NetworkFailure(message: 'No internet connection'));
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
      return Left(const NetworkFailure(message: 'No internet connection'));
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
      return Left(const NetworkFailure(message: 'No internet connection'));
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
      return Left(const NetworkFailure(message: 'No internet connection'));
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
        return Right(updatedProfile as UserProfile);
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

  @override
  Future<Either<Failure, bool>> deleteAddress(String userId, String addressId) async {
    debugPrint('TempUserProfileRepositoryImpl: Deleting address $addressId for user $userId');
    if (await networkInfo.isConnected) {
      try {
        debugPrint('TempUserProfileRepositoryImpl: Network connected, deleting from remote data source');

        // First check if the address is referenced by any orders
        try {
          final client = Supabase.instance.client;

          // Check if the address exists and belongs to the user
          final addressResponse = await client
              .from('addresses')
              .select('id, is_default')
              .eq('id', addressId)
              .eq('user_id', userId)
              .maybeSingle();

          if (addressResponse == null) {
            debugPrint('TempUserProfileRepositoryImpl: Address not found or does not belong to user');
            return const Left(ServerFailure(message: 'Address not found or does not belong to user'));
          }

          // Try to check if the address is referenced by any orders
          try {
            // Check for references in shipping_address_id or billing_address_id
            final ordersResponse = await client
                .from('information_schema.columns')
                .select('column_name')
                .eq('table_name', 'orders')
                .eq('table_schema', 'public');

            debugPrint('TempUserProfileRepositoryImpl: Orders table columns: $ordersResponse');

            final hasShippingAddressId =
                (ordersResponse as List<dynamic>).any((col) => col['column_name'] == 'shipping_address_id');

            final hasBillingAddressId =
                ordersResponse.any((col) => col['column_name'] == 'billing_address_id');

            if (hasShippingAddressId) {
              final shippingOrdersResponse = await client
                  .from('orders')
                  .select('id')
                  .eq('shipping_address_id', addressId)
                  .limit(1);

              if (shippingOrdersResponse.isNotEmpty) {
                debugPrint('TempUserProfileRepositoryImpl: Cannot delete address: It is used as shipping address in orders');
                return const Left(ServerFailure(
                  message: 'Cannot delete this address because it is used as a shipping address in one or more orders.'
                ));
              }
            }

            if (hasBillingAddressId) {
              final billingOrdersResponse = await client
                  .from('orders')
                  .select('id')
                  .eq('billing_address_id', addressId)
                  .limit(1);

              if (billingOrdersResponse.isNotEmpty) {
                debugPrint('TempUserProfileRepositoryImpl: Cannot delete address: It is used as billing address in orders');
                return const Left(ServerFailure(
                  message: 'Cannot delete this address because it is used as a billing address in one or more orders.'
                ));
              }
            }

            // Also check JSONB fields
            try {
              final jsonbOrdersResponse = await client
                  .from('orders')
                  .select('id')
                  .or('shipping_address->id.eq.$addressId,billing_address->id.eq.$addressId')
                  .limit(1);

              if (jsonbOrdersResponse.isNotEmpty) {
                debugPrint('TempUserProfileRepositoryImpl: Cannot delete address: It is used in orders JSONB fields');
                return const Left(ServerFailure(
                  message: 'Cannot delete this address because it is used in one or more orders.'
                ));
              }
            } catch (e) {
              debugPrint('TempUserProfileRepositoryImpl: Error checking JSONB fields: $e');
              // Continue if JSONB check fails
            }
          } catch (e) {
            debugPrint('TempUserProfileRepositoryImpl: Error checking orders table schema: $e');
            // Continue if schema check fails
          }
        } catch (e) {
          debugPrint('TempUserProfileRepositoryImpl: Error checking address references: $e');
          // Continue with deletion attempt
        }

        // Now try to delete the address
        final result = await remoteDataSource.deleteAddress(userId, addressId);
        debugPrint('TempUserProfileRepositoryImpl: Successfully deleted address');
        return Right(result);
      } on ServerException catch (e) {
        debugPrint('TempUserProfileRepositoryImpl: Server exception: ${e.message}');
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        debugPrint('TempUserProfileRepositoryImpl: Unexpected error: $e');
        return Left(ServerFailure(message: 'Unexpected error: $e'));
      }
    } else {
      debugPrint('TempUserProfileRepositoryImpl: No network connection');
      return const Left(NetworkFailure(message: 'No internet connection'));
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
  (ref) => UploadProfileImageUseCase(ref.watch(userProfileRepositoryProvider)),
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
  (ref) => UpdatePreferencesUseCase(ref.watch(userProfileRepositoryProvider)),
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
    debugPrint('autoLoadUserProfileProvider: Initializing');
    final authState = ref.watch(authNotifierProvider);

    debugPrint('autoLoadUserProfileProvider: Current auth state - isAuthenticated: ${authState.isAuthenticated}, hasUser: ${authState.user != null}');

    // Listen for changes in auth state
    ref.listen(authNotifierProvider, (previous, current) {
      debugPrint('autoLoadUserProfileProvider: Auth state changed');
      debugPrint('autoLoadUserProfileProvider: Previous state - isAuthenticated: ${previous?.isAuthenticated}, hasUser: ${previous?.user != null}');
      debugPrint('autoLoadUserProfileProvider: Current state - isAuthenticated: ${current.isAuthenticated}, hasUser: ${current.user != null}');

      // If user just became authenticated, load their profile
      if (current.isAuthenticated && current.user != null &&
          (previous == null || !previous.isAuthenticated || previous.user == null)) {
        debugPrint('autoLoadUserProfileProvider: User just authenticated, loading profile for user ID: ${current.user!.id}');

        // Check if we're already loading
        final profileState = ref.read(userProfileNotifierProvider);
        if (profileState.isLoading) {
          debugPrint('autoLoadUserProfileProvider: Already loading, resetting state first');
          ref.read(userProfileNotifierProvider.notifier).resetLoadingState();
        }

        // Load profile
        ref.read(userProfileNotifierProvider.notifier).loadUserProfile(current.user!.id);
      }
    });

    // If already authenticated, load profile
    if (authState.isAuthenticated && authState.user != null) {
      debugPrint('autoLoadUserProfileProvider: User already authenticated, scheduling profile load for user ID: ${authState.user!.id}');

      // Use a delayed future to avoid conflicts with other initialization
      Future.delayed(const Duration(milliseconds: 500), () {
        // Check if we're already loading
        final profileState = ref.read(userProfileNotifierProvider);
        if (profileState.isLoading) {
          debugPrint('autoLoadUserProfileProvider: Already loading, resetting state first');
          ref.read(userProfileNotifierProvider.notifier).resetLoadingState();
        }

        debugPrint('autoLoadUserProfileProvider: Loading profile for user ID: ${authState.user!.id}');
        ref.read(userProfileNotifierProvider.notifier).loadUserProfile(authState.user!.id);
      });
    } else {
      debugPrint('autoLoadUserProfileProvider: User not authenticated, skipping profile load');
    }

    return;
  },
);

