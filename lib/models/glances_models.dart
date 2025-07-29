// lib/models/glances_models.dart

/// Represents the data fetched from the Glances API for CPU stats.
/// Corresponds to the `/api/3/cpu` endpoint.
class GlancesCpu {
  final int total;

  GlancesCpu({required this.total});

  /// Factory constructor to parse the JSON map from the Glances API.
  factory GlancesCpu.fromJson(Map<String, dynamic> json) {
    // The 'total' value can be an integer or a double in the JSON.
    // We safely handle both cases and convert to an int.
    final totalValue = json['total'];
    return GlancesCpu(
      total: totalValue is int
          ? totalValue
          : (totalValue as double?)?.round() ?? 0,
    );
  }
}

/// Represents the data fetched from the Glances API for Memory stats.
/// Corresponds to the `/api/3/mem` endpoint.
class GlancesMem {
  final int percent;

  GlancesMem({required this.percent});

  /// Factory constructor to parse the JSON map from the Glances API.
  factory GlancesMem.fromJson(Map<String, dynamic> json) {
    final percentValue = json['percent'];
    return GlancesMem(
      percent: percentValue is int
          ? percentValue
          : (percentValue as double?)?.round() ?? 0,
    );
  }
}

/// A container class to hold all the system stats fetched from Glances.
/// This simplifies passing the data around the app.
class SystemStats {
  final GlancesCpu cpu;
  final GlancesMem mem;

  SystemStats({required this.cpu, required this.mem});
}
