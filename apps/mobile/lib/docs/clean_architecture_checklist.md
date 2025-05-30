# Clean Architecture Implementation Checklist

Use this checklist when implementing new features in the Dayliz application to ensure adherence to clean architecture principles.

## Domain Layer

### Entity Creation
- [ ] Create entity class in `lib/domain/entities/`
- [ ] Define all required properties as `final`
- [ ] Implement `copyWith()` method for immutability
- [ ] Implement equality and hash code
- [ ] Ensure entity contains no dependencies on external packages except for core Dart/Flutter

### Repository Interface
- [ ] Define repository interface in `lib/domain/repositories/`
- [ ] Declare methods with appropriate return types using `Either<Failure, T>`
- [ ] Document method parameters and return values
- [ ] Ensure methods are focused on business operations, not technical details

### Use Cases
- [ ] Create separate use case class for each business operation
- [ ] Place in `lib/domain/usecases/`
- [ ] Implement `call()` method to make the class callable
- [ ] Inject repository dependency via constructor
- [ ] Keep use cases focused on a single responsibility

## Data Layer

### Data Source Interfaces
- [ ] Create data source interface in `lib/data/datasources/`
- [ ] Define methods that return entity types (not models)
- [ ] Include both remote and local data source interfaces if needed
- [ ] Document expected exceptions

### Models
- [ ] Create model classes in `lib/data/models/`
- [ ] Extend or implement corresponding domain entities
- [ ] Implement `fromJson()` and `toJson()` methods
- [ ] Include proper error handling in parsing methods
- [ ] Keep models focused on data transformation, not business logic

### Repository Implementation
- [ ] Implement repository in `lib/data/repositories/`
- [ ] Inject required data sources and network info
- [ ] Handle network connectivity checks
- [ ] Implement proper error handling with appropriate Failures
- [ ] Cache remote data locally when appropriate
- [ ] Return domain entities to higher layers, not models

## Presentation Layer

### State Management
- [ ] Define state classes/enums in `lib/presentation/bloc/` or `lib/presentation/cubit/`
- [ ] Include states for loading, success, and error cases
- [ ] Make state classes immutable (preferably using Equatable)

### BLoC/Cubit
- [ ] Create BLoC/Cubit in `lib/presentation/bloc/` or `lib/presentation/cubit/`
- [ ] Inject required use cases via constructor
- [ ] Implement event handlers or methods for user interactions
- [ ] Emit appropriate states based on use case results
- [ ] Handle errors and show meaningful messages to users

### UI Components
- [ ] Create widgets in `lib/presentation/widgets/`
- [ ] Create pages/screens in `lib/presentation/pages/`
- [ ] Use BLoC/Cubit for state management
- [ ] Separate presentation logic from UI
- [ ] Implement proper loading and error states in UI

## Core Layer

### Error Handling
- [ ] Define exceptions in `lib/core/error/exceptions.dart`
- [ ] Define failures in `lib/core/error/failures.dart`
- [ ] Include meaningful error messages

### Dependency Injection
- [ ] Register all dependencies in `lib/di/dependency_injection.dart`
- [ ] Group registrations by feature
- [ ] Register in correct order (data sources → repositories → use cases → BLoCs/Cubits)
- [ ] Use appropriate scope (lazySingleton, factory, etc.)

## Testing

### Unit Tests
- [ ] Test entities and models
- [ ] Test use cases
- [ ] Test repository implementations
- [ ] Test BLoCs/Cubits
- [ ] Mock dependencies using Mockito or other mocking libraries

### Integration Tests
- [ ] Test repository with real data sources
- [ ] Test complete feature flow

## Final Verification

- [ ] Ensure domain layer has no dependencies on data or presentation layers
- [ ] Verify data layer only depends on domain layer
- [ ] Check that presentation layer only depends on domain layer
- [ ] Confirm all exceptions are properly handled
- [ ] Validate that UI properly displays loading, success, and error states
- [ ] Run all tests and fix any failures 