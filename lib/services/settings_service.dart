// lib/services/settings_service.dart

import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// A service that manages persistent app settings using secure storage.
///
/// This acts as a wrapper around [FlutterSecureStorage] to provide a typed API
/// for saving and retrieving all user-configurable data.
class SettingsService {
  final _storage = const FlutterSecureStorage();

  // Define keys to prevent typos and centralize key management.
  static const String _keyLocalWlanIp = 'localWlanIp';
  static const String _keyZeroTierIp = 'zeroTierIp';
  static const String _keyDashyPort = 'dashyPort';
  static const String _keyDarkModeEnabled = 'darkModeEnabled';
  static const String _keySelectedSections = 'selectedSections';

  /// Saves the user's local WLAN IP address.
  Future<void> saveLocalWlanIp(String ip) async =>
      await _storage.write(key: _keyLocalWlanIp, value: ip);

  /// Retrieves the user's local WLAN IP address. Returns null if not set.
  Future<String?> getLocalWlanIp() async =>
      await _storage.read(key: _keyLocalWlanIp);

  /// Saves the user's ZeroTier (or other secondary) IP address.
  Future<void> saveZeroTierIp(String ip) async =>
      await _storage.write(key: _keyZeroTierIp, value: ip);

  /// Retrieves the user's ZeroTier IP address. Returns null if not set.
  Future<String?> getZeroTierIp() async =>
      await _storage.read(key: _keyZeroTierIp);

  /// Saves the user's Dashy instance port number.
  Future<void> saveDashyPort(String port) async =>
      await _storage.write(key: _keyDashyPort, value: port);

  /// Retrieves the user's Dashy instance port number. Returns null if not set.
  Future<String?> getDashyPort() async =>
      await _storage.read(key: _keyDashyPort);

  /// Saves the list of selected section names.
  ///
  /// The list is encoded into a JSON string to robustly handle special
  /// characters, such as commas, in section names.
  Future<void> saveSelectedSections(List<String> sectionNames) async {
    final String jsonString = jsonEncode(sectionNames);
    await _storage.write(key: _keySelectedSections, value: jsonString);
  }

  /// Retrieves the list of selected section names.
  ///
  /// Reads the JSON string and decodes it back into a list of strings.
  /// Returns an empty list if no sections have been saved.
  Future<List<String>> getSelectedSections() async {
    final sectionsString = await _storage.read(key: _keySelectedSections);
    if (sectionsString == null || sectionsString.isEmpty) {
      return [];
    }
    // Decode the JSON string and cast it to the correct type.
    try {
      final List<dynamic> decodedList = jsonDecode(sectionsString);
      return decodedList.cast<String>().toList();
    } catch (e) {
      // If decoding fails (e.g., due to corrupt data), return an empty list.
      return [];
    }
  }

  /// Saves the user's dark mode preference.
  Future<void> saveDarkModeEnabled(bool enabled) async =>
      await _storage.write(key: _keyDarkModeEnabled, value: enabled.toString());

  /// Retrieves the user's dark mode preference.
  ///
  /// Defaults to `false` (light mode) if the setting has never been saved.
  Future<bool> getDarkModeEnabled() async =>
      await _storage.read(key: _keyDarkModeEnabled) == 'true';
}
