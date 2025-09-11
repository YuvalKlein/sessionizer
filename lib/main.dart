import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/core/utils/injection_container.dart';
import 'package:myapp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:myapp/features/auth/presentation/bloc/auth_event.dart';
import 'package:myapp/features/auth/presentation/bloc/auth_state.dart';
import 'package:myapp/features/user/presentation/bloc/user_bloc.dart';
import 'package:myapp/features/booking/presentation/bloc/booking_bloc.dart';
import 'package:myapp/router.dart';
import 'package:myapp/core/config/environment.dart';
import 'package:myapp/core/config/environment_config.dart';
import 'firebase_options.dart';
import 'firebase_options_production.dart' as prod;
import 'firebase_options_development.dart' as dev;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with apiclientapp project for development
  final environment = EnvironmentConfig.current;
  
  if (environment == Environment.development) {
    // Use apiclientapp project for development
    final firebaseOptions = dev.DefaultFirebaseOptions.currentPlatform;
    print('🔧 Initializing Firebase for DEVELOPMENT (apiclientapp)');
    print('🔧 Environment Name: development');
    print('🔧 Project Name: apiclientapp');
    await Firebase.initializeApp(options: firebaseOptions);
  } else {
    // Use default firebase_options.dart for production (play-e37a6)
    print('🚀 Initializing Firebase for PRODUCTION (play-e37a6)');
    print('🚀 Environment Name: production');
    print('🚀 Project Name: play-e37a6');
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
  
  // Initialize Firebase Messaging
  await FirebaseMessaging.instance.requestPermission();
  
  await initializeDependencies();
  runApp(const MyAppClean());
}

class MyAppClean extends StatelessWidget {
  const MyAppClean({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => sl<AuthBloc>()..add(AuthCheckRequested()),
        ),
        BlocProvider(
          create: (context) => sl<UserBloc>(),
        ),
        BlocProvider(
          create: (context) => sl<BookingBloc>(),
        ),
      ],
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          return MaterialApp.router(
            title: 'Sessionizer',
            theme: ThemeData(
              primarySwatch: Colors.blue,
              textTheme: GoogleFonts.interTextTheme(),
              useMaterial3: true,
            ),
            routerConfig: AppRouter.router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
