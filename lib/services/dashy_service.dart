// lib/services/dashy_service.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:yaml/yaml.dart';
import 'package:dashymobile/models/dashboard_models.dart';

class DashyService {
  String? _activeBaseUrl;
  String? _localDashyUrl;
  String? _secondaryDashyUrl;

  static const String localPlaceholderIcon = 'LOCAL_ASSET_PLACEHOLDER';

  Future<ConfigFetchResult> fetchAndParseConfig(List<String> urlsToTry) async {
    _localDashyUrl = urlsToTry.isNotEmpty ? urlsToTry[0] : null;
    _secondaryDashyUrl = urlsToTry.length > 1 ? urlsToTry[1] : null;

    for (String baseUrl in urlsToTry) {
      if (baseUrl.trim().isEmpty) continue;
      try {
        final cleanBaseUrl = baseUrl.endsWith('/')
            ? baseUrl.substring(0, baseUrl.length - 1)
            : baseUrl;
        final response = await http
            .get(Uri.parse('$cleanBaseUrl/conf.yml'))
            .timeout(const Duration(seconds: 4));
        if (response.statusCode == 200) {
          _activeBaseUrl = cleanBaseUrl;
          final sections = _parseConfig(response.body, cleanBaseUrl);
          return ConfigFetchResult(
            sections: sections,
            activeBaseUrl: cleanBaseUrl,
          );
        }
      } catch (e) {
        if (kDebugMode) {
          print('Failed to connect to $baseUrl: $e');
        }
      }
    }
    throw Exception('Could not connect to any of the provided Dashy URLs.');
  }

  String _resolveIconUrl(String? iconPath, String activeBaseUrl) {
    if (iconPath == null || iconPath.isEmpty) return localPlaceholderIcon;
    if (iconPath.startsWith('http')) return iconPath;
    final cleanIconPath = iconPath.startsWith('/')
        ? iconPath.substring(1)
        : iconPath;
    return '$activeBaseUrl/item-icons/$cleanIconPath';
  }

  ServiceItem _parseSingleItem(YamlMap item, String activeBaseUrl) {
    List<ServiceItem>? subItems;
    if (item.containsKey('subItems') && item['subItems'] is YamlList) {
      subItems = (item['subItems'] as YamlList)
          .whereType<YamlMap>()
          .map((subItem) => _parseSingleItem(subItem, activeBaseUrl))
          .toList();
    }
    return ServiceItem(
      title: item['title'] ?? 'No Title',
      launchUrl: item['url'] ?? '',
      description: item['description'],
      iconUrl: _resolveIconUrl(item['icon'], activeBaseUrl),
      subItems: subItems,
    );
  }

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
      if (section is! YamlMap) continue;
      final List<ServiceItem> items = [];
      if (section.containsKey('items') && section['items'] is YamlList) {
        items.addAll(
          (section['items'] as YamlList).whereType<YamlMap>().map(
            (item) => _parseSingleItem(item, activeBaseUrl),
          ),
        );
      }
      final List<DashboardWidget> widgets = [];
      if (section.containsKey('widgets') && section['widgets'] is YamlList) {
        for (final widgetMap in section['widgets'].whereType<YamlMap>()) {
          final options = <String, dynamic>{};
          if (widgetMap['options'] is YamlMap) {
            (widgetMap['options'] as YamlMap).forEach((key, value) {
              options[key.toString()] = value;
            });
          }
          widgets.add(
            DashboardWidget(
              type: widgetMap['type'] ?? 'unknown-widget',
              id: widgetMap['id'],
              options: options,
            ),
          );
        }
      }
      if (items.isNotEmpty || widgets.isNotEmpty) {
        sections.add(
          DashboardSection(
            name: section['name'] ?? 'Unnamed Section',
            items: items,
            widgets: widgets,
          ),
        );
      }
    }
    return sections;
  }

  String rewriteServiceUrl(String originalUrl) {
    if (_activeBaseUrl == null ||
        _localDashyUrl == null ||
        _secondaryDashyUrl == null ||
        originalUrl.isEmpty ||
        !originalUrl.startsWith('http')) {
      return originalUrl;
    }
    try {
      final activeUri = Uri.parse(_activeBaseUrl!);
      final localUri = Uri.parse(_localDashyUrl!);
      final secondaryUri = Uri.parse(_secondaryDashyUrl!);
      final originalUri = Uri.parse(originalUrl);

      Uri? inactiveUri;
      if (activeUri.authority == localUri.authority) {
        inactiveUri = secondaryUri;
      } else if (activeUri.authority == secondaryUri.authority) {
        inactiveUri = localUri;
      }

      if (inactiveUri != null &&
          originalUri.authority == inactiveUri.authority) {
        final newUri = originalUri.replace(
          scheme: activeUri.scheme,
          host: activeUri.host,
          port: activeUri.port,
        );
        return newUri.toString();
      }
      return originalUrl;
    } catch (e) {
      if (kDebugMode) {
        print("Error rewriting service URL: $e. Returning original URL.");
      }
      return originalUrl;
    }
  }
}
