import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:myapp/features/auth/presentation/bloc/auth_state.dart';
import 'package:myapp/features/auth/presentation/bloc/auth_event.dart';
import 'package:myapp/features/user/presentation/bloc/user_bloc.dart';
import 'package:myapp/features/user/presentation/bloc/user_event.dart';
import 'package:myapp/features/user/presentation/bloc/user_state.dart';
import 'package:myapp/core/utils/injection_container.dart';
import 'package:myapp/features/user/domain/usecases/get_instructors.dart';
import 'package:myapp/features/user/domain/usecases/get_user.dart';
import 'package:myapp/features/user/domain/repositories/user_repository.dart';
import 'package:myapp/core/utils/logger.dart';

class MainScreen extends StatefulWidget {
  final Widget child;

  const MainScreen({super.key, required this.child});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  UserBloc? _userBloc;
  String? _currentUserId;

  @override
  void dispose() {
    AppLogger.widgetBuild('MainScreenClean', data: {'action': 'dispose'});
    _userBloc?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, authState) {
        AppLogger.blocState('AuthBloc', authState.runtimeType.toString());
        
        if (authState is AuthUnauthenticated) {
          AppLogger.navigation('main-screen', 'login');
          context.go('/login');
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState is AuthLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (authState is AuthUnauthenticated) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

        if (authState is AuthError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${authState.message}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Go to Login'),
                  ),
                ],
              ),
            ),
          );
        }

        if (authState is AuthAuthenticated) {
          // Only create UserBloc if we don't have one or if the user ID changed
          if (_userBloc == null || _currentUserId != authState.user.id) {
            AppLogger.debug('🔄 Creating/Updating UserBloc for user: ${authState.user.id}');
            _userBloc?.close();
            _currentUserId = authState.user.id;
            _userBloc = UserBloc(
              getInstructors: sl<GetInstructors>(),
              getUser: sl<GetUser>(),
              userRepository: sl<UserRepository>(),
            )..add(LoadUser(userId: authState.user.id));
          }

          return BlocProvider<UserBloc>.value(
            value: _userBloc!,
            child: BlocBuilder<UserBloc, UserState>(
              builder: (context, userState) {
                AppLogger.blocState('UserBloc', userState.runtimeType.toString());
                
                if (userState is UserLoading) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                if (userState is UserError) {
                  return Scaffold(
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text('Error: ${userState.message}'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => context.go('/login'),
                            child: const Text('Go to Login'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (userState is UserLoaded) {
                  final user = userState.user;
                  final isInstructor = user.isInstructor;
                  final title = isInstructor ? 'Instructor Dashboard' : 'Client Dashboard';

                  return Scaffold(
                    appBar: AppBar(
                      title: Text(title),
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.notifications),
                          onPressed: () => context.go('/notifications'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout),
                          onPressed: () {
                            if (mounted) {
                              AppLogger.debug('🔄 Logout button pressed - triggering sign out');
                              context.read<AuthBloc>().add(SignOutRequested());
                            } else {
                              AppLogger.warning('⚠️ Widget not mounted - skipping sign out');
                            }
                          },
                        ),
                      ],
                    ),
                    body: widget.child,
                    bottomNavigationBar: BottomNavigationBar(
                      items: isInstructor ? const [
                        BottomNavigationBarItem(
                          icon: Icon(Icons.home),
                          label: 'Dashboard',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.person),
                          label: 'Profile',
                        ),
                      ] : const [
                        BottomNavigationBarItem(
                          icon: Icon(Icons.home),
                          label: 'Dashboard',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.calendar_today),
                          label: 'My Sessions',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.person),
                          label: 'Profile',
                        ),
                      ],
                      currentIndex: _calculateSelectedIndex(context, isInstructor),
                      onTap: (index) => _onItemTapped(index, context, isInstructor),
                      type: BottomNavigationBarType.fixed,
                    ),
                  );
                }

                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              },
            ),
          );
        }

        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context, bool isInstructor) {
    try {
      final location = GoRouterState.of(context).matchedLocation;
      if (location.startsWith('/profile')) {
        return isInstructor ? 1 : 2;
      } else if (location.startsWith('/client/bookings')) {
        return 1;
      }
      return 0;
    } catch (e) {
      // If GoRouterState is not available, return default index
      return 0;
    }
  }

  void _onItemTapped(int index, BuildContext context, bool isInstructor) {
    if (isInstructor) {
      switch (index) {
        case 0:
          context.go('/instructor-dashboard');
          break;
        case 1:
          context.go('/profile');
          break;
      }
    } else {
      switch (index) {
        case 0:
          context.go('/client/instructor-selection');
          break;
        case 1:
          context.go('/client/bookings');
          break;
        case 2:
          context.go('/profile');
          break;
      }
    }
  }
}
