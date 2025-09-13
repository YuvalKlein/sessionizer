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
import 'package:myapp/features/feedback/presentation/widgets/floating_feedback_button.dart';

class MainScreen extends StatefulWidget {
  final Widget child;
  final String? instructorId;

  const MainScreen({super.key, required this.child, this.instructorId});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  UserBloc? _userBloc;
  String? _currentUserId;
  String? _instructorName;

  @override
  void initState() {
    super.initState();
    if (widget.instructorId != null) {
      _loadInstructorName();
    }
  }

  @override
  void dispose() {
    AppLogger.widgetBuild('MainScreenClean', data: {'action': 'dispose'});
    _userBloc?.close();
    super.dispose();
  }

  Future<void> _loadInstructorName() async {
    try {
      final userRepository = sl<UserRepository>();
      final result = await userRepository.getUserById(widget.instructorId!);
      if (mounted) {
        result.fold(
          (failure) {
            print('Error loading instructor name: ${failure.message}');
            setState(() {
              _instructorName = 'Instructor';
            });
          },
          (instructor) {
            setState(() {
              _instructorName = instructor.displayName ?? 'Instructor';
            });
          },
        );
      }
    } catch (e) {
      print('Error loading instructor name: $e');
      if (mounted) {
        setState(() {
          _instructorName = 'Instructor';
        });
      }
    }
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
                  String title;
                  if (isInstructor) {
                    title = 'Instructor Dashboard';
                  } else if (widget.instructorId != null && _instructorName != null) {
                    title = 'Dashboard - $_instructorName';
                  } else {
                    title = 'Client Dashboard';
                  }

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
                    body: Stack(
                      children: [
                        widget.child,
                        const FloatingFeedbackButton(),
                      ],
                    ),
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
          // Instructor profile - for now use the old profile, can be updated later
          context.go('/profile');
          break;
      }
    } else {
      switch (index) {
        case 0:
          context.go('/client-dashboard?instructorId=1ftCSRo1JBQR23NpQy5digDt1tm2');
          break;
        case 1:
          context.go('/client/bookings');
          break;
        case 2:
          // Client profile - use the new client profile with Google Calendar sync
          context.go('/client/profile');
          break;
      }
    }
  }
}
