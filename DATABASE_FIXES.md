# Database Query Fixes

## Issues Fixed

### 1. PostgreSQL Join Error
**Error**: `column profiles_1.email does not exist`

**Root Cause**: The join syntax for teammate profiles was incorrectly using `teammate:profiles!teammate_id` which was creating an ambiguous alias that PostgreSQL couldn't resolve properly.

**Fix**: Updated the join syntax to use explicit aliases:
```sql
-- Before
teammate:profiles!teammate_id(id, full_name, email, phone)

-- After  
teammate_profile:profiles!matches_teammate_id_fkey(id, full_name, email, phone)
```

**Files Updated**:
- `lib/screens/tabs/matches_screen.dart` - Updated query and all references to use `match['teammate_profile']`
- `lib/screens/tabs/find_screen.dart` - Updated query and references to use `match['teammate_profile']`

### 2. Type Mismatch Error
**Error**: `type 'String' is not a subtype of type 'int'`

**Root Cause**: Course and county IDs were being returned as strings from Supabase but the code expected integers for the mapping.

**Fix**: Added proper type conversion:
```dart
// Before
_courseMap = {for (var e in data) e['name']: e['id']};
countyMap[full] = row['id'];

// After
_courseMap = {for (var e in data) e['name']: int.tryParse(e['id'].toString()) ?? 0};
countyMap[full] = int.tryParse(row['id'].toString()) ?? 0;
```

**Files Updated**:
- `lib/screens/tabs/create_screen.dart` - Fixed course and county ID type conversion

## Database Schema Notes

The foreign key relationship is correctly defined as:
```sql
teammate_id UUID REFERENCES profiles(id) ON DELETE SET NULL
```

The join should reference the foreign key name `matches_teammate_id_fkey` which Supabase auto-generates based on the table and column names.

## Testing

After these fixes:
- ✅ Teammate profile data should load correctly in matches and find screens
- ✅ Course and county loading should work without type errors
- ✅ Proper teammate names should display instead of raw data
- ✅ Database queries should execute without PostgreSQL errors

## Next Steps

1. Test the teammate selection flow in create screen
2. Verify that matches display teammate information correctly
3. Check that partnerships are created properly with the linked teammate IDs
4. Test the find screen to ensure it shows teammate info for existing matches
