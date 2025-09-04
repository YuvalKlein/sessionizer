import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/services/user_service.dart';
import 'package:myapp/ui/login_screen.dart';
import 'package:myapp/ui/registration_screen.dart';
import 'package:myapp/ui/profile_screen.dart';
import 'package:myapp/ui/instructor_dashboard_screen.dart';
import 'package:myapp/ui/instructor_booking_management_screen.dart';
import 'package:myapp/ui/client_dashboard_screen.dart';
import 'package:myapp/ui/client_booking_management_screen.dart';
import 'package:myapp/ui/booking_screen.dart';
import 'package:myapp/ui/enhanced_booking_screen.dart';
import 'package:myapp/ui/schedules_list_screen.dart';
import 'package:myapp/ui/schedule_detail_screen.dart';
import 'package:myapp/ui/schedulable_sessions_screen.dart';
import 'package:myapp/ui/schedulable_session_form_screen.dart';
import 'package:myapp/ui/availability_demo_screen.dart';
import 'package:myapp/ui/instructor/schedule_form_screen.dart';
import 'package:myapp/ui/instructor/manage_sessions_screen.dart';
import 'package:myapp/ui/session_types_screen.dart';
import 'package:myapp/ui/locations_screen.dart';
import 'package:myapp/ui/main_screen.dart';
import 'package:provider/provider.dart';

class AppRouter {
  final AuthService authService;

  AppRouter(this.authService);

  late final GoRouter router = GoRouter(
    refreshListenable: authService,
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        redirect: (context, state) async {
          final user = authService.currentUser;
          if (user == null) {
            return '/login';
          }
          final userModel = await context.read<UserService>().getUser(user.uid);
          if (userModel?.isInstructor ?? false) {
            return '/instructor';
          } else {
            return '/client';
          }
        },
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MainScreen(child: child);
        },
        routes: [
          GoRoute(
            path: '/instructor',
            builder: (BuildContext context, GoRouterState state) {
              return const InstructorDashboardScreen();
            },
            routes: [
              GoRoute(
                path: 'manage-sessions',
                builder: (BuildContext context, GoRouterState state) {
                  return const ManageSessionsScreen();
                },
              ),
              GoRoute(
                path: 'bookings',
                builder: (BuildContext context, GoRouterState state) {
                  return const InstructorBookingManagementScreen();
                },
              ),
              GoRoute(
                path: 'session-types',
                builder: (BuildContext context, GoRouterState state) {
                  return const SessionTypesScreen();
                },
              ),
              GoRoute(
                path: 'locations',
                builder: (BuildContext context, GoRouterState state) {
                  return const LocationsScreen();
                },
              ),
              GoRoute(
                path: 'schedules',
                builder: (BuildContext context, GoRouterState state) {
                  return SchedulesListScreen(
                    instructorId: authService.currentUser!.uid,
                  );
                },
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (BuildContext context, GoRouterState state) {
                      return const ScheduleFormScreen();
                    },
                  ),
                  GoRoute(
                    path: ':scheduleId',
                    builder: (BuildContext context, GoRouterState state) {
                      final scheduleId = state.pathParameters['scheduleId']!;
                      return ScheduleDetailScreen(scheduleId: scheduleId);
                    },
                  ),
                ],
              ),
              GoRoute(
                path: 'schedulable-sessions',
                builder: (BuildContext context, GoRouterState state) {
                  return const SchedulableSessionsScreen();
                },
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (BuildContext context, GoRouterState state) {
                      return const SchedulableSessionFormScreen();
                    },
                  ),
                  GoRoute(
                    path: ':schedulableSessionId',
                    builder: (BuildContext context, GoRouterState state) {
                      final schedulableSessionId = state.pathParameters['schedulableSessionId']!;
                      return SchedulableSessionFormScreen(schedulableSessionId: schedulableSessionId);
                    },
                  ),
                  GoRoute(
                    path: ':schedulableSessionId/edit',
                    builder: (BuildContext context, GoRouterState state) {
                      final schedulableSessionId = state.pathParameters['schedulableSessionId']!;
                      return SchedulableSessionFormScreen(schedulableSessionId: schedulableSessionId);
                    },
                  ),
                ],
              ),
              GoRoute(
                path: 'availability-demo',
                builder: (BuildContext context, GoRouterState state) {
                  return const AvailabilityDemoScreen();
                },
              ),
            ],
          ),
          GoRoute(
            path: '/client',
            builder: (BuildContext context, GoRouterState state) {
              return const ClientDashboardScreen();
            },
          ),
          GoRoute(
            path: '/client/bookings',
            builder: (BuildContext context, GoRouterState state) {
              return const ClientBookingManagementScreen();
            },
          ),
          GoRoute(
            path: '/profile',
            builder: (BuildContext context, GoRouterState state) {
              return const ProfileScreen();
            },
          ),
          GoRoute(
            path: '/booking/:instructorId',
            builder: (BuildContext context, GoRouterState state) {
              final instructorId = state.pathParameters['instructorId']!;
              return EnhancedBookingScreen(instructorId: instructorId);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/login',
        builder: (BuildContext context, GoRouterState state) {
          return const LoginScreen();
        },
      ),
      GoRoute(
        path: '/register',
        builder: (BuildContext context, GoRouterState state) {
          return const RegistrationScreen();
        },
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) async {
      final bool loggedIn = authService.currentUser != null;
      final String location = state.matchedLocation;
      final bool loggingIn = location == '/login' || location == '/register';

      if (!loggedIn) {
        return loggingIn ? null : '/login';
      }

      final isInitial = state.matchedLocation == '/';
      if (loggedIn && (loggingIn || isInitial)) {
        final userModel = await context.read<UserService>().getUser(authService.currentUser!.uid);
        if (userModel?.isInstructor ?? false) {
          return '/instructor';
        } else {
          return '/client';
        }
      }

      return null;
    },
  );
}
