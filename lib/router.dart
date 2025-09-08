import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:myapp/features/auth/presentation/bloc/auth_state.dart';
import 'package:myapp/features/auth/presentation/pages/login_page.dart';
import 'package:myapp/features/auth/presentation/pages/signup_page.dart';
import 'package:myapp/features/main/presentation/pages/main_screen.dart';
import 'package:myapp/features/main/presentation/pages/profile_page.dart';
import 'package:myapp/features/main/presentation/pages/instructor_dashboard_page.dart';
import 'package:myapp/features/main/presentation/pages/client_dashboard_page.dart';
import 'package:myapp/features/main/presentation/pages/client_bookings_page.dart';
import 'package:myapp/features/main/presentation/pages/client_sessions_page.dart';
import 'package:myapp/features/main/presentation/pages/client_profile_page.dart';
import 'package:myapp/features/booking/presentation/pages/instructor_booking_management_page.dart';
import 'package:myapp/features/booking/presentation/pages/client_calendar_page.dart';
import 'package:myapp/features/booking/presentation/pages/client_booking_flow_page.dart';
import 'package:myapp/features/booking/presentation/pages/public_calendar_page.dart';
import 'package:myapp/features/main/presentation/pages/public_sessions_page.dart';
import 'package:myapp/features/main/presentation/pages/instructor_public_links_page.dart';
import 'package:myapp/features/main/presentation/pages/client_instructor_selection_page.dart';
import 'package:myapp/features/booking/presentation/bloc/booking_bloc.dart';
import 'package:myapp/features/schedule/presentation/pages/schedule_management_page.dart';
import 'package:myapp/features/schedule/presentation/pages/schedule_creation_page.dart';
import 'package:myapp/features/schedule/presentation/pages/schedule_detail_page.dart';
import 'package:myapp/features/schedule/presentation/pages/schedule_edit_page.dart';
import 'package:myapp/features/schedule/presentation/bloc/schedule_bloc.dart';
import 'package:myapp/features/session_type/presentation/pages/session_type_management_page.dart';
import 'package:myapp/features/session_type/presentation/pages/session_type_creation_page.dart';
import 'package:myapp/features/session_type/presentation/bloc/session_type_bloc.dart';
import 'package:myapp/features/bookable_session/presentation/pages/simple_bookable_session_page.dart';
import 'package:myapp/features/location/presentation/pages/location_management_page.dart';
import 'package:myapp/features/location/presentation/pages/location_creation_page.dart';
import 'package:myapp/features/location/presentation/bloc/location_bloc.dart';
import 'package:myapp/features/location/domain/entities/location_entity.dart';
import 'package:myapp/features/session_type/domain/entities/session_type_entity.dart';
import 'package:myapp/features/notification/presentation/pages/notification_management_page.dart';
import 'package:myapp/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:myapp/core/utils/injection_container.dart';
import 'package:myapp/core/utils/logger.dart';

// Stream to listen to auth state changes
Stream<AuthState> get _authStateStream {
  final authBloc = sl<AuthBloc>();
  return authBloc.stream;
}

// Custom refresh stream for GoRouter
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream({required Stream<dynamic> stream}) {
    _subscription = stream.listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    refreshListenable: GoRouterRefreshStream(
      stream: _authStateStream,
    ),
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const SignupPage(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const MainScreen(child: ProfilePage()),
      ),
      GoRoute(
        path: '/instructor-dashboard',
        builder: (context, state) => const MainScreen(child: InstructorDashboardPage()),
      ),
      GoRoute(
        path: '/client-dashboard',
        builder: (context, state) {
          final instructorId = state.uri.queryParameters['instructorId'];
          return MainScreen(
            child: ClientDashboardPage(instructorId: instructorId),
          );
        },
      ),
        GoRoute(
          path: '/client/instructor-selection',
          builder: (context, state) => const MainScreen(
            child: ClientInstructorSelectionPage(),
          ),
        ),
      GoRoute(
        path: '/client/bookings',
        builder: (context, state) => const MainScreen(child: ClientBookingsPage()),
      ),
      GoRoute(
        path: '/client/sessions',
        builder: (context, state) {
          final instructorId = state.uri.queryParameters['instructorId'];
          return MainScreen(child: ClientSessionsPage(instructorId: instructorId));
        },
      ),
      GoRoute(
        path: '/client/profile',
        builder: (context, state) => BlocProvider.value(
          value: sl<BookingBloc>(),
          child: const MainScreen(child: ClientProfilePage()),
        ),
      ),
      GoRoute(
        path: '/client/book/:sessionId/:instructorId',
        builder: (context, state) {
          final sessionId = state.pathParameters['sessionId']!;
          final instructorId = state.pathParameters['instructorId']!;
          return BlocProvider.value(
            value: sl<BookingBloc>(),
            child: MainScreen(
              child: ClientBookingFlowPage(
                sessionId: sessionId,
                instructorId: instructorId,
              ),
            ),
          );
        },
      ),
      GoRoute(
        path: '/client/calendar/:sessionId/:instructorId',
        builder: (context, state) {
          final sessionId = state.pathParameters['sessionId']!;
          final instructorId = state.pathParameters['instructorId']!;
          final rescheduleBookingId = state.uri.queryParameters['reschedule'];
          final clientId = state.uri.queryParameters['clientId'];
          return MainScreen(
            child: ClientCalendarPage(
              sessionId: sessionId,
              instructorId: instructorId,
              rescheduleBookingId: rescheduleBookingId,
              clientId: clientId,
            ),
          );
        },
      ),
      // Instructor Booking Management
      GoRoute(
        path: '/instructor/bookings',
        builder: (context, state) => BlocProvider.value(
          value: sl<BookingBloc>(),
          child: const MainScreen(child: InstructorBookingManagementPage()),
        ),
      ),
      // Instructor Public Links
      GoRoute(
        path: '/instructor/public-links',
        builder: (context, state) => const MainScreen(
          child: InstructorPublicLinksPage(),
        ),
      ),
      // Client Booking Calendar
      GoRoute(
        path: '/client/booking/:templateId',
        builder: (context, state) {
          final templateId = state.pathParameters['templateId']!;
          return MainScreen(
            child: FutureBuilder<Map<String, dynamic>?>(
              future: _loadTemplate(templateId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                
                if (snapshot.hasError || snapshot.data == null) {
                  return Scaffold(
                    appBar: AppBar(title: const Text('Error')),
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text('Failed to load template: ${snapshot.error}'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => context.go('/client/sessions'),
                            child: const Text('Back to Sessions'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                return ClientCalendarPage(
                  sessionId: templateId,
                  instructorId: snapshot.data!['instructorId'] ?? '',
                );
              },
            ),
          );
        },
      ),
      // Schedule Management Routes
      GoRoute(
        path: '/schedule',
        builder: (context, state) => BlocProvider.value(
          value: sl<ScheduleBloc>(),
          child: const MainScreen(child: ScheduleManagementPage()),
        ),
      ),
      GoRoute(
        path: '/schedule/create',
        builder: (context, state) => BlocProvider.value(
          value: sl<ScheduleBloc>(),
          child: const MainScreen(child: ScheduleCreationPage()),
        ),
      ),
      GoRoute(
        path: '/schedule/:scheduleId',
        builder: (context, state) {
          final scheduleId = state.pathParameters['scheduleId']!;
          return BlocProvider.value(
            value: sl<ScheduleBloc>(),
            child: MainScreen(child: ScheduleDetailPage(scheduleId: scheduleId)),
          );
        },
      ),
      GoRoute(
        path: '/schedule/:scheduleId/edit',
        builder: (context, state) {
          final scheduleId = state.pathParameters['scheduleId']!;
          return BlocProvider.value(
            value: sl<ScheduleBloc>(),
            child: MainScreen(child: ScheduleEditPage(scheduleId: scheduleId)),
          );
        },
      ),
      // Session Type Management Routes
      GoRoute(
        path: '/session-types',
        builder: (context, state) => BlocProvider.value(
          value: sl<SessionTypeBloc>(),
          child: const MainScreen(child: SessionTypeManagementPage()),
        ),
      ),
      GoRoute(
        path: '/session-types/create',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final sessionType = extra?['sessionType'] as SessionTypeEntity?;
          final isEdit = extra?['isEdit'] as bool? ?? false;
          
          return BlocProvider.value(
            value: sl<SessionTypeBloc>(),
            child: MainScreen(
              child: SessionTypeCreationPage(
                existingSessionType: sessionType,
                isEdit: isEdit,
              ),
            ),
          );
        },
      ),
      // Schedulable Session Management Routes
      GoRoute(
        path: '/bookable-sessions',
        builder: (context, state) => const MainScreen(child: SimpleBookableSessionPage()),
      ),
      // Location Management Routes
      GoRoute(
        path: '/locations',
        builder: (context, state) => BlocProvider.value(
          value: sl<LocationBloc>(),
          child: const MainScreen(child: LocationManagementPage()),
        ),
      ),
      GoRoute(
        path: '/locations/create',
        builder: (context, state) => BlocProvider.value(
          value: sl<LocationBloc>(),
          child: const MainScreen(child: LocationCreationPage()),
        ),
      ),
      // Notification Management Routes
      GoRoute(
        path: '/notifications',
        builder: (context, state) => BlocProvider.value(
          value: sl<NotificationBloc>(),
          child: const MainScreen(child: NotificationManagementPage()),
        ),
      ),
      GoRoute(
        path: '/locations/edit',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final location = extra?['location'] as LocationEntity?;
          
          return BlocProvider.value(
            value: sl<LocationBloc>(),
            child: MainScreen(
              child: LocationCreationPage(
                existingLocation: location,
                isEdit: true,
              ),
            ),
          );
        },
      ),
      // Public routes (no authentication required)
      GoRoute(
        path: '/public/sessions/:instructorId',
        builder: (context, state) {
          final instructorId = state.pathParameters['instructorId']!;
          return PublicSessionsPage(instructorId: instructorId);
        },
      ),
      GoRoute(
        path: '/public/calendar/:sessionId/:instructorId',
        builder: (context, state) {
          final sessionId = state.pathParameters['sessionId']!;
          final instructorId = state.pathParameters['instructorId']!;
          return PublicCalendarPage(
            sessionId: sessionId,
            instructorId: instructorId,
          );
        },
      ),
    ],
    redirect: (context, state) {
      try {
        final authBloc = context.read<AuthBloc>();
        final authState = authBloc.state;
        
        final isLoggingIn = state.uri.path == '/login';
        final isRegistering = state.uri.path == '/register';
        
        print('🔄 Router redirect: path=${state.uri.path}, authState=${authState.runtimeType}');
        
        // Only redirect if auth state is not loading
        if (authState is AuthLoading) {
          print('⏳ Router: Auth loading - no redirect');
          return null; // Let the loading state show
        }
        
        // If authenticated, redirect based on user role
        if (authState is AuthAuthenticated) {
          print('✅ Router: User authenticated');
          final user = authState.user;
          if (isLoggingIn || isRegistering) {
            // Redirect instructors to their dashboard, clients to instructor selection
            if (user.isInstructor) {
              print('🔄 Router: Redirecting instructor to /instructor-dashboard');
              return '/instructor-dashboard';
            } else {
              print('🔄 Router: Redirecting client to /client/instructor-selection');
              return '/client/instructor-selection';
            }
          }
          // Also redirect from root path based on role
          if (state.uri.path == '/') {
            if (user.isInstructor) {
              print('🔄 Router: Redirecting instructor from root to /instructor-dashboard');
              return '/instructor-dashboard';
            } else {
              print('🔄 Router: Redirecting client from root to /client/instructor-selection');
              return '/client/instructor-selection';
            }
          }
          print('✅ Router: No redirect needed - user can access current route');
          return null; // Allow navigation to other routes
        }
        
        // If not authenticated, redirect to login (except for login/register pages)
        if (authState is AuthUnauthenticated) {
          print('❌ Router: User not authenticated');
          if (!isLoggingIn && !isRegistering) {
            print('🔄 Router: Redirecting to /login');
            return '/login';
          }
          print('✅ Router: Allowing access to ${state.uri.path}');
          return null; // Allow login/register
        }
        
        print('❓ Router: Unknown auth state - no redirect');
        return null;
      } catch (e) {
        // If there's an error reading the auth state, don't redirect
        AppLogger.error('⚠️ Error in router redirect: $e');
        return null;
      }
    },
  );
}

Future<Map<String, dynamic>?> _loadTemplate(String templateId) async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection('bookable_sessions')
        .doc(templateId)
        .get();
    
    if (doc.exists) {
      return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
    }
    return null;
  } catch (e) {
    throw Exception('Failed to load template: $e');
  }
}


