import 'package:get_it/get_it.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:myapp/core/config/app_config.dart';

// Features
import 'package:myapp/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:myapp/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:myapp/features/auth/domain/repositories/auth_repository.dart';
import 'package:myapp/features/auth/domain/usecases/sign_in_with_email.dart';
import 'package:myapp/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:myapp/features/auth/domain/usecases/sign_up_with_email.dart';
import 'package:myapp/features/auth/domain/usecases/sign_out.dart';
import 'package:myapp/features/auth/presentation/bloc/auth_bloc.dart';

import 'package:myapp/features/schedule/data/datasources/schedule_remote_data_source.dart';
import 'package:myapp/features/schedule/data/repositories/schedule_repository_impl.dart';
import 'package:myapp/features/schedule/domain/repositories/schedule_repository.dart';
import 'package:myapp/features/schedule/domain/usecases/get_schedules.dart';
import 'package:myapp/features/schedule/domain/usecases/get_schedule_by_id.dart';
import 'package:myapp/features/schedule/domain/usecases/create_schedule.dart';
import 'package:myapp/features/schedule/domain/usecases/update_schedule.dart';
import 'package:myapp/features/schedule/presentation/bloc/schedule_bloc.dart';

import 'package:myapp/features/user/data/datasources/user_remote_data_source.dart';
import 'package:myapp/features/user/data/repositories/user_repository_impl.dart';
import 'package:myapp/features/user/domain/repositories/user_repository.dart';
import 'package:myapp/features/user/domain/usecases/get_instructors.dart';
import 'package:myapp/features/user/domain/usecases/get_user.dart';
import 'package:myapp/features/user/domain/usecases/get_instructor_by_id.dart';
import 'package:myapp/features/user/presentation/bloc/user_bloc.dart';

import 'package:myapp/features/bookable_session/data/datasources/bookable_session_remote_data_source.dart';
import 'package:myapp/features/bookable_session/data/repositories/bookable_session_repository_impl.dart';
import 'package:myapp/features/bookable_session/domain/repositories/bookable_session_repository.dart';
import 'package:myapp/features/bookable_session/domain/usecases/get_bookable_sessions.dart';
import 'package:myapp/features/bookable_session/domain/usecases/get_all_bookable_sessions.dart';
import 'package:myapp/features/bookable_session/domain/usecases/create_bookable_session.dart';
import 'package:myapp/features/bookable_session/domain/usecases/update_bookable_session.dart';
import 'package:myapp/features/bookable_session/domain/usecases/delete_bookable_session.dart';
import 'package:myapp/features/bookable_session/presentation/bloc/bookable_session_bloc.dart';

import 'package:myapp/features/session_type/data/datasources/session_type_remote_data_source.dart';
import 'package:myapp/features/session_type/data/repositories/session_type_repository_impl.dart';
import 'package:myapp/features/session_type/domain/repositories/session_type_repository.dart';
import 'package:myapp/features/session_type/domain/usecases/get_session_types.dart';
import 'package:myapp/features/session_type/domain/usecases/create_session_type.dart';
import 'package:myapp/features/session_type/domain/usecases/update_session_type.dart';
import 'package:myapp/features/session_type/domain/usecases/delete_session_type.dart';
import 'package:myapp/features/session_type/presentation/bloc/session_type_bloc.dart';

import 'package:myapp/features/booking/data/datasources/booking_remote_data_source.dart';
import 'package:myapp/features/booking/data/repositories/booking_repository_impl.dart';
import 'package:myapp/features/booking/domain/repositories/booking_repository.dart';
import 'package:myapp/features/booking/domain/usecases/get_bookings.dart';
import 'package:myapp/features/booking/domain/usecases/create_booking.dart';
import 'package:myapp/features/booking/domain/usecases/cancel_booking.dart';
import 'package:myapp/features/booking/presentation/bloc/booking_bloc.dart';

import 'package:myapp/features/review/data/repositories/review_repository_impl.dart';
import 'package:myapp/features/review/domain/repositories/review_repository.dart';
import 'package:myapp/features/review/domain/usecases/create_review.dart';
import 'package:myapp/features/review/domain/usecases/get_reviews_by_booking.dart';
import 'package:myapp/features/review/domain/usecases/get_review_by_booking_and_client.dart';
import 'package:myapp/features/review/presentation/bloc/review_bloc.dart';

import 'package:myapp/features/location/data/datasources/location_remote_data_source.dart';
import 'package:myapp/features/location/data/repositories/location_repository_impl.dart';
import 'package:myapp/features/location/domain/repositories/location_repository.dart';
import 'package:myapp/features/location/domain/usecases/get_locations.dart';
import 'package:myapp/features/location/domain/usecases/get_locations_by_instructor.dart';
import 'package:myapp/features/location/domain/usecases/create_location.dart';
import 'package:myapp/features/location/domain/usecases/update_location.dart';
import 'package:myapp/features/location/domain/usecases/delete_location.dart';
import 'package:myapp/features/location/presentation/bloc/location_bloc.dart';
import 'package:myapp/features/notification/data/datasources/notification_remote_data_source.dart';
import 'package:myapp/features/notification/data/repositories/notification_repository_impl.dart';
import 'package:myapp/features/notification/domain/repositories/notification_repository.dart';
import 'package:myapp/features/notification/domain/usecases/get_notifications.dart';
import 'package:myapp/features/notification/domain/usecases/mark_notification_as_read.dart';
import 'package:myapp/features/notification/domain/usecases/send_booking_confirmation.dart';
import 'package:myapp/features/notification/domain/usecases/send_booking_reminder.dart';
import 'package:myapp/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:myapp/core/services/dependency_checker.dart';
import 'package:myapp/core/services/email_service.dart';
import 'package:myapp/core/services/email_service_web.dart';
import 'package:myapp/core/services/email_service_firebase.dart';
import 'package:myapp/core/services/email_service_simple.dart';
import 'package:myapp/core/services/google_signin_service.dart';
import 'package:myapp/core/config/environment_config.dart';

final sl = GetIt.instance;

Future<void> initializeDependencies() async {
  // External dependencies
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() {
    // Use environment-specific database
    final environment = EnvironmentConfig.current;
    final databaseId = EnvironmentConfig.databaseId;
    
    final firestore = FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: databaseId);
    print('🔧 Firestore instance created with databaseId: ${firestore.databaseId}');
    print('🔧 Firestore app name: ${firestore.app.name}');
    print('🔧 Firestore app project: ${firestore.app.options.projectId}');
    print('🔧 Environment: ${environment.name}');
    print('🔧 Environment Name: ${EnvironmentConfig.environmentName}');
    print('🔧 Project Name: ${firestore.app.options.projectId}');
    return firestore;
  });
  sl.registerLazySingleton(() => FirebaseMessaging.instance);
  sl.registerLazySingleton(() => GoogleSignInService());
  
  // Services
  sl.registerLazySingleton(() => DependencyChecker(firestore: sl()));
  
  // Email Service - Environment-based selection
  sl.registerLazySingleton<EmailService>(() => _createEmailService());

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(
      firebaseAuth: sl(),
      firestore: sl(),
      googleSignInService: sl(),
    ),
  );

  sl.registerLazySingleton<ScheduleRemoteDataSource>(
    () => ScheduleRemoteDataSourceImpl(firestore: sl()),
  );

  sl.registerLazySingleton<UserRemoteDataSource>(
    () => UserRemoteDataSourceImpl(firestore: sl()),
  );
  sl.registerLazySingleton<BookableSessionRemoteDataSource>(
    () => BookableSessionRemoteDataSourceImpl(firestore: sl()),
  );
  sl.registerLazySingleton<SessionTypeRemoteDataSource>(
    () => SessionTypeRemoteDataSourceImpl(firestore: sl()),
  );
  sl.registerLazySingleton<BookingRemoteDataSource>(
    () => BookingRemoteDataSourceImpl(firestore: sl()),
  );
  sl.registerLazySingleton<LocationRemoteDataSource>(
    () => LocationRemoteDataSourceImpl(firestore: sl()),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl()),
  );

  sl.registerLazySingleton<ScheduleRepository>(
    () => ScheduleRepositoryImpl(sl()),
  );

  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<BookableSessionRepository>(
    () => BookableSessionRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<SessionTypeRepository>(
    () => SessionTypeRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<BookingRepository>(
    () => BookingRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<LocationRepository>(
    () => LocationRepositoryImpl(sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => SignInWithEmail(sl()));
  sl.registerLazySingleton(() => SignInWithGoogle(sl()));
  sl.registerLazySingleton(() => SignUpWithEmail(sl()));
  sl.registerLazySingleton(() => SignOut(sl()));

  sl.registerLazySingleton(() => GetSchedules(sl()));
  sl.registerLazySingleton(() => GetScheduleById(sl()));
  sl.registerLazySingleton(() => CreateSchedule(sl()));
  sl.registerLazySingleton(() => UpdateScheduleUseCase(sl()));

  sl.registerLazySingleton(() => GetInstructors(sl()));
  sl.registerLazySingleton(() => GetUser(sl()));
  sl.registerLazySingleton(() => GetInstructorById(sl()));

  sl.registerLazySingleton(() => GetBookableSessions(sl()));
  sl.registerLazySingleton(() => GetAllBookableSessions(sl()));
  sl.registerLazySingleton(() => CreateBookableSession(sl()));
  sl.registerLazySingleton(() => UpdateBookableSession(sl()));
  sl.registerLazySingleton(() => DeleteBookableSession(sl()));

  sl.registerLazySingleton(() => GetSessionTypes(sl()));
  sl.registerLazySingleton(() => CreateSessionType(sl()));
  sl.registerLazySingleton(() => UpdateSessionType(sl()));
  sl.registerLazySingleton(() => DeleteSessionType(sl()));

  sl.registerLazySingleton(() => GetBookings(sl()));
  sl.registerLazySingleton(() => CreateBooking(sl()));
  sl.registerLazySingleton(() => CancelBooking(sl()));

  sl.registerLazySingleton(() => GetLocations(sl()));
  sl.registerLazySingleton(() => GetLocationsByInstructor(sl()));
  sl.registerLazySingleton(() => CreateLocation(sl()));
  sl.registerLazySingleton(() => UpdateLocation(sl()));
  sl.registerLazySingleton(() => DeleteLocation(sl()));

  // BLoCs
  sl.registerFactory(
    () => AuthBloc(
      signInWithEmail: sl(),
      signInWithGoogle: sl(),
      signUpWithEmail: sl(),
      signOut: sl(),
      authRepository: sl(),
    ),
  );

  sl.registerFactory(
    () => ScheduleBloc(
      getSchedules: sl(),
      getScheduleById: sl(),
      createSchedule: sl(),
      updateSchedule: sl(),
      scheduleRepository: sl(),
    ),
  );
  sl.registerFactory(
    () => UserBloc(
      getInstructors: sl(),
      getUser: sl(),
      userRepository: sl(),
    ),
  );
  sl.registerFactory(
    () => BookableSessionBloc(
      getBookableSessions: sl(),
      getAllBookableSessions: sl(),
      createBookableSession: sl(),
      updateBookableSession: sl(),
      deleteBookableSession: sl(),
    ),
  );
  sl.registerLazySingleton(
    () => SessionTypeBloc(
      getSessionTypes: sl(),
      createSessionType: sl(),
      updateSessionType: sl(),
      deleteSessionType: sl(),
    ),
  );
  sl.registerLazySingleton(
    () => LocationBloc(
      getLocations: sl(),
      getLocationsByInstructor: sl(),
      createLocation: sl(),
      updateLocation: sl(),
      deleteLocation: sl(),
    ),
  );
  sl.registerFactory(
    () => BookingBloc(
      getBookings: sl(),
      createBooking: sl(),
      cancelBooking: sl(),
      repository: sl(),
      sendBookingConfirmation: sl(),
    ),
  );

  // Review dependencies
  sl.registerLazySingleton<ReviewRepository>(
    () => ReviewRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => CreateReview(sl()));
  sl.registerLazySingleton(() => GetReviewsByBooking(sl()));
  sl.registerLazySingleton(() => GetReviewByBookingAndClient(sl()));
  sl.registerFactory(
    () => ReviewBloc(
      createReview: sl(),
      getReviewsByBooking: sl(),
      getReviewByBookingAndClient: sl(),
    ),
  );

  // Notification dependencies
  sl.registerLazySingleton<NotificationRemoteDataSource>(
    () => NotificationRemoteDataSourceImpl(
      firestore: sl(),
      messaging: sl(),
      emailService: sl(),
    ),
  );

  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton(() => GetNotifications(sl()));
  sl.registerLazySingleton(() => MarkNotificationAsRead(sl()));
  sl.registerLazySingleton(() => SendBookingConfirmation(sl()));
  sl.registerLazySingleton(() => SendBookingReminder(sl()));

  sl.registerLazySingleton(
    () => NotificationBloc(
      getNotifications: sl(),
      markAsRead: sl(),
      sendBookingConfirmation: sl(),
      sendBookingReminder: sl(),
      repository: sl(),
    ),
  );
}

/// Factory function to create the appropriate email service based on environment
EmailService _createEmailService() {
  // Print environment information
  EnvironmentConfig.printEnvironmentInfo();
  
  // Choose email service based on environment
  if (EnvironmentConfig.shouldUseRealEmail) {
    print('🔧 Email Service: Using FirebaseEmailService for real email delivery via SendGrid');
    return FirebaseEmailService();
  } else {
    print('🔧 Email Service: Using SimpleEmailService for console logging');
    return SimpleEmailService();
  }
}
