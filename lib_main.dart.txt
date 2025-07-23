// lib/main.dart

import 'package:flutter/material.dart';
import 'package:dashymobile/screens/startup_screen.dart';
import 'package:dashymobile/services/theme_service.dart'; // Import the service

// main is now async to load the theme before the app runs
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load the user's saved theme preference on startup
  await themeService.loadTheme();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // AnimatedBuilder listens to the themeService's notifier.
    // When the value changes, this builder runs again, rebuilding MaterialApp.
    return AnimatedBuilder(
      animation: themeService.themeModeNotifier,
      builder: (context, child) {
        return MaterialApp(
          title: 'Dashy Mobile',
          // Define both a light and dark theme
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorSchemeSeed: Colors.blue,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorSchemeSeed: Colors.blue,
          ),
          // Set the current mode from our service
          themeMode: themeService.themeModeNotifier.value,
          home: const StartupScreen(),
        );
      },
    );
  }
}
