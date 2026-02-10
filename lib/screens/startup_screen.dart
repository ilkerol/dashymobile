// lib/screens/startup_screen.dart

import 'package:flutter/material.dart';
import 'package:dashymobile/services/settings_service.dart';
import 'package:dashymobile/screens/home_screen.dart';
import 'package:dashymobile/screens/settings_screen.dart';

/// A temporary screen shown on app launch to determine the initial route.
///
/// This screen checks if the application has been configured with server details.
/// It then navigates the user to the [HomeScreen] if configured, or to the
/// [SettingsScreen] for first-time setup.
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

  /// Checks for saved server IP addresses and navigates accordingly.
  Future<void> _checkConfigAndNavigate() async {
    final settings = SettingsService();
    final localIp = await settings.getLocalWlanIp();
    final zeroTierIp = await settings.getZeroTierIp();
    final reverseProxyUrl = await settings.getReverseProxyUrl();

    // A small delay to prevent a jarring screen flash on fast device storage.
    await Future.delayed(const Duration(milliseconds: 500));

    // A safety check to ensure the widget is still in the tree before navigating.
    if (!mounted) return;

    // The app is considered configured if at least one connection method is saved.
    final bool isConfigured =
        (localIp != null && localIp.isNotEmpty) ||
        (zeroTierIp != null && zeroTierIp.isNotEmpty) ||
        (reverseProxyUrl != null && reverseProxyUrl.isNotEmpty);

    if (isConfigured) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      // If not configured, navigate to the settings screen in "first time setup" mode.
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
    // Display a simple loading indicator to serve as a splash screen
    // while the configuration check is in progress.
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
