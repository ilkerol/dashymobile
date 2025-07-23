// lib/main.dart

import 'package:flutter/material.dart';
import 'package:dashymobile/screens/startup_screen.dart'; // Import startup screen

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dashy Mobile',
      theme: ThemeData.dark(useMaterial3: true),
      // Set the StartupScreen as the initial route for the app
      home: const StartupScreen(),
    );
  }
}
