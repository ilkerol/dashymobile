// lib/services/theme_service.dart

import 'package:flutter/material.dart';
import 'package:dashymobile/services/settings_service.dart';

/// A service to manage the application's visual theme (light/dark mode).
///
/// It encapsulates the logic for loading, saving, and updating the theme
/// preference, and notifies the UI of any changes.
class ThemeService {
  /// A [ValueNotifier] that holds the current [ThemeMode].
  ///
  /// Widgets can listen to this notifier to automatically rebuild when the
  /// theme changes. It is initialized to [ThemeMode.dark] as a default.
  final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(
    ThemeMode.dark,
  );

  final SettingsService _settingsService = SettingsService();

  /// Loads the saved theme preference from storage and updates the notifier.
  ///
  /// This should be called once on app startup to restore the user's last
  /// selected theme.
  Future<void> loadTheme() async {
    final isDarkMode = await _settingsService.getDarkModeEnabled();
    themeModeNotifier.value = isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  /// Toggles the theme between light and dark mode.
  ///
  /// This updates the notifier to immediately change the app's theme and also
  /// saves the new preference to persistent storage.
  Future<void> toggleTheme(bool isDarkMode) async {
    themeModeNotifier.value = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    await _settingsService.saveDarkModeEnabled(isDarkMode);
  }
}

/// A single, global instance of the [ThemeService].
///
/// This singleton pattern allows any part of the app to access the theme
/// service easily without needing to pass it down the widget tree or use a

/// dependency injection framework.
final themeService = ThemeService();
