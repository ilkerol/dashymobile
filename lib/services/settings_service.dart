// lib/services/settings_service.dart
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// A service that manages persistent app settings using secure storage.
class SettingsService {
  final _storage = const FlutterSecureStorage();
  static const String _keyLocalWlanIp = 'localWlanIp';
  static const String _keyZeroTierIp = 'zeroTierIp';
  static const String _keyDashyPort = 'dashyPort';
  static const String _keyDarkModeEnabled = 'darkModeEnabled';
  static const String _keySelectedSections = 'selectedSections';
  static const String _keyShowCaptions = 'showCaptions';
  static const String _keyGlancesUrl = 'glancesUrl'; // CHANGED
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
  Future<void> saveSelectedSections(List<String> sectionNames) async {
    final String jsonString = jsonEncode(sectionNames);
    await _storage.write(key: _keySelectedSections, value: jsonString);
  }

  Future<List<String>> getSelectedSections() async {
    final sectionsString = await _storage.read(key: _keySelectedSections);
    if (sectionsString == null || sectionsString.isEmpty) return [];
    try {
      final List<dynamic> decodedList = jsonDecode(sectionsString);
      return decodedList.cast<String>().toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveDarkModeEnabled(bool enabled) async =>
      await _storage.write(key: _keyDarkModeEnabled, value: enabled.toString());
  Future<bool> getDarkModeEnabled() async =>
      await _storage.read(key: _keyDarkModeEnabled) == 'true';
  Future<void> saveShowCaptions(bool enabled) async =>
      await _storage.write(key: _keyShowCaptions, value: enabled.toString());
  Future<bool> getShowCaptions() async =>
      await _storage.read(key: _keyShowCaptions) == 'true';
  // NEW Methods for a single Glances URL
  /// Saves the user's Glances instance full base URL.
  Future<void> saveGlancesUrl(String url) async =>
      await _storage.write(key: _keyGlancesUrl, value: url);

  /// Retrieves the user's Glances instance full base URL.
  Future<String?> getGlancesUrl() async =>
      await _storage.read(key: _keyGlancesUrl);
}
