// lib/services/theme_service.dart

import 'package:flutter/material.dart';
import 'package:dashymobile/services/settings_service.dart';

class ThemeService {
  // A ValueNotifier holds a value and notifies listeners when it changes.
  final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(
    ThemeMode.dark,
  );

  final SettingsService _settingsService = SettingsService();

  Future<void> loadTheme() async {
    final isDarkMode = await _settingsService.getDarkModeEnabled();
    themeModeNotifier.value = isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggleTheme(bool isDarkMode) async {
    themeModeNotifier.value = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    await _settingsService.saveDarkModeEnabled(isDarkMode);
  }
}

// Create a single, global instance of the service that the whole app can use.
final themeService = ThemeService();
