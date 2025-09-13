import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/core/utils/injection_container.dart';
import 'package:myapp/core/config/environment.dart';
import 'package:myapp/core/config/environment_config.dart';

/// Centralized collection path manager for Firestore
/// This ensures all collection paths are consistent and can be changed in one place
/// Now supports environment-based collection separation (DevData/ProdData)
class FirestoreCollections {
  /// Get the root collection name based on current environment
  static String get _rootCollection => EnvironmentConfig.collectionPrefix;
  
  // Collection names
  static const String _users = 'users';
  static const String _locations = 'locations';
  static const String _bookableSessions = 'bookable_sessions';
  static const String _bookings = 'bookings';
  static const String _schedules = 'schedules';
  static const String _sessionTypes = 'session_types';
  static const String _notifications = 'notifications';
  static const String _scheduledNotifications = 'scheduled_notifications';
  static const String _feedback = 'feedback';
  static const String _mail = 'mail';

  /// Get the configured Firestore instance (play database)
  static FirebaseFirestore get _firestore {
    final instance = sl<FirebaseFirestore>();
    print('🔍 Project Name: ${instance.app.options.projectId}');
    print('🔍 FirestoreCollections using database ID: ${instance.databaseId}');
    return instance;
  }

  /// Helper method to get a collection reference
  /// Now uses nested collection access: sessionizer/{environmentPrefix}/{collectionName}
  static CollectionReference _getCollection(String collectionName) => 
      _firestore.collection('sessionizer').doc(_rootCollection).collection(collectionName);

  /// Get the users collection reference
  static CollectionReference get users => _getCollection(_users);

  /// Get the locations collection reference
  static CollectionReference get locations => _getCollection(_locations);

  /// Get the bookable sessions collection reference
  static CollectionReference get bookableSessions => _getCollection(_bookableSessions);

  /// Get the bookings collection reference
  static CollectionReference get bookings => _getCollection(_bookings);

  /// Get the schedules collection reference
  static CollectionReference get schedules => _getCollection(_schedules);

  /// Get the session types collection reference
  static CollectionReference get sessionTypes => _getCollection(_sessionTypes);

  /// Get the notifications collection reference
  static CollectionReference get notifications => _getCollection(_notifications);

  /// Get the scheduled notifications collection reference
  static CollectionReference get scheduledNotifications => _getCollection(_scheduledNotifications);

  /// Get the feedback collection reference
  static CollectionReference get feedback => _getCollection(_feedback);

  /// Get the mail collection reference
  static CollectionReference get mail => _getCollection(_mail);

  /// Get a specific user document reference
  static DocumentReference user(String userId) => users.doc(userId);

  /// Get a specific location document reference
  static DocumentReference location(String locationId) => locations.doc(locationId);

  /// Get a specific bookable session document reference
  static DocumentReference bookableSession(String sessionId) => bookableSessions.doc(sessionId);

  /// Get a specific booking document reference
  static DocumentReference booking(String bookingId) => bookings.doc(bookingId);

  /// Get a specific schedule document reference
  static DocumentReference schedule(String scheduleId) => schedules.doc(scheduleId);

  /// Get a specific session type document reference
  static DocumentReference sessionType(String typeId) => sessionTypes.doc(typeId);

  /// Get a specific notification document reference
  static DocumentReference notification(String notificationId) => notifications.doc(notificationId);

  /// Get a specific scheduled notification document reference
  static DocumentReference scheduledNotification(String notificationId) => scheduledNotifications.doc(notificationId);

  /// Get a specific feedback document reference
  static DocumentReference feedbackDoc(String feedbackId) => feedback.doc(feedbackId);

  /// Get a specific mail document reference
  static DocumentReference mailDoc(String mailId) => mail.doc(mailId);

}

/// Query builders for common queries
class FirestoreQueries {
  /// Get users by instructor status
  static Query getInstructors() => FirestoreCollections.users.where('isInstructor', isEqualTo: true);

  /// Get locations by instructor
  static Query getLocationsByInstructor(String instructorId) => 
      FirestoreCollections.locations.where('instructorId', isEqualTo: instructorId);

  /// Get bookable sessions by instructor
  static Query getBookableSessionsByInstructor(String instructorId) => 
      FirestoreCollections.bookableSessions.where('instructorId', isEqualTo: instructorId);

  /// Get bookings by client
  static Query getBookingsByClient(String clientId) => 
      FirestoreCollections.bookings.where('clientId', isEqualTo: clientId);

  /// Get bookings by instructor
  static Query getBookingsByInstructor(String instructorId) => 
      FirestoreCollections.bookings.where('instructorId', isEqualTo: instructorId);

  /// Get schedules by instructor
  static Query getSchedulesByInstructor(String instructorId) => 
      FirestoreCollections.schedules.where('instructorId', isEqualTo: instructorId);

  /// Get notifications by user
  static Query getNotificationsByUser(String userId) => 
      FirestoreCollections.notifications.where('userId', isEqualTo: userId);

  /// Get unread notifications by user
  static Query getUnreadNotificationsByUser(String userId) => 
      FirestoreCollections.notifications
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending');
}
