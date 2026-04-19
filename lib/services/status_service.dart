import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/status_model.dart';
import '../utils/constants.dart';

/// Service for local app and public platform reachability checks.
class StatusService {
  static final DateTime _startedAt = DateTime.now();

  static const Map<String, String> _platformProbeUrls = {
    'tiktok': 'https://www.tiktok.com',
    'facebook': 'https://www.facebook.com',
    'spotify': 'https://open.spotify.com',
    'threads': 'https://www.threads.net',
    'youtube': 'https://www.youtube.com',
    'bilibili': 'https://www.bilibili.com',
    'instagram': 'https://www.instagram.com',
    'twitter': 'https://x.com',
  };

  /// Returns local runtime health information.
  static Future<ServerHealth?> getServerHealth() async {
    final uptimeSeconds = DateTime.now().difference(_startedAt).inSeconds;
    return ServerHealth(
      status: 'operativo',
      timestamp: DateTime.now(),
      uptime: uptimeSeconds.toDouble(),
      environment: 'local',
    );
  }

  /// Returns local app version as API version replacement.
  static Future<String> getApiVersion() async {
    return 'LOCAL-${AppConstants.appVersion}';
  }

  /// Checks if public platform URLs are reachable.
  static Future<List<PlatformStatus>> getPlatformStatuses() async {
    final statuses = <PlatformStatus>[];

    for (final platform in AppConstants.platformPatterns.keys) {
      statuses.add(await _probePlatform(platform));
    }

    return statuses;
  }

  static Future<PlatformStatus> _probePlatform(String platform) async {
    final url = _platformProbeUrls[platform] ?? 'https://$platform.com';
    final stopwatch = Stopwatch()..start();

    try {
      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
                  '(KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36',
            },
          )
          .timeout(const Duration(seconds: 8));

      stopwatch.stop();

      final ok = response.statusCode >= 200 && response.statusCode < 400;
      return PlatformStatus(
        platformName: platform,
        statusCode: ok ? 200 : response.statusCode,
        responseTime: stopwatch.elapsed,
        status: ok ? 'Operativo' : 'Sin servicio',
        errorMessage: ok
            ? null
            : 'Respuesta inesperada (${response.statusCode})',
        lastTestedUrl: url,
      );
    } on TimeoutException {
      stopwatch.stop();
      return PlatformStatus(
        platformName: platform,
        statusCode: 0,
        responseTime: stopwatch.elapsed,
        status: 'Sin conexión',
        errorMessage: 'Tiempo de espera agotado',
        lastTestedUrl: url,
      );
    } catch (_) {
      stopwatch.stop();
      return PlatformStatus(
        platformName: platform,
        statusCode: 0,
        responseTime: stopwatch.elapsed,
        status: 'Sin conexión',
        errorMessage: 'No se pudo verificar',
        lastTestedUrl: url,
      );
    }
  }
}
