// lib/widgets/system_monitor_dispatcher.dart

import 'package:flutter/material.dart';
import 'package:dashymobile/models/dashboard_models.dart';
import 'package:dashymobile/widgets/glances/glances_cpu_gauge.dart';

class SystemMonitorDispatcher extends StatelessWidget {
  final DashboardWidget widgetData;

  const SystemMonitorDispatcher({super.key, required this.widgetData});

  @override
  Widget build(BuildContext context) {
    final hostname = widgetData.options['hostname'] as String?;
    if (hostname == null || hostname.isEmpty) {
      return Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Widget "${widgetData.type}" is missing a "hostname" option in your conf.yml.',
          ),
        ),
      );
    }
    switch (widgetData.type) {
      case 'gl-current-cpu':
        return GlancesCpuGauge(hostname: hostname);
      default:
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Widget type "${widgetData.type}" is not yet supported.',
            ),
          ),
        );
    }
  }
}
