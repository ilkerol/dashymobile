// lib/services/settings_service.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SettingsService {
  final _storage = const FlutterSecureStorage();

  // Keys for secure storage (SSID key removed)
  static const String _keyLocalWlanIp = 'localWlanIp';
  static const String _keyZeroTierIp = 'zeroTierIp';
  static const String _keyDashyPort = 'dashyPort';
  static const String _keySelectedSections = 'selectedSections';
  static const String _keyDarkModeEnabled = 'darkModeEnabled';

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

  // --- Section Management (for later) ---
  Future<void> saveSelectedSections(List<String> sectionNames) async =>
      await _storage.write(
        key: _keySelectedSections,
        value: sectionNames.join(','),
      );
  Future<List<String>> getSelectedSections() async {
    final sections = await _storage.read(key: _keySelectedSections);
    return sections?.split(',').where((s) => s.isNotEmpty).toList() ?? [];
  }

  // --- Dark Mode Management (for later) ---
  Future<void> saveDarkModeEnabled(bool enabled) async =>
      await _storage.write(key: _keyDarkModeEnabled, value: enabled.toString());
  Future<bool> getDarkModeEnabled() async =>
      await _storage.read(key: _keyDarkModeEnabled) == 'true';
}
