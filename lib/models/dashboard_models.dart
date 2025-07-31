// lib/models/dashboard_models.dart

class DashboardSection {
  final String name;
  final List<ServiceItem> items;

  DashboardSection({required this.name, required this.items});
}

class ServiceItem {
  final String title;
  final String launchUrl;
  final String? description;
  final String iconUrl;
  final List<ServiceItem>? subItems;

  ServiceItem({
    required this.title,
    required this.launchUrl,
    this.description,
    required this.iconUrl,
    this.subItems,
  });

  bool get isGroup => subItems != null && subItems!.isNotEmpty;
}

class ConfigFetchResult {
  final List<DashboardSection> sections;
  final String activeBaseUrl;

  ConfigFetchResult({required this.sections, required this.activeBaseUrl});
}
