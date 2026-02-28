import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/status_model.dart';
import '../utils/constants.dart';
import '../core/validation/platform_schemas.dart';
import '../core/validation/schema_validator.dart';

/// Test URLs for each platform to validate actual functionality
const Map<String, String> _platformTestUrls = {
  'tiktok':
      'https://www.tiktok.com/@miakhalifa/video/7585261135566245150?is_from_webapp=1&sender_device=pc&web_id=7537168528312878597',
  'facebook': 'https://www.facebook.com/share/v/1H4bvqqRXn/',
  'spotify':
      'https://open.spotify.com/intl-es/track/3IPJg1sdqLj12kFIndaonN?si=243e06727fb94cd5',
  'threads':
      'https://www.threads.com/@naturaleza.xy/post/DSfmw4oEmKm?xmt=AQF0xOb75GoQffGeRocFb6o2Tn-FIPZ6JoYkORK5lTuBZg',
  'youtube': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
  'bilibili':
      'https://www.bilibili.com/video/BV1gRqLBHEFf/?share_source=copy_web',
  'instagram':
      'https://www.instagram.com/p/DSlaFUEFNXL/?utm_source=ig_web_copy_link&igsh=NTc4MTIwNjQ2YQ==',
  'twitter': 'https://x.com/vintageforestt/status/2003503125374918830?s=20',
};

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

  /// Pings all supported platforms to check their status
  static Future<List<PlatformStatus>> getPlatformStatuses() async {
    final platforms = AppConstants.platformPatterns.keys.toList();
    final results = <PlatformStatus>[];

    for (final platform in platforms) {
      final status = await _checkPlatformStatus(platform);
      results.add(status);
    }

    return results;
  }

  static Future<PlatformStatus> _checkPlatformStatus(String platform) async {
    final startTime = DateTime.now();
    String? errorMessage;
    String? lastTestedUrl;
    Map<String, dynamic>? responseData;
    ValidationResult? validation;

    try {
      final apiEndpoint = '${AppConstants.apiBaseUrl}/download/$platform';
      final testUrl = _platformTestUrls[platform] ?? '';
      lastTestedUrl = testUrl;

      final response = await http
          .post(
            Uri.parse(apiEndpoint),
            headers: {
              'Content-Type': 'application/json',
              'x-app-token': AppConstants.appSecret,
            },
            body: jsonEncode({'url': testUrl}),
          )
          .timeout(const Duration(seconds: 15));

      final endTime = DateTime.now();
      final responseTime = endTime.difference(startTime);

      // Parse response to check if it's actually working
      final isSuccess = response.statusCode == 200;
      String status;

      if (isSuccess) {
        try {
          final data = jsonDecode(response.body);
          responseData = data; // Store full response

          // Validate response against schema
          final schema = PlatformSchemas.getSchema(platform);
          if (schema != null) {
            validation = SchemaValidator.validate(data, schema);

            if (validation.isValid) {
              status = 'Operativo';
            } else {
              status = 'Datos incompletos';
              errorMessage = validation.errors.first;
            }
          } else {
            // No schema defined, use basic validation
            final hasData = data['data'] != null || data['url'] != null;
            status = hasData ? 'Operativo' : 'Respuesta incompleta';
            if (!hasData) {
              errorMessage = 'La API respondio pero sin datos validos';
            }
          }
        } catch (e) {
          status = 'Error de formato';
          errorMessage = 'Respuesta JSON invalida';
        }
      } else if (response.statusCode == 400) {
        // Check if it's a validation error (expected) or server error
        try {
          final data = jsonDecode(response.body);
          responseData = data; // Store error response too
          errorMessage = data['error'] ?? 'Error de validación';
          status = 'Problemas';
        } catch (e) {
          status = 'Error del servidor';
          errorMessage = 'Código ${response.statusCode}';
        }
      } else {
        status = 'Sin servicio';
        errorMessage = 'HTTP ${response.statusCode}';
      }

      return PlatformStatus(
        platformName: platform,
        statusCode: response.statusCode,
        responseTime: responseTime,
        status: status,
        errorMessage: errorMessage,
        lastTestedUrl: lastTestedUrl,
        responseData: responseData,
        validation: validation,
      );
    } catch (e) {
      return PlatformStatus(
        platformName: platform,
        statusCode: 0,
        responseTime: Duration.zero,
        status: 'Sin conexión',
        errorMessage: e.toString(),
        lastTestedUrl: lastTestedUrl,
      );
    }
  }
}
