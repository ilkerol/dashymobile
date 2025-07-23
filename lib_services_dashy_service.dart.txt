// lib/services/dashy_service.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:yaml/yaml.dart';
import 'package:dashymobile/models/dashboard_models.dart';
import 'package:dashymobile/services/settings_service.dart';

class DashyService {
  final SettingsService _settingsService = SettingsService();

  String? _activeBaseUrl;
  String? _localWlanIp;
  String? _zeroTierIp;

  // UPDATED: This function now sanitizes all inputs.
  Future<ConfigFetchResult> fetchAndParseConfig(List<String> urlsToTry) async {
    // 1. Load the raw values from settings
    final rawLocalIp = await _settingsService.getLocalWlanIp();
    final rawZeroTierIp = await _settingsService.getZeroTierIp();

    // 2. Sanitize them by trimming whitespace. This is the crucial fix.
    _localWlanIp = rawLocalIp?.trim();
    _zeroTierIp = rawZeroTierIp?.trim();

    // We re-check the provided URLs because they are built outside this service.
    for (String baseUrl in urlsToTry) {
      if (baseUrl.isEmpty) continue;

      try {
        final response = await http
            .get(Uri.parse('$baseUrl/conf.yml'))
            .timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          _activeBaseUrl = baseUrl;
          final sections = _parseConfig(response.body);
          return ConfigFetchResult(sections: sections, activeBaseUrl: baseUrl);
        }
      } catch (e) {
        debugPrint('Failed to connect to $baseUrl: $e');
      }
    }

    throw Exception('Could not connect to any of the provided Dashy URLs.');
  }

  List<DashboardSection> _parseConfig(String yamlContent) {
    final doc = loadYaml(yamlContent);
    final List<DashboardSection> sections = [];

    if (doc['sections'] is! YamlList) {
      throw Exception("Config file is missing a 'sections' list.");
    }

    for (final section in doc['sections']) {
      if (section.containsKey('items') && section['items'] is YamlList) {
        final List<ServiceItem> items = [];
        for (final item in section['items']) {
          if (item is! YamlMap) continue;

          String iconUrl = item['icon'] ?? '';
          if (iconUrl.isNotEmpty && !iconUrl.startsWith('http')) {
            final cleanIconPath = iconUrl.startsWith('/')
                ? iconUrl.substring(1)
                : iconUrl;
            iconUrl = '$_activeBaseUrl/item-icons/$cleanIconPath';
          } else if (iconUrl.isEmpty) {
            iconUrl = 'https://via.placeholder.com/64/333333/FFFFFF?text=N/A';
          }

          items.add(
            ServiceItem(
              title: item['title'] ?? 'No Title',
              launchUrl: item['url'] ?? '#',
              description: item['description'],
              iconUrl: iconUrl,
            ),
          );
        }
        sections.add(
          DashboardSection(
            name: section['name'] ?? 'Unnamed Section',
            items: items,
          ),
        );
      }
    }
    return sections;
  }

  // This logic is now reliable because its inputs are clean.
  String rewriteServiceUrl(String originalUrl) {
    if (_activeBaseUrl == null) {
      debugPrint('Rewrite skipped: No active base URL.');
      return originalUrl;
    }

    final activeIp = Uri.parse(_activeBaseUrl!).host;
    String? inactiveIp;

    // Check if we are on ZeroTier, which means the local IP is inactive
    if (activeIp == _zeroTierIp && _localWlanIp != null) {
      inactiveIp = _localWlanIp;
    }
    // Check if we are on WLAN, which means the ZeroTier IP is inactive
    else if (activeIp == _localWlanIp && _zeroTierIp != null) {
      inactiveIp = _zeroTierIp;
    }

    if (inactiveIp == null || inactiveIp.isEmpty) {
      debugPrint('Rewrite skipped: Could not determine inactive IP.');
      return originalUrl;
    }

    if (originalUrl.contains(inactiveIp)) {
      debugPrint(
        'REWRITING URL: Replacing "$inactiveIp" with "$activeIp" in "$originalUrl"',
      );
      return originalUrl.replaceFirst(inactiveIp, activeIp);
    }

    debugPrint('No rewrite needed for URL: $originalUrl');
    return originalUrl;
  }
}
