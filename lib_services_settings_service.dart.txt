// lib/services/settings_service.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SettingsService {
  final _storage = const FlutterSecureStorage();

  static const String _keyLocalWlanIp = 'localWlanIp';
  static const String _keyZeroTierIp = 'zeroTierIp';
  static const String _keyDashyPort = 'dashyPort';
  static const String _keyDarkModeEnabled = 'darkModeEnabled';
  // NEW: Key for the selected sections
  static const String _keySelectedSections = 'selectedSections';

  // --- URL & Port Management ---
  Future<void> saveLocalWlanIp(String ip) async =>
      await _storage.write(key: _keyLocalWlanIp, value: ip);
  Future<String?> getLocalWlanIp() async =>
      await _storage.read(key: _keyLocalWlanIp);
  Future<void> saveZeroTierIp(String ip) async =>
      await _storage.write(key: _keyZeroTierIp, value: ip);
  Future<String?> getZeroTierIp() async =>
      await _storage.read(key: _keyZeroTierIp);
  Future<void> saveDashyPort(String port) async =>
      await _storage.write(key: _keyDashyPort, value: port);
  Future<String?> getDashyPort() async =>
      await _storage.read(key: _keyDashyPort);

  // --- NEW: Section Management ---
  // Takes a list of section names and saves them as a single string
  Future<void> saveSelectedSections(List<String> sectionNames) async {
    await _storage.write(
      key: _keySelectedSections,
      value: sectionNames.join(','),
    );
  }

  // Reads the string and splits it back into a list of names
  Future<List<String>> getSelectedSections() async {
    final sectionsString = await _storage.read(key: _keySelectedSections);
    // Return an empty list if nothing is stored
    if (sectionsString == null || sectionsString.isEmpty) {
      return [];
    }
    return sectionsString.split(',');
  }

  // --- Dark Mode Management ---
  Future<void> saveDarkModeEnabled(bool enabled) async =>
      await _storage.write(key: _keyDarkModeEnabled, value: enabled.toString());
  Future<bool> getDarkModeEnabled() async =>
      await _storage.read(key: _keyDarkModeEnabled) == 'true';
}
