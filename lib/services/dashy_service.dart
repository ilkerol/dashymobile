import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:yaml/yaml.dart';
import 'package:dashymobile/models/dashboard_models.dart';
import 'package:dashymobile/services/settings_service.dart';

class DashyService {
  final SettingsService _settingsService = SettingsService();
  static const String localPlaceholderIcon = 'LOCAL_ASSET_PLACEHOLDER';

  String? _activeBaseUrl;
  String? _localWlanIp;
  String? _zeroTierIp;

  Future<ConfigFetchResult> fetchAndParseConfig(List<String> urlsToTry) async {
    _localWlanIp = (await _settingsService.getLocalWlanIp())?.trim();
    _zeroTierIp = (await _settingsService.getZeroTierIp())?.trim();

    for (String baseUrl in urlsToTry) {
      if (baseUrl.isEmpty) continue;
      try {
        final response = await http
            .get(Uri.parse('$baseUrl/conf.yml'))
            .timeout(const Duration(seconds: 4));
        if (response.statusCode == 200) {
          _activeBaseUrl = baseUrl;
          final sections = _parseConfig(response.body, baseUrl);
          return ConfigFetchResult(sections: sections, activeBaseUrl: baseUrl);
        }
      } catch (e) {
        if (kDebugMode) {
          print('Failed to connect to $baseUrl: $e');
        }
      }
    }
    throw Exception('Could not connect to any of the provided Dashy URLs.');
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
      if (section.containsKey('items') && section['items'] is YamlList) {
        final List<ServiceItem> items = [];
        for (final item in section['items']) {
          if (item is! YamlMap) continue;
          List<ServiceItem>? subItems;
          if (item.containsKey('subItems') && item['subItems'] is YamlList) {
            subItems = (item['subItems'] as YamlList)
                .whereType<YamlMap>()
                .map(
                  (subItemMap) =>
                      _parseSingleServiceItem(subItemMap, activeBaseUrl),
                )
                .toList();
          }
          items.add(
            _parseSingleServiceItem(item, activeBaseUrl, subItems: subItems),
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

  ServiceItem _parseSingleServiceItem(
    YamlMap item,
    String activeBaseUrl, {
    List<ServiceItem>? subItems,
  }) {
    String iconUrl = item['icon'] ?? '';
    if (iconUrl.isNotEmpty && !iconUrl.startsWith('http')) {
      final cleanIconPath = iconUrl.startsWith('/')
          ? iconUrl.substring(1)
          : iconUrl;
      iconUrl = '$activeBaseUrl/item-icons/$cleanIconPath';
    } else if (iconUrl.isEmpty) {
      iconUrl = localPlaceholderIcon;
    }
    return ServiceItem(
      title: item['title'] ?? 'No Title',
      launchUrl: item['url'] ?? '',
      description: item['description'],
      iconUrl: iconUrl,
      subItems: subItems,
    );
  }

  String rewriteServiceUrl(String originalUrl) {
    if (_activeBaseUrl == null) return originalUrl;
    final activeIp = Uri.parse(_activeBaseUrl!).host;
    String? inactiveIp;
    if (activeIp == _zeroTierIp && _localWlanIp != null) {
      inactiveIp = _localWlanIp;
    } else if (activeIp == _localWlanIp && _zeroTierIp != null) {
      inactiveIp = _zeroTierIp;
    }
    if (inactiveIp == null || inactiveIp.isEmpty) return originalUrl;
    if (originalUrl.contains(inactiveIp)) {
      return originalUrl.replaceFirst(inactiveIp, activeIp);
    }
    return originalUrl;
  }
}
