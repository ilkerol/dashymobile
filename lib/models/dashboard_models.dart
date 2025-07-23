// lib/models/dashboard_models.dart

/// Represents a single section of the dashboard, like "Productivity" or "Media".
/// Each section has a name and contains a list of individual service items.
class DashboardSection {
  /// The display name of the section (e.g., "Productivity").
  final String name;

  /// A list of [ServiceItem] objects that belong to this section.
  final List<ServiceItem> items;

  DashboardSection({required this.name, required this.items});
}

/// Represents a single clickable service or link within a [DashboardSection].
class ServiceItem {
  /// The display name of the service (e.g., "Syncthing").
  final String title;

  /// The full URL that will be launched when the user taps this item.
  final String launchUrl;

  /// An optional short description of the service.
  final String? description;

  /// The fully resolved URL to the icon image for this service.
  final String iconUrl;

  ServiceItem({
    required this.title,
    required this.launchUrl,
    this.description,
    required this.iconUrl,
  });
}

/// A data structure to hold the result of fetching and parsing the config.
///
/// This is useful for returning multiple related values from a single function,
/// in this case, both the parsed sections and the URL that was successfully used
/// to fetch them.
class ConfigFetchResult {
  /// The list of all parsed [DashboardSection]s from the configuration file.
  final List<DashboardSection> sections;

  /// The base URL (e.g., 'http://192.168.178.52:4444') from which the
  /// configuration was successfully fetched. This is important for resolving
  /// relative paths and for dynamic URL rewriting.
  final String activeBaseUrl;

  ConfigFetchResult({required this.sections, required this.activeBaseUrl});
}
