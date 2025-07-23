// lib/models/dashboard_models.dart

class DashboardSection {
  final String name;
  final List<ServiceItem> items;

  DashboardSection({required this.name, required this.items});
}

class ServiceItem {
  final String title;
  final String launchUrl; // Consistently use launchUrl
  final String? description; // Add the description field
  final String iconUrl;

  ServiceItem({
    required this.title,
    required this.launchUrl,
    this.description,
    required this.iconUrl,
  });
}

// This class remains correct
class ConfigFetchResult {
  final List<DashboardSection> sections;
  final String activeBaseUrl;

  ConfigFetchResult({required this.sections, required this.activeBaseUrl});
}
