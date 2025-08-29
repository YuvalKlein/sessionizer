import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/ui/main_screen.dart'; // Updated import
import 'package:myapp/ui/login_screen.dart';
import 'package:myapp/ui/registration_screen.dart';
import 'package:myapp/ui/schedule_screen.dart';

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

final GoRouter router = GoRouter(
  refreshListenable: GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),
  redirect: (BuildContext context, GoRouterState state) {
    final bool loggedIn = FirebaseAuth.instance.currentUser != null;
    final bool onAuthScreen = state.matchedLocation == '/login' || state.matchedLocation == '/register';

    if (!loggedIn && !onAuthScreen) {
      return '/login';
    }

    if (loggedIn && onAuthScreen) {
      return '/';
    }

    return null;
  },
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const MainScreen(); // Updated to MainScreen
      },
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
      path: '/schedule',
      builder: (BuildContext context, GoRouterState state) {
        return const ScheduleScreen();
      },
    ),
  ],
);
