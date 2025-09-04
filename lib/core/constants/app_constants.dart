class AppConstants {
  // Collections
  static const String usersCollection = 'users';
  static const String schedulesCollection = 'schedules';
  static const String sessionsCollection = 'sessions';
  static const String bookingsCollection = 'bookings';
  static const String sessionTypesCollection = 'sessionTypes';
  static const String schedulableSessionsCollection = 'schedulableSessions';
  static const String availabilityOverridesCollection = 'availability_overrides';
  
  // Error Messages
  static const String serverErrorMessage = 'Server error occurred';
  static const String cacheErrorMessage = 'Cache error occurred';
  static const String networkErrorMessage = 'Network error occurred';
  static const String authErrorMessage = 'Authentication error occurred';
  static const String validationErrorMessage = 'Validation error occurred';
  
  // Default Values
  static const int defaultBookingLeadTime = 30; // minutes
  static const int defaultFutureBookingLimit = 7; // days
  static const int defaultBreakTime = 0; // minutes
}
