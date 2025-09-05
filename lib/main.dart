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
import 'package:myapp/router.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
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
