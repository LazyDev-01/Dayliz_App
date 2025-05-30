# Data Type Migration Guide

This guide outlines the steps to resolve data type inconsistencies across the Dayliz application layers.

## Overview

We've identified inconsistencies in how data types are handled across:
- Flutter models
- FastAPI models
- Supabase/PostgreSQL database

This guide provides a step-by-step approach to standardize data types and ensure consistency.

## Migration Steps

### 1. Update Database Schema

First, update the database schema to use standardized types:

```sql
-- Example for updating the orders table
ALTER TABLE orders 
  ALTER COLUMN id TYPE UUID USING (uuid_generate_v4()),
  ALTER COLUMN total_price TYPE DECIMAL(10,2),
  RENAME COLUMN total_price TO total_amount;
```

Use the `updated_schema.sql` file as a reference for the target schema.

### 2. Update FastAPI Models

Update all FastAPI models to match the standardized types:

- Replace `Integer` primary keys with `UUID`
- Replace `Float` with `Numeric(10, 2)` for money values
- Ensure consistent field naming (e.g., `total_amount` not `total_price`)
- Use timezone-aware datetime fields

Example:
```python
from sqlalchemy.dialects.postgresql import UUID
import uuid

class Order(Base):
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    total_amount = Column(Numeric(10, 2))  # Not Float
```

### 3. Update Flutter Models

Update all Flutter models to use the type conversion utilities:

- Use `TypeConverters.toIdString()` for ID fields
- Use `TypeConverters.toPrice()` for monetary values
- Use `TypeConverters.toDateTime()` for date/time fields

Example:
```dart
factory Order.fromJson(Map<String, dynamic> json) {
  return Order(
    id: TypeConverters.toIdString(json['id']),
    totalAmount: TypeConverters.toPrice(json['total_amount']),
    createdAt: TypeConverters.toDateTime(json['created_at']) ?? DateTime.now(),
  );
}
```

### 4. Update API Schemas

Update all Pydantic schemas in FastAPI to match the new types:

```python
from pydantic import BaseModel
from decimal import Decimal
from datetime import datetime
from uuid import UUID

class OrderBase(BaseModel):
    total_amount: Decimal  # Not float
    user_id: UUID  # Not int or str
```

### 5. Testing Strategy

Test the migration in this order:

1. **Database Schema**: Apply changes to a test database first
2. **Backend Models**: Update and test FastAPI models against the new schema
3. **API Layer**: Test API endpoints with the updated models
4. **Flutter Models**: Update and test Flutter models with the API
5. **UI Layer**: Test the UI with the updated models

### 6. Rollout Plan

1. **Development Environment**: Apply all changes and test thoroughly
2. **Staging Environment**: Deploy and test with production-like data
3. **Production Migration**:
   - Schedule maintenance window
   - Backup database
   - Apply schema changes
   - Deploy updated backend
   - Deploy updated mobile app

## Common Issues and Solutions

### UUID Conversion

When converting from integer IDs to UUIDs:

```python
# In Python
from uuid import UUID
def int_to_uuid(int_id):
    return UUID(int=int_id)

# In SQL
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
UPDATE table SET id = uuid_generate_v4() WHERE id IS NOT NULL;
```

### Decimal Precision

When working with monetary values:

```python
# In Python
from decimal import Decimal
value = Decimal('123.45').quantize(Decimal('0.01'))

# In Dart
double value = (123.456 * 100).round() / 100;  // Rounds to 2 decimal places
```

### DateTime Timezone Handling

```python
# In Python
from datetime import datetime, timezone
dt = datetime.now(timezone.utc)

# In Dart
DateTime dt = DateTime.now().toUtc();
```

## Verification Checklist

- [ ] Database schema uses correct types
- [ ] FastAPI models match database schema
- [ ] Pydantic schemas match FastAPI models
- [ ] Flutter models use type converters
- [ ] API requests/responses use consistent types
- [ ] UI displays values correctly

## Resources

- [Data Type Standards Document](./data_type_standards.md)
- [Updated Database Schema](../Dayliz_App/docs/updated_schema.sql)
- [Flutter Type Converters](../Dayliz_App/lib/utils/type_converters.dart)
- [FastAPI Type Converters](../backend/app/utils/type_converters.py)
