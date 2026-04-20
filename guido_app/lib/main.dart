import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'providers/auth_provider.dart';
import 'providers/code_practice_provider.dart';
import 'providers/course_provider.dart';
import 'providers/reminder_provider.dart';
import 'services/notification_service.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/settings_screen.dart';
import 'utils/navigation_key.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  
  try {
    final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
  } catch (e) {
    debugPrint('Could not get local timezone: $e');
  }
  
  await NotificationService().initializeNotifications();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CourseProvider()),
        ChangeNotifierProvider(create: (_) => CodePracticeProvider()),
        ChangeNotifierProvider(create: (_) => ReminderProvider()),
      ],
      child: const GuidoApp(),
    ),
  );
}

class GuidoApp extends StatelessWidget {
  const GuidoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
      useMaterial3: true,
    );

    return MaterialApp(
      title: 'Guido',
      debugShowCheckedModeBanner: false,
      theme: baseTheme.copyWith(
        textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme),
      ),
      navigatorKey: navigatorKey,
      initialRoute: '/splash',
      routes: {
        '/splash': (_) => const SplashScreen(),
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignupScreen(),
        '/home': (_) => const MainNavigationScreen(),
        '/admin-dashboard': (_) => const AdminDashboardScreen(),
        '/settings': (_) => const SettingsScreen(),
      },
    );
  }
}
