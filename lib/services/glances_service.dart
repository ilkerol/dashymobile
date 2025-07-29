// lib/services/glances_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:dashymobile/models/glances_models.dart';

class GlancesApiService {
  static const String _glancesApiVersion = '4';

  Future<GlancesCpu> fetchCpu(String hostname) async {
    final url = _buildUrl(hostname, '/api/$_glancesApiVersion/cpu');
    if (kDebugMode) {
      print('[GlancesApiService] Requesting URL: $url');
    }
    final response = await http.get(url).timeout(const Duration(seconds: 4));
    if (response.statusCode == 200) {
      return GlancesCpu.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load CPU data: ${response.statusCode}');
    }
  }

  Uri _buildUrl(String hostname, String path) {
    final cleanBaseUrl = hostname.endsWith('/')
        ? hostname.substring(0, hostname.length - 1)
        : hostname;
    return Uri.parse('$cleanBaseUrl$path');
  }
}
