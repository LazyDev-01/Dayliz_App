# Dayliz App

A Q-commerce grocery delivery app with modern UI built with Flutter, following clean architecture principles.

## Features

- User Authentication (Login, Register, Forgot Password)
- Product Browsing and Search
- Category and Subcategory Navigation
- Shopping Cart and Checkout
- Order Management and Tracking
- Address Management
- User Profile and Preferences
- Wishlist Functionality

## Tech Stack

- Flutter for cross-platform development
- Clean Architecture for code organization
- Riverpod for State Management
- GetIt for Dependency Injection
- Go Router for Navigation
- Supabase for Backend Services
- Dartz for Functional Programming
- Equatable for Value Equality

## Setup Instructions

1. Clone this repository:
```bash
git clone https://github.com/LazyDev-01/Dayliz_App.git
```

2. Navigate to the project directory:
```bash
cd Dayliz_App
```

3. Install dependencies:
```bash
flutter pub get
```

4. Run the app:
```bash
flutter run
```

## Testing

For detailed testing instructions, please check [README_TESTING.md](README_TESTING.md).

## Screenshots

(Coming soon)

## Project Structure

### Clean Architecture Layers

- `lib/core`: Application-wide utilities and constants
  - `constants`: API endpoints, app constants
  - `errors`: Exception and failure handling
  - `utils`: Network info, validators, formatters

- `lib/domain`: Business logic layer
  - `entities`: Core business objects
  - `repositories`: Repository interfaces
  - `usecases`: Specific business operations

- `lib/data`: Data layer
  - `datasources`: Remote and local data sources
  - `models`: Data models extending domain entities
  - `repositories`: Repository implementations

- `lib/presentation`: UI layer
  - `providers`: State management
  - `screens`: UI screens
  - `widgets`: Reusable UI components

- `lib/di`: Dependency injection

### Additional Structure

- `lib/widgets`: Reusable UI components
- `lib/theme`: App theme and styling

## Clean Architecture Implementation

The project has been fully migrated to clean architecture:

- ✅ Overall Structure: 100% complete
- ✅ Domain Layer: 100% complete
- ✅ Data Layer: 100% complete
- ✅ Presentation Layer: 100% complete
- ✅ Core Layer: 100% complete

The application now follows clean architecture principles with clear separation of concerns and dependency inversion.

## License

MIT

## Author

[LazyDev-01](https://github.com/LazyDev-01)

## Database Schema Alignment

The clean architecture migration includes database schema alignment to ensure consistency between domain entities and the Supabase database. This phase has been completed (100%). Key features implemented:

- Entity-table mapping for all domain models
- Database view creation for efficient data access
- Migration scripts for schema updates
- Row Level Security (RLS) policy implementations
- Performance optimizations (indexes, materialized views)
- Full-text search capabilities
- Geospatial query support
- Real-time notification system

See [Database Schema Alignment](./docs/database/database_schema_alignment_updated.md) for complete documentation.

## Backend Integration Strategy

The app implements a dual backend strategy:

### Supabase Integration (Primary)

- Currently being implemented as the primary backend
- Data source implementations for each entity using Supabase client
- Row Level Security (RLS) policies for data protection
- Clean mapping between Supabase responses and domain entities

### FastAPI Backend (Future)

- Planned as an alternative backend option
- Will be enabled 2-3 months after initial launch
- HTTP-based implementations for all data sources
- Consistent API endpoints for all entities

The architecture allows switching between backends through dependency injection:

```dart
// Using the factory pattern to get the appropriate data source
final cartDataSource = CartDataSourceFactory.getDataSource();
final cartItems = await cartDataSource.getCartItems();
```

## Remaining Work

See [Remaining Screens Implementation](./docs/remaining_screens_implementation.md) for details on screens yet to be implemented.
