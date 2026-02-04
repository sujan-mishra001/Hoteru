import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dautari_adda/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:dautari_adda/features/home/presentation/screens/main_navigation_screen.dart';
import 'package:dautari_adda/features/auth/presentation/screens/login_screen.dart';
import 'package:dautari_adda/features/auth/presentation/screens/branch_selection_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/services/notification_service.dart';

import 'package:dautari_adda/core/theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: ".env");

  // Initialize Services
  await NotificationService().init();
  await ThemeProvider().init();

  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

  runApp(MyApp(isLoggedIn: isLoggedIn, hasSeenOnboarding: hasSeenOnboarding));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final bool hasSeenOnboarding;
  
  const MyApp({super.key, required this.isLoggedIn, required this.hasSeenOnboarding});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeProvider(),
      builder: (context, _) {
        final isDark = ThemeProvider().isDarkMode;
        
        return MaterialApp(
          title: 'Dautari Adda',
          debugShowCheckedModeBanner: false,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFFC107)),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFFFC107),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          home: isLoggedIn 
              ? const BranchSelectionScreen() 
              : (hasSeenOnboarding ? const LoginScreen() : const OnboardingScreen()),
        );
      },
    );
  }
}

