// lib/main.dart

import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // FOR NOW: We hard-code the URL. We will make this configurable later.
  final String dashyBaseUrl = 'http://192.168.178.52:4444'; // <-- CHANGE THIS

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dashy Mobile',
      theme: ThemeData.dark(useMaterial3: true), // A dark theme to match Dashy
      home: HomeScreen(dashyUrl: dashyBaseUrl),
    );
  }
}
