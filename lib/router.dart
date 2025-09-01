import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/services/user_service.dart';
import 'package:myapp/ui/login_screen.dart';
import 'package:myapp/ui/registration_screen.dart';
import 'package:myapp/ui/profile_screen.dart';
import 'package:myapp/ui/instructor_dashboard_screen.dart';
import 'package:myapp/ui/client_dashboard_screen.dart';
import 'package:myapp/ui/booking_screen.dart';
import 'package:myapp/ui/schedules_list_screen.dart';
import 'package:myapp/ui/instructor/manage_sessions_screen.dart';
import 'package:myapp/ui/session_types_screen.dart';
import 'package:myapp/ui/locations_screen.dart';
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
        builder: (BuildContext context, GoRouterState state) {
          // The redirect logic ensures the user is authenticated here.
          // We just need to decide which dashboard to show.
          return FutureBuilder<UserModel?>(
            future: context.read<UserService>().getUser(
              authService.currentUser!.uid,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              // Handle case where user data might fail to load
              if (snapshot.hasError ||
                  !snapshot.hasData ||
                  snapshot.data == null) {
                // Optional: Show an error screen or default to a client dashboard
                return const ClientDashboardScreen();
              }

              if (snapshot.data!.isInstructor) {
                return const InstructorDashboardScreen();
              } else {
                return const ClientDashboardScreen();
              }
            },
          );
        },
        routes: <RouteBase>[
          GoRoute(
            path: 'profile',
            builder: (BuildContext context, GoRouterState state) {
              return const ProfileScreen();
            },
          ),
          GoRoute(
            path: 'instructor/manage-sessions',
            builder: (BuildContext context, GoRouterState state) {
              return const ManageSessionsScreen();
            },
          ),
          GoRoute(
            path: 'instructor/session-types',
            builder: (BuildContext context, GoRouterState state) {
              return const SessionTypesScreen();
            },
          ),
          GoRoute(
            path: 'instructor/locations',
            builder: (BuildContext context, GoRouterState state) {
              return const LocationsScreen();
            },
          ),
          GoRoute(
            path: 'instructor/schedules',
            builder: (BuildContext context, GoRouterState state) {
              return SchedulesListScreen(
                instructorId: authService.currentUser!.uid,
              );
            },
          ),
          GoRoute(
            path: 'booking/:instructorId',
            builder: (BuildContext context, GoRouterState state) {
              final instructorId = state.pathParameters['instructorId']!;
              return BookingScreen(instructorId: instructorId);
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
      final bool loggingIn =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      // If user is not logged in and not on a login page, redirect to login.
      if (!loggedIn) {
        return loggingIn ? null : '/login';
      }

      // If user is logged in but on a login page, redirect to home.
      if (loggingIn) {
        return '/';
      }

      // No redirect needed.
      return null;
    },
  );
}
