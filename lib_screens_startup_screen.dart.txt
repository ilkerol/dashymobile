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
    final localIp = await settings.getLocalWlanIp();
    final zeroTierIp = await settings.getZeroTierIp();

    // Give a small delay to prevent a jarring screen flash on fast checks
    await Future.delayed(const Duration(milliseconds: 500));

    // If there's no context, it means the widget was removed. Do nothing.
    if (!mounted) return;

    // Check if at least one of the IPs has been set
    final bool isConfigured =
        (localIp != null && localIp.isNotEmpty) ||
        (zeroTierIp != null && zeroTierIp.isNotEmpty);

    if (isConfigured) {
      // If configured, go to the HomeScreen.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      // If not configured, this is a first-time setup. Go to settings.
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
    // Show a simple loading indicator while we check the config
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
