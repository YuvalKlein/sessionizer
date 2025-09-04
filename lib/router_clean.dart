import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:myapp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:myapp/features/auth/presentation/bloc/auth_state.dart';
import 'package:myapp/features/auth/presentation/pages/login_page.dart';
import 'package:myapp/features/auth/presentation/pages/signup_page.dart';
import 'package:myapp/features/main/presentation/pages/main_screen_clean.dart';
import 'package:myapp/features/main/presentation/pages/profile_page.dart';
import 'package:myapp/features/main/presentation/pages/instructor_dashboard_page.dart';
import 'package:myapp/features/main/presentation/pages/client_dashboard_page.dart';
import 'package:myapp/features/main/presentation/pages/client_bookings_page.dart';
import 'package:myapp/features/main/presentation/pages/client_sessions_page.dart';
import 'package:myapp/core/utils/injection_container.dart';

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
        builder: (context, state) => const MainScreenClean(child: ProfilePage()),
      ),
      GoRoute(
        path: '/instructor-dashboard',
        builder: (context, state) => const MainScreenClean(child: InstructorDashboardPage()),
      ),
      GoRoute(
        path: '/client-dashboard',
        builder: (context, state) => const MainScreenClean(child: ClientDashboardPage()),
      ),
      GoRoute(
        path: '/client/bookings',
        builder: (context, state) => const MainScreenClean(child: ClientBookingsPage()),
      ),
      GoRoute(
        path: '/client/sessions',
        builder: (context, state) => const MainScreenClean(child: ClientSessionsPage()),
      ),
    ],
    redirect: (context, state) {
      try {
        final authBloc = context.read<AuthBloc>();
        final authState = authBloc.state;
        
        final isLoggingIn = state.uri.path == '/login';
        final isRegistering = state.uri.path == '/register';
        
        // Only redirect if auth state is not loading
        if (authState is AuthLoading) {
          return null; // Let the loading state show
        }
        
        // If authenticated, redirect from login/register to dashboard
        if (authState is AuthAuthenticated) {
          if (isLoggingIn || isRegistering) {
            return '/client-dashboard';
          }
          return null; // Allow navigation to other routes
        }
        
        // If not authenticated, redirect to login (except for login/register pages)
        if (authState is AuthUnauthenticated) {
          if (!isLoggingIn && !isRegistering) {
            return '/login';
          }
          return null; // Allow login/register
        }
        
        return null;
      } catch (e) {
        // If there's an error reading the auth state, don't redirect
        print('⚠️ Error in router redirect: $e');
        return null;
      }
    },
  );
}
