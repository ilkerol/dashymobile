// lib/services/dashy_service.dart

import 'package:http/http.dart' as http;
import 'package:yaml/yaml.dart'; // <--- THIS WAS THE FIX
import 'package:dashymobile/models/dashboard_models.dart';

class DashyService {
  Future<List<DashboardSection>> fetchAndParseConfig(String baseUrl) async {
    // Ensure the URL is valid before proceeding
    if (!baseUrl.startsWith('http')) {
      throw Exception('Invalid URL format. URL must start with http or https.');
    }

    final configUrl = Uri.parse('$baseUrl/conf.yml');
    final List<DashboardSection> dashboardSections = [];

    try {
      // Add a timeout to prevent the app from hanging indefinitely
      final response = await http
          .get(configUrl)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final yamlMap = loadYaml(response.body);

        // Check if 'sections' key exists and is a list
        if (yamlMap['sections'] is! List) {
          throw Exception("Config file is missing a 'sections' list.");
        }
        final sections = yamlMap['sections'] as List;

        for (final section in sections) {
          if (section.containsKey('items') && section['items'] != null) {
            final List<ServiceItem> serviceItems = [];
            final items = section['items'] as List;

            for (final item in items) {
              if (item is! YamlMap) continue;

              String iconUrl = item['icon'] ?? '';

              // Handle relative icon URLs more robustly
              if (iconUrl.isNotEmpty && !iconUrl.startsWith('http')) {
                iconUrl =
                    '$baseUrl/${iconUrl.startsWith('/') ? iconUrl.substring(1) : iconUrl}';
              } else if (iconUrl.isEmpty) {
                // Provide a fallback transparent image or a default icon
                iconUrl = 'https://via.placeholder.com/48/000000/000000';
              }

              serviceItems.add(
                ServiceItem(
                  title: item['title'] ?? 'No Title',
                  launchUrl: item['url'] ?? '',
                  description: item['description'],
                  iconUrl: iconUrl,
                ),
              );
            }

            if (serviceItems.isNotEmpty) {
              dashboardSections.add(
                DashboardSection(
                  name: section['name'] ?? 'Unnamed Section',
                  items: serviceItems,
                ),
              );
            }
          }
        }
        return dashboardSections;
      } else {
        throw Exception(
          'Failed to load config file (Status code: ${response.statusCode})',
        );
      }
    } catch (e) {
      // Provide a more user-friendly error message
      throw Exception(
        'Could not connect to server or parse config file. Please check your URL and network connection.\n\nDetails: $e',
      );
    }
  }
}
