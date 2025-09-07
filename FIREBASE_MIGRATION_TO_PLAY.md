# Firebase Migration to Play Project

## Overview
This document outlines the migration from the original Firebase project to the new 'play-e37a6' project with restructured database collections under the 'sessionizer' collection.

## Changes Made

### 1. Firebase Configuration Updated
**File**: `lib/firebase_options.dart`
- **Project ID**: Changed from `apiclientapp` to `play-e37a6`
- **Auth Domain**: Changed from `apiclientapp.firebaseapp.com` to `play-e37a6.firebaseapp.com`
- **Storage Bucket**: Changed from `apiclientapp.firebasestorage.app` to `play-e37a6.firebasestorage.app`

### 2. Firestore Rules Updated
**File**: `firestore.rules`
- **Database**: Now specifically targets the `play` database
- **Collection Structure**: All collections are now under the `sessionizer` parent collection
- **New Paths**:
  - `sessionizer/users/{userId}`
  - `sessionizer/locations/{locationId}`
  - `sessionizer/bookable_sessions/{sessionId}`
  - `sessionizer/schedules/{scheduleId}`
  - `sessionizer/session_types/{typeId}`
  - `sessionizer/bookings/{bookingId}`
  - `sessionizer/reviews/{reviewId}`
  - `sessionizer/notifications/{notificationId}`
  - `sessionizer/mail/{mailId}`
  - `sessionizer/instructors/{instructorId}`

### 3. Data Sources Updated

#### User Data Source
**File**: `lib/features/user/data/datasources/user_remote_data_source.dart`
- All collection references changed from `users` to `sessionizer/users`
- Methods updated:
  - `getInstructors()`
  - `getUser()`
  - `getUserById()`
  - `createUser()`
  - `updateUser()`
  - `deleteUser()`

### 4. Data Sources Updated ✅
All data sources have been successfully updated to use the new collection structure:

#### Auth Data Source ✅
- **File**: `lib/features/auth/data/datasources/auth_remote_data_source.dart`
- **Collections**: `users` → `sessionizer/users`
- **Status**: Updated all 6 collection references

#### Location Data Source ✅
- **File**: `lib/features/location/data/datasources/location_remote_data_source.dart`
- **Collections**: `locations` → `sessionizer/locations`
- **Status**: Updated all collection references

#### Bookable Session Data Source ✅
- **File**: `lib/features/bookable_session/data/datasources/bookable_session_remote_data_source.dart`
- **Collections**: `bookable_sessions` → `sessionizer/bookable_sessions`
- **Status**: Updated all collection references

#### Schedule Data Source ✅
- **File**: `lib/features/schedule/data/datasources/schedule_remote_data_source.dart`
- **Collections**: `schedules` → `sessionizer/schedules`
- **Status**: Updated all collection references

#### Session Type Data Source ✅
- **File**: `lib/features/session_type/data/datasources/session_type_remote_data_source.dart`
- **Collections**: `session_types` → `sessionizer/session_types`
- **Status**: Updated all collection references

#### Booking Data Source ✅
- **File**: `lib/features/booking/data/datasources/booking_remote_data_source.dart`
- **Collections**: `bookings` → `sessionizer/bookings`
- **Status**: Updated all collection references

#### Notification Data Source ✅
- **File**: `lib/features/notification/data/datasources/notification_remote_data_source.dart`
- **Collections**: `notifications` → `sessionizer/notifications`, `mail` → `sessionizer/mail`
- **Status**: Updated all collection references

#### Dependency Checker Service ✅
- **File**: `lib/core/services/dependency_checker.dart`
- **Collections**: Updated all collection references to use new paths
- **Status**: Updated all collection references

### 5. Collection Path Changes Summary

| Original Path | New Path |
|---------------|----------|
| `users` | `sessionizer/users` |
| `locations` | `sessionizer/locations` |
| `bookable_sessions` | `sessionizer/bookable_sessions` |
| `schedules` | `sessionizer/schedules` |
| `session_types` | `sessionizer/session_types` |
| `bookings` | `sessionizer/bookings` |
| `reviews` | `sessionizer/reviews` |
| `notifications` | `sessionizer/notifications` |
| `mail` | `sessionizer/mail` |
| `instructors` | `sessionizer/instructors` |

## Migration Steps

### Completed ✅
1. Updated Firebase configuration to use 'play-e37a6' project
2. Updated Firestore rules to use 'play' database
3. Restructured all rules to use 'sessionizer' parent collection
4. Updated User data source to use new collection paths

### In Progress 🔄
5. Update remaining data sources to use new collection paths

### Pending ⏳
6. Update any models if needed for new structure
7. Test the migration to ensure everything works
8. Deploy Firestore rules to the new project
9. Migrate existing data (if any) to new structure

## Security Rules Benefits

The new structure under the 'sessionizer' collection provides:
- **Better Organization**: All app data is contained under one parent collection
- **Easier Management**: Clearer separation from other potential apps in the same project
- **Simplified Rules**: More straightforward rule management
- **Namespace Protection**: Prevents conflicts with other collections

## Database Structure

```
play (database)
└── sessionizer (collection)
    ├── users (subcollection)
    │   └── {userId} (document)
    ├── locations (subcollection)
    │   └── {locationId} (document)
    ├── bookable_sessions (subcollection)
    │   └── {sessionId} (document)
    ├── schedules (subcollection)
    │   └── {scheduleId} (document)
    ├── session_types (subcollection)
    │   └── {typeId} (document)
    ├── bookings (subcollection)
    │   └── {bookingId} (document)
    ├── reviews (subcollection)
    │   └── {reviewId} (document)
    ├── notifications (subcollection)
    │   └── {notificationId} (document)
    ├── mail (subcollection)
    │   └── {mailId} (document)
    └── instructors (subcollection)
        └── {instructorId} (document)
```

## Next Steps

1. **Complete Data Source Updates**: Update all remaining data sources to use the new collection paths
2. **Test Locally**: Ensure all functionality works with the new structure
3. **Deploy Rules**: Deploy the updated Firestore rules to the 'play-e37a6' project
4. **Data Migration**: If there's existing data, create a migration script
5. **Update Tests**: Update any unit tests to use the new collection paths
6. **Documentation**: Update any API documentation to reflect the new structure

## Important Notes

- **Database Name**: The Firestore rules now specifically target the `play` database
- **Collection Nesting**: All collections are now nested under the `sessionizer` collection
- **Authentication**: Firebase Auth remains the same, only the Firestore structure has changed
- **Permissions**: The security rules maintain the same permission logic but with updated paths
- **Backwards Compatibility**: This change is not backwards compatible with the old structure
