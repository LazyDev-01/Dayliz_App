# Dayliz App

A Q-commerce grocery delivery app with modern UI built with Flutter.

## Features

- User Authentication
- Product Browsing
- Shopping Cart
- Checkout Process
- Order Confirmation
- Address Management

## Tech Stack

- Flutter
- Riverpod for State Management
- Go Router for Navigation
- SharedPreferences for Local Storage

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

- `lib/models`: Data models
- `lib/providers`: State management
- `lib/screens`: UI screens
- `lib/widgets`: Reusable UI components
- `lib/theme`: App theme and styling

## License

MIT

## Author

[LazyDev-01](https://github.com/LazyDev-01)

## Database Schema Alignment

The clean architecture migration includes database schema alignment to ensure consistency between domain entities and the Supabase database. Key features include:

- Entity-table mapping for all domain models
- Database view creation for efficient data access
- Version tracking with the `clean_architecture_versions` table
- Row Level Security (RLS) policy implementations

See [Database Schema Alignment](./docs/database_schema_alignment.md) for complete documentation.

## Backend Integration

The app includes multiple backend options:

### Supabase Integration

- Data source implementations for each entity using Supabase client
- Factory pattern to select correct backend implementation at runtime
- Row Level Security (RLS) policies for data protection
- Clean mapping between Supabase responses and domain entities

Example usage:

```dart
// Using the Cart data source with Supabase
final cartDataSource = CartDataSourceFactory.getSupabaseDataSource();
final cartItems = await cartDataSource.getCartItems();
```

### FastAPI Backend (Alternative)

- HTTP-based implementations for all data sources
- Consistent API endpoints for all entities
