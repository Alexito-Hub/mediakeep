import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/status_model.dart';
import '../utils/constants.dart';

/// Service for monitoring application and platform status
class StatusService {
  static String get _healthUrl => '${AppConstants.apiBaseUrl}/health';

  /// Fetches the general server health with extended information
  static Future<ServerHealth?> getServerHealth() async {
    try {
      final response = await http
          .get(Uri.parse(_healthUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ServerHealth.fromJson(data);
      }
    } catch (e) {
      // Error fetching server health
    }
    return null;
  }

  /// Fetches API version information
  static Future<String> getApiVersion() async {
    try {
      final response = await http
          .get(Uri.parse(_healthUrl))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['version'] ?? 'Unknown';
      }
    } catch (e) {
      // Error fetching API version
    }
    return 'Unknown';
  }

  /// Fetches platform statuses from the backend /status/platforms endpoint.
  /// Falls back to _allOffline() on any error.
  static Future<List<PlatformStatus>> getPlatformStatuses() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/status/platforms'),
        headers: {'x-app-token': AppConstants.appSecret},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) return _allOffline();

      final body = jsonDecode(response.body);
      if (body['status'] != true || body['data'] == null) return _allOffline();

      final Map<String, dynamic> data = body['data'];

      return data.entries.map((entry) {
        final platform = entry.key;
        final info = entry.value as Map<String, dynamic>;
        final ok = info['ok'] as bool? ?? false;
        final latency = info['latency'] as int? ?? 0;
        final statusCode = info['statusCode'] as int? ?? 0;
        final validation = info['validation'] as Map<String, dynamic>?;
        final error = info['error'] as String?;

        return PlatformStatus(
          platformName: platform,
          statusCode: statusCode,
          responseTime: Duration(milliseconds: latency),
          status: ok ? 'Operativo' : 'Sin servicio',
          errorMessage: validation?['reason'] as String? ?? error,
        );
      }).toList();
    } catch (e) {
      return _allOffline();
    }
  }

  static List<PlatformStatus> _allOffline() {
    return AppConstants.platformPatterns.keys.map((platform) {
      return PlatformStatus(
        platformName: platform,
        statusCode: 0,
        responseTime: Duration.zero,
        status: 'Sin conexión',
        errorMessage: 'No se pudo verificar',
      );
    }).toList();
  }
}
