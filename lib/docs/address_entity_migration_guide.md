# Address Entity Migration Guide

This guide demonstrates how to migrate the `Address` implementation in the Dayliz application to follow clean architecture principles correctly. It provides a step-by-step approach to refactor existing code to use the domain entity directly instead of relying on models across layers.

## Current Implementation Issues

Our codebase currently has these issues with Address implementation:

1. Multiple Address class implementations across different layers
2. Inconsistent property names and structures
3. Converting between entity and model unnecessarily
4. Data sources returning models instead of entities
5. Repositories relying on model implementations

## Migration Steps

### Step 1: Define the Domain Entity

The domain entity is the core business object that should be used by all layers:

```dart
// lib/domain/entities/address.dart
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Represents a user address entity
@immutable
class Address extends Equatable {
  /// Unique identifier for this address
  final String id;
  
  /// The user ID this address belongs to
  final String userId;
  
  /// First line of the address
  final String addressLine1;
  
  /// Second line of the address (optional)
  final String addressLine2;
  
  /// City name
  final String city;
  
  /// State or province
  final String state;
  
  /// Postal or ZIP code
  final String postalCode;
  
  /// Country name
  final String country;
  
  /// Phone number associated with this address
  final String? phoneNumber;
  
  /// Whether this is the default address
  final bool isDefault;
  
  /// A label for this address (e.g., "Home", "Work")
  final String label;
  
  /// Additional information about the address
  final String? additionalInfo;
  
  /// Geographic coordinates for this address
  final Map<String, double>? coordinates;

  /// Creates a new Address instance
  const Address({
    required this.id,
    required this.userId,
    required this.addressLine1,
    this.addressLine2 = '',
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    this.phoneNumber,
    this.isDefault = false,
    this.label = 'Home',
    this.additionalInfo,
    this.coordinates,
  });

  /// Creates a copy of this address with the given fields replaced with new values
  Address copyWith({
    String? id,
    String? userId,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    String? phoneNumber,
    bool? isDefault,
    String? label,
    String? additionalInfo,
    Map<String, double>? coordinates,
  }) {
    return Address(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isDefault: isDefault ?? this.isDefault,
      label: label ?? this.label,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      coordinates: coordinates ?? this.coordinates,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        addressLine1,
        addressLine2,
        city,
        state,
        postalCode,
        country,
        phoneNumber,
        isDefault,
        label,
        additionalInfo,
        coordinates,
      ];
}
```

### Step 2: Refactor the Model Class

The model should extend the entity and only add data-layer specific functionality:

```dart
// lib/data/models/address_model.dart
import 'package:dayliz_app/domain/entities/address.dart';

/// Model class for [Address] with additional functionality for the data layer
class AddressModel extends Address {
  const AddressModel({
    required String id,
    required String userId,
    required String addressLine1,
    String addressLine2 = '',
    required String city,
    required String state,
    required String postalCode,
    required String country,
    String? phoneNumber,
    bool isDefault = false,
    String label = 'Home',
    String? additionalInfo,
    Map<String, double>? coordinates,
  }) : super(
          id: id,
          userId: userId,
          addressLine1: addressLine1,
          addressLine2: addressLine2,
          city: city,
          state: state,
          postalCode: postalCode,
          country: country,
          phoneNumber: phoneNumber,
          isDefault: isDefault,
          label: label,
          additionalInfo: additionalInfo,
          coordinates: coordinates,
        );

  /// Factory constructor to create an [AddressModel] from a map (JSON)
  factory AddressModel.fromMap(Map<String, dynamic> map) {
    return AddressModel(
      id: map['id'],
      userId: map['user_id'] ?? '',
      addressLine1: map['address_line1'],
      addressLine2: map['address_line2'] ?? '',
      city: map['city'],
      state: map['state'],
      postalCode: map['postal_code'],
      country: map['country'],
      phoneNumber: map['phone_number'],
      isDefault: map['is_default'] ?? false,
      label: map['label'] ?? 'Home',
      additionalInfo: map['additional_info'],
      coordinates: map['coordinates'] != null
          ? Map<String, double>.from(map['coordinates'])
          : null,
    );
  }

  /// Convert this [AddressModel] to a map (JSON)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'address_line1': addressLine1,
      'address_line2': addressLine2,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'country': country,
      'phone_number': phoneNumber,
      'is_default': isDefault,
      'label': label,
      'additional_info': additionalInfo,
      'coordinates': coordinates,
    };
  }
  
  // For backward compatibility with existing code
  factory AddressModel.fromJson(Map<String, dynamic> json) => AddressModel.fromMap(json);
  Map<String, dynamic> toJson() => toMap();
}
```

### Step 3: Update DataSource Definitions

Data sources should return domain entities, not models. The data source is responsible for converting from raw data to entities:

```dart
// lib/data/datasources/user_profile_datasource.dart (interface)
abstract class UserProfileDataSource {
  /// Gets all addresses for the given [userId].
  /// 
  /// Throws a [ServerException] for all server errors.
  Future<List<Address>> getUserAddresses(String userId);
  
  /// Adds a new address for the user.
  /// 
  /// Throws a [ServerException] for all server errors.
  Future<Address> addAddress(String userId, Address address);
  
  /// Updates an existing address.
  /// 
  /// Throws a [ServerException] for all server errors.
  Future<Address> updateAddress(String userId, Address address);
  
  /// Deletes an address.
  /// 
  /// Throws a [ServerException] for all server errors.
  Future<bool> deleteAddress(String userId, String addressId);
  
  /// Sets an address as the default address.
  /// 
  /// Throws a [ServerException] for all server errors.
  Future<bool> setDefaultAddress(String userId, String addressId);
  
  // Other methods...
}
```

### Step 4: Update DataSource Implementation

The implementation should use the model internally for JSON conversions but return domain entities:

```dart
// lib/data/datasources/user_profile_datasource.dart (implementation)
@override
Future<List<Address>> getUserAddresses(String userId) async {
  try {
    final response = await client
        .from('addresses')
        .select()
        .eq('user_id', userId)
        .order('is_default', ascending: false);
    
    return (response as List).map((item) => AddressModel.fromMap(item)).toList();
  } catch (e) {
    throw ServerException(message: e.toString());
  }
}

@override
Future<Address> addAddress(String userId, Address address) async {
  try {
    // If this is the first address or marked as default, ensure it's set as default
    bool shouldBeDefault = address.isDefault;
    
    if (!shouldBeDefault) {
      // Check if user has any addresses
      final existingAddresses = await client
          .from('addresses')
          .select('id')
          .eq('user_id', userId);
          
      // If no addresses exist, make this the default
      if (existingAddresses.isEmpty) {
        shouldBeDefault = true;
      }
    }
    
    // If setting as default, reset any existing default addresses
    if (shouldBeDefault) {
      await client
          .from('addresses')
          .update({'is_default': false})
          .eq('user_id', userId)
          .eq('is_default', true);
    }
    
    // Create map from address to insert
    final Map<String, dynamic> data;
    if (address is AddressModel) {
      // If it's already a model, use its toMap method
      data = (address as AddressModel).toMap();
      // Override the is_default value
      data['is_default'] = shouldBeDefault;
    } else {
      // Otherwise create a map manually
      data = {
        'user_id': userId,
        'address_line1': address.addressLine1,
        'address_line2': address.addressLine2,
        'city': address.city,
        'state': address.state,
        'postal_code': address.postalCode,
        'country': address.country,
        'is_default': shouldBeDefault,
        'label': address.label,
        'phone_number': address.phoneNumber,
        'additional_info': address.additionalInfo,
        'coordinates': address.coordinates,
      };
    }
    
    final response = await client
        .from('addresses')
        .insert(data)
        .select()
        .single();
        
    return AddressModel.fromMap(response);
  } catch (e) {
    throw ServerException(message: e.toString());
  }
}

// Similar updates for updateAddress, deleteAddress, and setDefaultAddress
```

### Step 5: Update Repository Implementation

The repository implementation doesn't need to change much since it already returns domain entities. Just make sure no unnecessary type conversions are happening:

```dart
// lib/data/repositories/user_profile_repository_impl.dart
@override
Future<Either<Failure, Address>> addAddress(String userId, Address address) async {
  if (await networkInfo.isConnected) {
    try {
      final newAddress = await remoteDataSource.addAddress(userId, address);
      // Add to local cache
      await localDataSource.addAddress(userId, newAddress);
      return Right(newAddress);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  } else {
    try {
      // Add locally and queue for remote update when connection is restored
      final newAddress = await localDataSource.addAddress(userId, address);
      return Right(newAddress);
    } on ServerException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }
}

// Similar implementations for other Address-related methods
```

### Step 6: Add Extension Methods for Convenience

Add extension methods on the Address entity to make common operations easier:

```dart
// lib/domain/entities/address_extensions.dart
import 'package:dayliz_app/domain/entities/address.dart';

extension AddressExtensions on Address {
  /// Returns a formatted single-line version of the address
  String get formattedAddress {
    final parts = [
      addressLine1,
      if (addressLine2.isNotEmpty) addressLine2,
      city,
      state,
      postalCode,
      country,
    ];
    return parts.join(', ');
  }
  
  /// Returns a human-readable representation of the address
  String get displayAddress {
    final List<String> lines = [];
    
    lines.add(addressLine1);
    if (addressLine2.isNotEmpty) {
      lines.add(addressLine2);
    }
    lines.add('$city, $state $postalCode');
    lines.add(country);
    
    return lines.join('\n');
  }
  
  /// Returns just the city and state portion of the address
  String get cityState => '$city, $state';
}
```

### Step 7: Update UI Code

Update any UI code to use the Address entity directly instead of AddressModel. Example:

```dart
// Before
final AddressModel address = // ...
Text('Address: ${address.addressLine1}, ${address.city}');

// After
final Address address = // ...
Text('Address: ${address.addressLine1}, ${address.city}');
// Or using the extension
Text('Address: ${address.formattedAddress}');
```

### Step 8: Add Tests

Finally, add unit tests to verify the correct behavior of the Address entity and related components:

```dart
// test/domain/entities/address_test.dart
void main() {
  test('Address copyWith should create a new instance with updated fields', () {
    final address = Address(
      id: '1',
      userId: 'user1',
      addressLine1: '123 Main St',
      city: 'New York',
      state: 'NY',
      postalCode: '10001',
      country: 'USA',
    );
    
    final updatedAddress = address.copyWith(
      city: 'Boston',
      state: 'MA',
    );
    
    expect(updatedAddress.id, '1');
    expect(updatedAddress.addressLine1, '123 Main St');
    expect(updatedAddress.city, 'Boston');
    expect(updatedAddress.state, 'MA');
  });

  // More tests for other functionality
}
```

## Benefits of This Approach

1. **Simplified Code**: Domain entities are used directly across all layers
2. **Reduced Duplication**: Single source of truth for address data
3. **Type Safety**: Consistent types throughout the codebase
4. **Testability**: Easier to test with well-defined boundaries
5. **Maintainability**: Easier to add new features or modify existing ones

## Legacy Code Removal

Once the migration is complete and tested, you can remove the old Address model in `lib/models/address.dart` to avoid confusion.

Always ensure backward compatibility during the migration by maintaining the necessary interfaces and methods until all parts of the application have been updated to use the new approach. 