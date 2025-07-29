// lib/services/dashy_service.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:yaml/yaml.dart';
import 'package:dashymobile/models/dashboard_models.dart';
import 'package:dashymobile/services/settings_service.dart';

/// A service responsible for all interactions with the Dashy server.
///
/// This includes fetching and parsing the configuration file, and dynamically
/// rewriting service URLs based on the currently active connection.
class DashyService {
  final SettingsService _settingsService = SettingsService();

  // The base URL that was last used to successfully fetch the config.
  String? _activeBaseUrl;
  // The IP addresses loaded from settings, used for URL rewriting.
  String? _localWlanIp;
  String? _zeroTierIp;

  /// A constant to identify items that need a local placeholder icon.
  static const String localPlaceholderIcon = 'LOCAL_ASSET_PLACEHOLDER';

  /// Fetches and parses the `conf.yml` from a list of potential Dashy URLs.
  Future<ConfigFetchResult> fetchAndParseConfig(List<String> urlsToTry) async {
    // Load and trim IP settings to ensure clean data for rewriting logic.
    _localWlanIp = (await _settingsService.getLocalWlanIp())?.trim();
    _zeroTierIp = (await _settingsService.getZeroTierIp())?.trim();

    for (String baseUrl in urlsToTry) {
      if (baseUrl.isEmpty) continue;

      try {
        final response = await http
            .get(Uri.parse('$baseUrl/conf.yml'))
            .timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          // On success, store the active URL and parse the content.
          _activeBaseUrl = baseUrl;
          final sections = _parseConfig(response.body, baseUrl);
          return ConfigFetchResult(sections: sections, activeBaseUrl: baseUrl);
        }
      } catch (e) {
        // Log connection errors and try the next URL in the list.
        if (kDebugMode) {
          print('Failed to connect to $baseUrl: $e');
        }
      }
    }

    // If the loop completes without a successful connection, throw an error.
    throw Exception('Could not connect to any of the provided Dashy URLs.');
  }

  /// Helper function to resolve a relative icon path to a full URL.
  String _resolveIconUrl(String? iconPath, String activeBaseUrl) {
    if (iconPath == null || iconPath.isEmpty) {
      // THIS IS THE FIX: Return the local constant instead of an internet URL.
      return localPlaceholderIcon;
    }
    // If icon path is already a full URL, return it as is.
    if (iconPath.startsWith('http')) {
      return iconPath;
    }
    // Otherwise, prepend the server's base URL.
    final cleanIconPath = iconPath.startsWith('/')
        ? iconPath.substring(1)
        : iconPath;
    return '$activeBaseUrl/item-icons/$cleanIconPath';
  }

  /// Parses a single item (or sub-item) from a YamlMap into a ServiceItem.
  ServiceItem _parseSingleItem(YamlMap item, String activeBaseUrl) {
    // Recursively parse sub-items if they exist
    List<ServiceItem>? subItems;
    if (item.containsKey('subItems') && item['subItems'] is YamlList) {
      subItems = (item['subItems'] as YamlList)
          .whereType<YamlMap>()
          .map((subItem) => _parseSingleItem(subItem, activeBaseUrl))
          .toList();
    }

    return ServiceItem(
      title: item['title'] ?? 'No Title',
      launchUrl: item['url'] ?? '', // Default to empty string
      description: item['description'],
      iconUrl: _resolveIconUrl(item['icon'], activeBaseUrl),
      subItems: subItems,
    );
  }

  /// Parses the YAML string content into a list of [DashboardSection] objects.
  List<DashboardSection> _parseConfig(
    String yamlContent,
    String activeBaseUrl,
  ) {
    final doc = loadYaml(yamlContent);
    final List<DashboardSection> sections = [];

    if (doc['sections'] is! YamlList) {
      throw Exception("Config file is missing a 'sections' list.");
    }

    for (final section in doc['sections']) {
      if (section is! YamlMap ||
          !section.containsKey('items') ||
          section['items'] is! YamlList) {
        continue;
      }

      final List<ServiceItem> items = (section['items'] as YamlList)
          .whereType<YamlMap>()
          .map((item) => _parseSingleItem(item, activeBaseUrl))
          .toList();

      sections.add(
        DashboardSection(
          name: section['name'] ?? 'Unnamed Section',
          items: items,
        ),
      );
    }
    return sections;
  }

  /// Rewrites a service URL to use the currently active server IP.
  String rewriteServiceUrl(String originalUrl) {
    if (_activeBaseUrl == null || originalUrl.isEmpty) {
      // Cannot rewrite if we don't know which URL is active or if URL is empty.
      return originalUrl;
    }

    final activeIp = Uri.parse(_activeBaseUrl!).host;
    String? inactiveIp;

    // Determine which of the saved IPs is the inactive one.
    if (activeIp == _zeroTierIp && _localWlanIp != null) {
      inactiveIp = _localWlanIp;
    } else if (activeIp == _localWlanIp && _zeroTierIp != null) {
      inactiveIp = _zeroTierIp;
    }

    // If there's no inactive IP to replace, or it's not in the URL, do nothing.
    if (inactiveIp == null || inactiveIp.isEmpty) {
      return originalUrl;
    }

    if (originalUrl.contains(inactiveIp)) {
      return originalUrl.replaceFirst(inactiveIp, activeIp);
    }

    return originalUrl;
  }
}
