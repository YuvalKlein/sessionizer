import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/ui/login_screen.dart';
import 'package:myapp/ui/main_screen.dart';
import 'package:myapp/ui/registration_screen.dart';
import 'package:myapp/ui/profile_screen.dart';
import 'package:myapp/ui/sessions_screen.dart';
import 'package:myapp/ui/set_screen.dart';
import 'package:myapp/ui/schedule_screen.dart';
import 'package:myapp/ui/post_list_screen.dart';
import 'package:myapp/ui/create_post_screen.dart';

class AppRouter {
  final AuthService authService;

  AppRouter(this.authService);

  late final GoRouter router = GoRouter(
    refreshListenable: GoRouterRefreshStream(authService.authStateChanges),
    initialLocation: '/login',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) {
          return const MainScreen();
        },
        routes: <RouteBase>[
          GoRoute(
            path: 'profile',
            builder: (BuildContext context, GoRouterState state) {
              return const ProfileScreen();
            },
          ),
          GoRoute(
            path: 'posts',
            builder: (BuildContext context, GoRouterState state) {
              return const PostListScreen();
            },
          ),
          GoRoute(
            path: 'create_post',
            builder: (BuildContext context, GoRouterState state) {
              return const CreatePostScreen();
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
      GoRoute(
        path: '/sessions',
        builder: (BuildContext context, GoRouterState state) {
          return const SessionsScreen();
        },
      ),
      GoRoute(
        path: '/set',
        builder: (BuildContext context, GoRouterState state) {
          return const SetScreen();
        },
      ),
      GoRoute(
        path: '/schedule',
        builder: (BuildContext context, GoRouterState state) {
          return const ScheduleScreen();
        },
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final bool loggedIn = authService.currentUser != null;
      final bool loggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/register';

      if (!loggedIn) {
        return loggingIn ? null : '/login';
      }

      if (loggingIn) {
        return '/';
      }

      return null;
    },
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
