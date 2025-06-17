# Debug Module

This directory contains debug-only screens and utilities that should not be included in production builds.

## Structure

```
debug/
├── screens/           # Debug screens for testing features
├── utils/            # Debug utilities and helpers
├── widgets/          # Debug-specific widgets
└── README.md         # This file
```

## Usage

Debug screens are only available in debug builds and should be accessed through the debug menu.

## Important Notes

- These files should never be imported in production code
- Use conditional compilation or debug flags to ensure they're excluded from release builds
- All debug screens should be properly documented with their purpose and usage

## Debug Screens

- `debug_menu_screen.dart` - Main debug menu with links to all debug features
- `cart_dependency_test_screen.dart` - Test cart dependencies and state management
- `supabase_connection_test_screen.dart` - Test Supabase connectivity
- `google_maps_diagnostic_screen.dart` - Test Google Maps integration
- And more...

## Guidelines

1. Keep debug code separate from production code
2. Use clear naming conventions (prefix with `debug_` or `test_`)
3. Document the purpose of each debug screen
4. Remove or disable debug features before production release
