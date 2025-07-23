// lib/main.dart

import 'package:flutter/material.dart';
import 'package:dashymobile/screens/startup_screen.dart';
import 'package:dashymobile/services/theme_service.dart';

// The main entry point for the application.
// It is marked `async` to allow for setup tasks before the app runs.
Future<void> main() async {
  // Ensure the Flutter framework is initialized before any Flutter-specific code.
  WidgetsFlutterBinding.ensureInitialized();

  // Load the user's saved theme preference on startup.
  await themeService.loadTheme();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Use AnimatedBuilder to listen for changes in the theme service.
    // This efficiently rebuilds MaterialApp when the theme is updated,
    // without rebuilding the entire widget tree.
    return AnimatedBuilder(
      animation: themeService.themeModeNotifier,
      builder: (context, child) {
        return MaterialApp(
          title: 'Dashy Mobile',
          // The light theme configuration for the app.
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorSchemeSeed: Colors.blue,
          ),
          // The dark theme configuration for the app.
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorSchemeSeed: Colors.blue,
          ),
          // The current theme mode is determined by the theme service.
          themeMode: themeService.themeModeNotifier.value,
          // The initial screen of the application.
          home: const StartupScreen(),
        );
      },
    );
  }
}
