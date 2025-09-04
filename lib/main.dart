import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/core/utils/injection_container.dart';
import 'package:myapp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:myapp/features/auth/presentation/bloc/auth_event.dart';
import 'package:myapp/features/auth/presentation/bloc/auth_state.dart';
import 'package:myapp/router_clean.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDependencies();
  runApp(const MyApp());
}

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>(
          create: (_) => AuthService(
            FirebaseAuth.instance,
            firestore: FirebaseFirestore.instance,
            googleSignIn: GoogleSignIn(
              clientId: DefaultFirebaseOptions.currentPlatform.appId,
            ),
          ),
        ),
        Provider<UserService>(create: (_) => UserService()),
        Provider<ScheduleService>(create: (_) => ScheduleService()),
        ChangeNotifierProvider<BookingService>(create: (_) => BookingService()),
        Provider<SessionService>(
          create: (_) => SessionService(FirebaseFirestore.instance),
        ),
        Provider<SchedulableSessionService>(create: (_) => SchedulableSessionService()),
        Provider<SessionTypeService>(create: (_) => SessionTypeService()),
        ChangeNotifierProvider<AvailabilityService>(
          create: (context) => AvailabilityService(
            scheduleService: context.read<ScheduleService>(),
            schedulableSessionService: context.read<SchedulableSessionService>(),
            sessionTypeService: context.read<SessionTypeService>(),
            bookingService: context.read<BookingService>(),
          ),
        ),
        ChangeNotifierProvider<ScheduleViewModel>(
          create: (context) =>
              ScheduleViewModel(context.read<ScheduleService>()),
        ),
        ChangeNotifierProvider<SessionViewModel>(
          create: (context) => SessionViewModel(context.read<SessionService>()),
        ),
        ChangeNotifierProvider<SchedulableSessionViewModel>(
          create: (context) => SchedulableSessionViewModel(context.read<SchedulableSessionService>()),
        ),
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        ProxyProvider<AuthService, GoRouter>(
          update: (context, authService, _) => AppRouter(authService).router,
        ),
      ],
      child: const AppMaterial(),
    );
  }
}

class AppMaterial extends StatelessWidget {
  const AppMaterial({super.key});

  @override
  Widget build(BuildContext context) {
    final router = Provider.of<GoRouter>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    const primarySeedColor = Colors.deepPurple;
    final textTheme = TextTheme(
      displayLarge: GoogleFonts.oswald(
        fontSize: 57,
        fontWeight: FontWeight.bold,
      ),
      titleLarge: GoogleFonts.roboto(fontSize: 22, fontWeight: FontWeight.w500),
      bodyMedium: GoogleFonts.openSans(fontSize: 14),
    );

    final lightTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primarySeedColor,
        brightness: Brightness.light,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: primarySeedColor,
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.oswald(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    final darkTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primarySeedColor,
        brightness: Brightness.dark,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.oswald(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    return MaterialApp.router(
      title: 'SchedulEasy',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeProvider.themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
