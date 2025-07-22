// lib/models/dashboard_models.dart

// A class to hold a single service/item
class ServiceItem {
  final String title;
  final String? description;
  final String iconUrl;
  final String launchUrl;

  ServiceItem({
    required this.title,
    this.description,
    required this.iconUrl,
    required this.launchUrl,
  });
}

// A class to hold a section, like "Productivity" or "Media"
class DashboardSection {
  final String name;
  final List<ServiceItem> items;

  DashboardSection({required this.name, required this.items});
}

// --- THERE SHOULD BE NO OTHER CODE IN THIS FILE ---
