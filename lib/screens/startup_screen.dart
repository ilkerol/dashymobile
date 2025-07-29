// lib/screens/startup_screen.dart

import 'package:flutter/material.dart';
import 'package:dashymobile/services/settings_service.dart';
import 'package:dashymobile/screens/home_screen.dart';
import 'package:dashymobile/screens/settings_screen.dart';

class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  @override
  void initState() {
    super.initState();
    _checkConfigAndNavigate();
  }

  Future<void> _checkConfigAndNavigate() async {
    final settings = SettingsService();
    final localUrl = await settings.getLocalDashyUrl();
    final secondaryUrl = await settings.getSecondaryDashyUrl();

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    final bool isConfigured =
        (localUrl != null && localUrl.isNotEmpty) ||
        (secondaryUrl != null && secondaryUrl.isNotEmpty);

    if (isConfigured) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const SettingsScreen(isFirstTimeSetup: true),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
