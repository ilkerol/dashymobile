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

  /// Fetches and parses the `conf.yml` from a list of potential Dashy URLs.
  ///
  /// It attempts to connect to each URL in [urlsToTry] in order. The first
  /// successful connection is used. It also pre-loads IP settings to enable
  /// the URL rewriting functionality.
  /// Throws an [Exception] if no URLs can be reached.
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

  /// Parses the YAML string content into a list of [DashboardSection] objects.
  ///
  /// This is a pure function whose output depends only on its inputs.
  /// It resolves relative icon paths into fully qualified URLs using the
  /// provided [activeBaseUrl].
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
      if (section.containsKey('items') && section['items'] is YamlList) {
        final List<ServiceItem> items = [];
        for (final item in section['items']) {
          if (item is! YamlMap) continue;

          String iconUrl = item['icon'] ?? '';
          // If icon path is relative, prepend the server's base URL.
          if (iconUrl.isNotEmpty && !iconUrl.startsWith('http')) {
            final cleanIconPath = iconUrl.startsWith('/')
                ? iconUrl.substring(1)
                : iconUrl;
            iconUrl = '$activeBaseUrl/item-icons/$cleanIconPath';
          } else if (iconUrl.isEmpty) {
            // Provide a placeholder for items that have no icon defined.
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

  /// Rewrites a service URL to use the currently active server IP.
  ///
  /// This is the core of the dual-URL system. It checks if the [originalUrl]
  /// contains the 'inactive' IP and, if so, replaces it with the 'active' IP.
  /// For example, if connected via ZeroTier, it replaces the local WLAN IP in
  /// the URL with the ZeroTier IP.
  String rewriteServiceUrl(String originalUrl) {
    if (_activeBaseUrl == null) {
      // Cannot rewrite if we don't know which URL is active.
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
