# Dayliz Data Type Standards

This document defines the standard data types to be used across all layers of the Dayliz application.

## Core Data Types

| Concept | Supabase/PostgreSQL | FastAPI/SQLAlchemy | Flutter/Dart | JSON Representation |
|---------|---------------------|---------------------|--------------|---------------------|
| **Identifiers** | `UUID` | `String` | `String` | String |
| **Money/Price** | `DECIMAL(10, 2)` | `Decimal` | `double` | Number with 2 decimal places |
| **Integer Counts** | `INTEGER` | `Integer` | `int` | Number (integer) |
| **Text** | `TEXT` | `String` | `String` | String |
| **Boolean** | `BOOLEAN` | `Boolean` | `bool` | Boolean |
| **Date** | `DATE` | `date` | `DateTime` | ISO-8601 date string (YYYY-MM-DD) |
| **DateTime** | `TIMESTAMP WITH TIME ZONE` | `datetime` | `DateTime` | ISO-8601 datetime string |
| **Enums** | Custom ENUM type | String with validators | Enum class | String |
| **JSON/Maps** | `JSONB` | `Dict` / JSON field | `Map<String, dynamic>` | JSON object |
| **Arrays** | Array types | `List` | `List<T>` | JSON array |

## Type Conversion Rules

### Identifiers
- All IDs should be UUIDs stored as strings
- In Flutter: Use `String` type for all IDs
- In FastAPI: Use `String` type with UUID validation
- In Supabase: Use `UUID` type with `uuid_generate_v4()` defaults

### Money/Price Values
- Store as `DECIMAL(10, 2)` in the database
- Use `Decimal` from `decimal` module in Python
- Use `double` in Dart with appropriate rounding for display
- Always round to 2 decimal places for display
- Always use explicit conversion when handling money values

### Date and Time
- Store all timestamps with timezone information
- Use UTC for all server-side operations
- Convert to local time only for display purposes
- Use ISO-8601 format for all string representations
- Include timezone information in all datetime strings

### Enums
- Define as proper ENUM types in the database
- Use string constants with validators in FastAPI
- Use Enum classes with fromString/toString methods in Flutter
- Document all possible values in this standards document

## Implementation Guidelines

1. When creating new models, refer to this document
2. When modifying existing models, update toward these standards
3. Add appropriate conversion in service layers when necessary
4. Include validation to ensure data integrity across boundaries
5. Update this document when new data types are introduced

## Appendix: Enum Values

### OrderStatus
- `pending`
- `processing`
- `shipped`
- `delivered`
- `cancelled`

### PaymentStatus
- `pending`
- `completed`
- `failed`
- `refunded`

### PaymentMethod
- `creditCard`
- `wallet`
- `cashOnDelivery`
- `upi`
