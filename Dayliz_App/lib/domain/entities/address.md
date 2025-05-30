# Address Entity in Clean Architecture

## Overview

The `Address` entity is a core domain object in the Dayliz application, representing user addresses for shipping, billing, and other purposes. This entity is implemented following Clean Architecture principles, which ensures:

1. The domain entity is independent from frameworks, UI, and databases
2. The entity contains pure business logic with no dependencies on external resources
3. The entity can be used directly throughout the application to maintain data consistency

## Implementation Details

### Entity Structure

The `Address` entity contains the following properties:

- **id**: Unique identifier for the address
- **userId**: ID of the user this address belongs to
- **addressLine1**: Primary address line (street address)
- **addressLine2**: Secondary address line (apartment, suite, etc.) - optional
- **city**: City name
- **state**: State or province
- **postalCode**: Postal or ZIP code
- **country**: Country name
- **phoneNumber**: Contact phone number - optional
- **isDefault**: Flag indicating if this is the user's default address
- **label**: User-friendly label for the address (e.g., "Home", "Work")
- **additionalInfo**: Any additional delivery instructions - optional
- **coordinates**: Geographic coordinates for mapping - optional

### Clean Architecture Implementation

The `Address` entity follows these Clean Architecture principles:

1. **Domain-Centric**: The entity is defined in the domain layer and doesn't depend on any external frameworks or UI components.

2. **Direct Usage**: Unlike a traditional implementation with separate model and entity classes, the Dayliz app uses the `Address` entity directly throughout all layers:
   - Domain layer: Defines the entity and its business rules
   - Data layer: Uses the entity directly for data operations
   - Presentation layer: Displays and manipulates the entity

3. **Immutable Design**: The entity is immutable, with any changes creating a new instance through the `copyWith` method.

### Repository Pattern

The `UserProfileRepository` interface defines operations for managing addresses:

- `getUserAddresses`: Retrieves all addresses for a user
- `addAddress`: Adds a new address
- `updateAddress`: Updates an existing address
- `deleteAddress`: Removes an address
- `setDefaultAddress`: Sets an address as the default

The implementation (`UserProfileRepositoryImpl`) handles:
- Network connectivity checks
- Local caching of addresses
- Error handling with appropriate Failure types

### Data Sources

Both remote and local data sources are implemented to provide:
- Network data access with proper error handling
- Local caching for offline operation
- Consistent serialization/deserialization of Address entities

## Migration from Model/Entity Pattern

The Dayliz application initially used a dual structure:
- `Address` entity in the domain layer
- `AddressModel` in the data layer

This has been simplified to use just the `Address` entity throughout all layers, which:
- Reduces code duplication
- Eliminates unnecessary mapping between models and entities
- Provides a consistent data structure across the entire application
- Simplifies testing and maintenance

## Usage Guidelines

When working with the `Address` entity:

1. Always use the entity directly in repositories and data sources
2. Use the `copyWith` method to create modified instances
3. For serialization/deserialization:
   - Convert to/from JSON maps directly using the entity's properties
   - Follow the naming conventions in the documentation for JSON field names

## Example Usage

```dart
// Creating a new address
final address = Address(
  id: '',  // Will be generated on save
  userId: currentUserId,
  addressLine1: '123 Main St',
  city: 'Anytown',
  state: 'CA',
  postalCode: '12345',
  country: 'USA',
  label: 'Home',
  isDefault: true,
);

// Updating an address
final updatedAddress = address.copyWith(
  addressLine1: '456 Oak Ave',
  label: 'Work',
);

// Adding to repository
final result = await userProfileRepository.addAddress(userId, address);

// Setting as default
await userProfileRepository.setDefaultAddress(userId, address.id);
``` 