// lib/widgets/glances/glances_cpu_gauge.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:dashymobile/models/glances_models.dart';
import 'package:dashymobile/services/glances_service.dart';

class GlancesCpuGauge extends StatefulWidget {
  final String hostname;
  const GlancesCpuGauge({super.key, required this.hostname});

  @override
  State<GlancesCpuGauge> createState() => _GlancesCpuGaugeState();
}

class _GlancesCpuGaugeState extends State<GlancesCpuGauge> {
  final GlancesApiService _glancesApiService = GlancesApiService();
  Timer? _timer;

  GlancesCpu? _cpuData;
  Object? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchData();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final data = await _glancesApiService.fetchCpu(widget.hostname);
      if (mounted) {
        setState(() {
          _cpuData = data;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text(
          'Error fetching CPU data:\n${_error.toString()}',
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      );
    }
    if (_cpuData == null) {
      return const Center(child: Text('No data available.'));
    }

    final cpuUsage = _cpuData!.total;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('CPU Usage', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        SizedBox(
          height: 150,
          width: 150,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: cpuUsage.toDouble(),
                      color: colorScheme.primary,
                      radius: 20,
                      showTitle: false,
                    ),
                    PieChartSectionData(
                      value: (100 - cpuUsage).toDouble(),
                      color: colorScheme.onSurface.withAlpha(30),
                      radius: 20,
                      showTitle: false,
                    ),
                  ],
                  startDegreeOffset: -90,
                  centerSpaceRadius: double.infinity,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {},
                  ),
                ),
              ),
              Text(
                '$cpuUsage%',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
