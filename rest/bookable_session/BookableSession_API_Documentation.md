# BookableSession API Documentation

## Overview

The BookableSession API provides REST endpoints for managing bookable sessions in the Sessionizer application. This API replaces the Firebase Firestore implementation with a traditional REST API approach.

## Base URL Structure

```
https://your-api-domain.com/api/v1/bookable-sessions
```

## Authentication

All API endpoints require Firebase Authentication. Include the Firebase ID token in the Authorization header:

```
Authorization: Bearer <firebase_id_token>
```

### Getting Firebase ID Token

```dart
// In Flutter/Dart
final user = FirebaseAuth.instance.currentUser;
final token = await user?.getIdToken();
```

## Request/Response Formats

### Content-Type
- **Request**: `application/json`
- **Response**: `application/json`

### Standard Response Format

#### Success Response
```json
{
  "success": true,
  "data": {
    // Response data here
  },
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 100,
    "totalPages": 5
  }
}
```

#### Error Response
```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human readable error message",
    "details": "Additional error details"
  }
}
```

## Data Models

### BookableSession Model

```json
{
  "id": "string",
  "instructorId": "string",
  "sessionTypeIds": ["string"],
  "locationIds": ["string"],
  "availabilityIds": ["string"],
  "breakTimeInMinutes": "integer",
  "bookingLeadTimeInMinutes": "integer",
  "futureBookingLimitInDays": "integer",
  "durationOverride": "integer (optional)",
  "createdAt": "ISO 8601 datetime",
  "updatedAt": "ISO 8601 datetime"
}
```

#### Field Descriptions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | No | Unique identifier (auto-generated) |
| `instructorId` | string | Yes | ID of the instructor who owns this session |
| `sessionTypeIds` | string[] | Yes | Array of session type IDs (min 1) |
| `locationIds` | string[] | Yes | Array of location IDs (min 1) |
| `availabilityIds` | string[] | Yes | Array of availability/schedule IDs (min 1) |
| `breakTimeInMinutes` | integer | No | Break time between sessions (default: 0) |
| `bookingLeadTimeInMinutes` | integer | No | Minimum advance booking time (default: 30) |
| `futureBookingLimitInDays` | integer | No | How far in advance bookings can be made (default: 7) |
| `durationOverride` | integer | No | Optional duration override in minutes |
| `createdAt` | datetime | No | Creation timestamp (auto-generated) |
| `updatedAt` | datetime | No | Last update timestamp (auto-generated) |

#### Validation Rules

- `instructorId`: Required, non-empty string
- `sessionTypeIds`: Required, non-empty array, each element must be non-empty string
- `locationIds`: Required, non-empty array, each element must be non-empty string
- `availabilityIds`: Required, non-empty array, each element must be non-empty string
- `breakTimeInMinutes`: Optional, non-negative integer, max 1440 (24 hours)
- `bookingLeadTimeInMinutes`: Optional, non-negative integer, max 10080 (7 days)
- `futureBookingLimitInDays`: Optional, positive integer, max 365
- `durationOverride`: Optional, positive integer, max 1440 (24 hours)

## API Endpoints

### 1. Get All Bookable Sessions

**GET** `/api/v1/bookable-sessions`

Retrieve all bookable sessions with optional filtering and pagination.

#### Query Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `instructorId` | string | No | - | Filter by instructor ID |
| `isActive` | boolean | No | true | Filter by active status |
| `page` | integer | No | 1 | Page number for pagination |
| `limit` | integer | No | 20 | Number of items per page (max 100) |
| `sortBy` | string | No | createdAt | Field to sort by |
| `sortOrder` | string | No | desc | Sort order (asc/desc) |

#### Example Request
```http
GET /api/v1/bookable-sessions?instructorId=instructor_456&page=1&limit=20&sortBy=createdAt&sortOrder=desc
Authorization: Bearer <firebase_id_token>
```

#### Example Response
```json
{
  "success": true,
  "data": [
    {
      "id": "session_123",
      "instructorId": "instructor_456",
      "sessionTypeIds": ["type_1", "type_2"],
      "locationIds": ["loc_1", "loc_2"],
      "availabilityIds": ["avail_1", "avail_2"],
      "breakTimeInMinutes": 15,
      "bookingLeadTimeInMinutes": 30,
      "futureBookingLimitInDays": 7,
      "durationOverride": 60,
      "createdAt": "2024-01-01T00:00:00Z",
      "updatedAt": "2024-01-01T00:00:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 1,
    "totalPages": 1
  }
}
```

### 2. Get Bookable Session by ID

**GET** `/api/v1/bookable-sessions/{id}`

Retrieve a specific bookable session by its ID.

#### Path Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | string | Yes | Bookable session ID |

#### Example Request
```http
GET /api/v1/bookable-sessions/session_123
Authorization: Bearer <firebase_id_token>
```

#### Example Response
```json
{
  "success": true,
  "data": {
    "id": "session_123",
    "instructorId": "instructor_456",
    "sessionTypeIds": ["type_1", "type_2"],
    "locationIds": ["loc_1", "loc_2"],
    "availabilityIds": ["avail_1", "avail_2"],
    "breakTimeInMinutes": 15,
    "bookingLeadTimeInMinutes": 30,
    "futureBookingLimitInDays": 7,
    "durationOverride": 60,
    "createdAt": "2024-01-01T00:00:00Z",
    "updatedAt": "2024-01-01T00:00:00Z"
  }
}
```

### 3. Create Bookable Session

**POST** `/api/v1/bookable-sessions`

Create a new bookable session.

#### Request Body

```json
{
  "instructorId": "instructor_456",
  "sessionTypeIds": ["type_1", "type_2"],
  "locationIds": ["loc_1", "loc_2"],
  "availabilityIds": ["avail_1", "avail_2"],
  "breakTimeInMinutes": 15,
  "bookingLeadTimeInMinutes": 30,
  "futureBookingLimitInDays": 7,
  "durationOverride": 60
}
```

#### Example Request
```http
POST /api/v1/bookable-sessions
Authorization: Bearer <firebase_id_token>
Content-Type: application/json

{
  "instructorId": "instructor_456",
  "sessionTypeIds": ["type_1", "type_2"],
  "locationIds": ["loc_1", "loc_2"],
  "availabilityIds": ["avail_1", "avail_2"],
  "breakTimeInMinutes": 15,
  "bookingLeadTimeInMinutes": 30,
  "futureBookingLimitInDays": 7,
  "durationOverride": 60
}
```

#### Example Response
```json
{
  "success": true,
  "data": {
    "id": "session_123",
    "instructorId": "instructor_456",
    "sessionTypeIds": ["type_1", "type_2"],
    "locationIds": ["loc_1", "loc_2"],
    "availabilityIds": ["avail_1", "avail_2"],
    "breakTimeInMinutes": 15,
    "bookingLeadTimeInMinutes": 30,
    "futureBookingLimitInDays": 7,
    "durationOverride": 60,
    "createdAt": "2024-01-01T00:00:00Z",
    "updatedAt": "2024-01-01T00:00:00Z"
  }
}
```

### 4. Update Bookable Session

**PUT** `/api/v1/bookable-sessions/{id}`

Update an existing bookable session.

#### Path Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | string | Yes | Bookable session ID |

#### Request Body

Same as create, but all fields are optional for partial updates.

#### Example Request
```http
PUT /api/v1/bookable-sessions/session_123
Authorization: Bearer <firebase_id_token>
Content-Type: application/json

{
  "breakTimeInMinutes": 20,
  "bookingLeadTimeInMinutes": 45,
  "futureBookingLimitInDays": 14
}
```

#### Example Response
```json
{
  "success": true,
  "data": {
    "id": "session_123",
    "instructorId": "instructor_456",
    "sessionTypeIds": ["type_1", "type_2"],
    "locationIds": ["loc_1", "loc_2"],
    "availabilityIds": ["avail_1", "avail_2"],
    "breakTimeInMinutes": 20,
    "bookingLeadTimeInMinutes": 45,
    "futureBookingLimitInDays": 14,
    "durationOverride": 60,
    "createdAt": "2024-01-01T00:00:00Z",
    "updatedAt": "2024-01-01T12:00:00Z"
  }
}
```

### 5. Delete Bookable Session

**DELETE** `/api/v1/bookable-sessions/{id}`

Delete a bookable session.

#### Path Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | string | Yes | Bookable session ID |

#### Example Request
```http
DELETE /api/v1/bookable-sessions/session_123
Authorization: Bearer <firebase_id_token>
```

#### Example Response
```http
HTTP/1.1 204 No Content
```

### 6. Search Bookable Sessions

**GET** `/api/v1/bookable-sessions/search`

Search bookable sessions with various filters.

#### Query Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `q` | string | No | Search query string |
| `instructorId` | string | No | Filter by instructor ID |
| `locationId` | string | No | Filter by location ID |
| `sessionTypeId` | string | No | Filter by session type ID |
| `page` | integer | No | 1 | Page number |
| `limit` | integer | No | 20 | Items per page |

#### Example Request
```http
GET /api/v1/bookable-sessions/search?q=yoga&instructorId=instructor_456&page=1&limit=20
Authorization: Bearer <firebase_id_token>
```

## Error Handling

### HTTP Status Codes

| Code | Description |
|------|-------------|
| 200 | OK - Request successful |
| 201 | Created - Resource created successfully |
| 204 | No Content - Resource deleted successfully |
| 400 | Bad Request - Invalid request data |
| 401 | Unauthorized - Authentication required |
| 403 | Forbidden - Insufficient permissions |
| 404 | Not Found - Resource not found |
| 409 | Conflict - Resource conflict |
| 422 | Unprocessable Entity - Validation error |
| 500 | Internal Server Error - Server error |

### Error Codes

| Code | Description |
|------|-------------|
| `UNAUTHORIZED` | Authentication required |
| `FORBIDDEN` | Insufficient permissions |
| `BOOKABLE_SESSION_NOT_FOUND` | Bookable session not found |
| `VALIDATION_ERROR` | Request validation failed |
| `INSTRUCTOR_NOT_FOUND` | Instructor not found |
| `LOCATION_NOT_FOUND` | Location not found |
| `SESSION_TYPE_NOT_FOUND` | Session type not found |
| `AVAILABILITY_NOT_FOUND` | Availability not found |
| `CONFLICT` | Resource conflict |
| `INTERNAL_SERVER_ERROR` | Internal server error |

### Example Error Response

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Validation failed",
    "details": [
      {
        "field": "instructorId",
        "message": "Instructor ID is required"
      },
      {
        "field": "sessionTypeIds",
        "message": "At least one session type must be specified"
      }
    ]
  }
}
```

## Rate Limiting

- **Rate Limit**: 1000 requests per hour per user
- **Headers**: 
  - `X-RateLimit-Limit`: Request limit per hour
  - `X-RateLimit-Remaining`: Remaining requests
  - `X-RateLimit-Reset`: Reset time (Unix timestamp)

## Pagination

All list endpoints support pagination:

- `page`: Page number (1-based)
- `limit`: Items per page (max 100)
- `total`: Total number of items
- `totalPages`: Total number of pages

## Caching

- **Cache-Control**: `public, max-age=300` (5 minutes)
- **ETag**: Entity tag for conditional requests
- **Last-Modified**: Last modification timestamp

## Firebase Functions Considerations

### Cold Start
- First request may take 2-5 seconds
- Subsequent requests are faster
- Consider warming up functions

### Timeout
- Default timeout: 30 seconds
- Maximum timeout: 540 seconds (9 minutes)

### Regional Deployment
- Deploy to `us-central1` for optimal performance
- Consider multi-region deployment for global users

### Authentication
- Firebase Auth tokens expire after 1 hour
- Implement automatic token refresh
- Handle token refresh failures gracefully

## Testing

### Unit Tests
```dart
// Example test structure
group('BookableSessionRemoteRestDataSource', () {
  test('should return bookable sessions when GET request is successful', () async {
    // Test implementation
  });
  
  test('should throw ServerException when GET request fails', () async {
    // Test implementation
  });
});
```

### Integration Tests
- Test with real Firebase Auth tokens
- Test error scenarios
- Test timeout handling
- Test token refresh

## Migration Guide

### 1. Update Dependencies

Add HTTP client dependency to `pubspec.yaml`:

```yaml
dependencies:
  http: ^1.1.0
```

### 2. Update Dependency Injection

Replace Firestore data source with REST data source:

```dart
// Before
sl.registerLazySingleton<BookableSessionRemoteDataSource>(
  () => BookableSessionRemoteDataSourceImpl(firestore: sl()),
);

// After
sl.registerLazySingleton<BookableSessionRemoteDataSource>(
  () => BookableSessionRemoteRestDataSourceImpl(
    httpClient: sl(),
    firebaseAuth: sl(),
    baseUrl: 'https://your-api-domain.com',
  ),
);
```

### 3. Register HTTP Client

Add HTTP client to dependency injection:

```dart
sl.registerLazySingleton(() => http.Client());
```

### 4. Update Environment Configuration

Add API base URL to environment configuration:

```dart
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://your-api-domain.com',
  );
}
```

### 5. Test Migration

1. Run unit tests
2. Run integration tests
3. Test with real API endpoints
4. Verify error handling
5. Test token refresh

## Security Considerations

1. **Authentication**: Always validate Firebase tokens
2. **Authorization**: Check user permissions for each operation
3. **Input Validation**: Validate all input data
4. **Rate Limiting**: Implement rate limiting
5. **HTTPS**: Use HTTPS for all communications
6. **CORS**: Configure CORS properly
7. **Logging**: Log security events
8. **Monitoring**: Monitor for suspicious activity

## Performance Optimization

1. **Caching**: Implement appropriate caching strategies
2. **Pagination**: Use pagination for large datasets
3. **Compression**: Enable gzip compression
4. **CDN**: Use CDN for static assets
5. **Database**: Optimize database queries
6. **Connection Pooling**: Use connection pooling
7. **Monitoring**: Monitor performance metrics

## Monitoring and Logging

### Metrics to Monitor
- Request count
- Response time
- Error rate
- Authentication failures
- Rate limit hits

### Logging
- Request/response logging
- Error logging
- Authentication events
- Performance metrics

### Alerts
- High error rate
- Slow response times
- Authentication failures
- Rate limit exceeded
