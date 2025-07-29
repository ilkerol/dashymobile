// lib/services/settings_service.dart

import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SettingsService {
  final _storage = const FlutterSecureStorage();

  static const String _keyLocalDashyUrl = 'localDashyUrl';
  static const String _keySecondaryDashyUrl = 'secondaryDashyUrl';
  static const String _keyGlancesUrl = 'glancesUrl';
  static const String _keyDarkModeEnabled = 'darkModeEnabled';
  static const String _keySelectedSections = 'selectedSections';
  static const String _keyShowCaptions = 'showCaptions';

  Future<void> saveLocalDashyUrl(String url) async =>
      await _storage.write(key: _keyLocalDashyUrl, value: url);
  Future<String?> getLocalDashyUrl() async =>
      await _storage.read(key: _keyLocalDashyUrl);

  Future<void> saveSecondaryDashyUrl(String url) async =>
      await _storage.write(key: _keySecondaryDashyUrl, value: url);
  Future<String?> getSecondaryDashyUrl() async =>
      await _storage.read(key: _keySecondaryDashyUrl);

  Future<void> saveGlancesUrl(String url) async =>
      await _storage.write(key: _keyGlancesUrl, value: url);
  Future<String?> getGlancesUrl() async =>
      await _storage.read(key: _keyGlancesUrl);

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
}
