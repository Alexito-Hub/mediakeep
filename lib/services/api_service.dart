import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/tiktok_model.dart';
import '../models/facebook_model.dart';
import '../models/spotify_model.dart';
import '../models/threads_model.dart';
import '../models/youtube_model.dart';
import '../models/bilibili_model.dart';
import '../models/instagram_model.dart';
import '../models/twitter_model.dart';
import '../utils/constants.dart';
import '../core/responses/api_response.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

/// Service for API communication with the download backend
class ApiService {
  /// Generates or retrieves a persistent device fingerprint for limit tracking
  static Future<String> _getDeviceFingerprint() async {
    final prefs = await SharedPreferences.getInstance();
    String? fingerprint = prefs.getString('device_fingerprint');

    if (fingerprint == null) {
      final randomStr = List.generate(
        32,
        (index) => Random().nextInt(36).toRadixString(36),
      ).join();
      fingerprint = 'fp_${DateTime.now().millisecondsSinceEpoch}_$randomStr';
      await prefs.setString('device_fingerprint', fingerprint);
    }

    return fingerprint;
  }

  /// Fetches media data from the API based on platform and URL
  static Future<ApiResponse> fetchMedia({
    required String url,
    required String platform,
  }) async {
    try {
      final apiEndpoint = '${AppConstants.apiBaseUrl}/download/$platform';

      final String fingerprint = await _getDeviceFingerprint();

      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'x-app-token': AppConstants.appSecret,
        'x-device-fingerprint': fingerprint,
      };

      final response = await http
          .post(
            Uri.parse(apiEndpoint),
            headers: headers,
            body: jsonEncode({'url': url}),
          )
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode != 200) {
        // Parse the body even on error responses to detect limit codes (backend returns 403)
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['code'] == 'AUTH_LIMIT_REACHED' ||
              errorData['code'] == 'UNAUTH_LIMIT_REACHED') {
            return ApiResponse.error(
              errorData['msg'] ?? 'Límite alcanzado',
              limitReached: true,
            );
          }
          if (errorData['msg'] != null) {
            return ApiResponse.error(errorData['msg']);
          }
        } catch (_) {}
        return ApiResponse.error(
          'Error del servidor (${response.statusCode}). Intenta más tarde.',
        );
      }

      final responseData = jsonDecode(response.body);

      if (responseData['status'] == true) {
        return ApiResponse.success(data: responseData, platform: platform);
      } else {
        // Handle usage limits errors gracefully
        if (responseData['code'] == 'AUTH_LIMIT_REACHED' ||
            responseData['code'] == 'UNAUTH_LIMIT_REACHED') {
          return ApiResponse.error(responseData['msg'], limitReached: true);
        }
        return ApiResponse.error(
          responseData['msg'] ??
              'No se pudo obtener el contenido. Intenta de nuevo.',
        );
      }
    } on TimeoutException {
      return ApiResponse.error(
        'El servidor tardó demasiado en responder. Revisa tu conexión.',
      );
    } catch (e) {
      return ApiResponse.error('Error de conexión. Verifica tu internet.');
    }
  }

  /// Parses the API response into specific platform data models
  static dynamic parseResponseData(Map<String, dynamic> data, String platform) {
    switch (platform) {
      case 'tiktok':
        return TikTokData.fromJson(data['data'] ?? data);
      case 'facebook':
        return FacebookData.fromJson(data['data']);
      case 'spotify':
        return SpotifyData.fromJson(data['data']);
      case 'threads':
        return ThreadsData.fromJson(data);
      case 'youtube':
        return YouTubeData.fromJson(data['data'] ?? data);
      case 'bilibili':
        return BilibiliData.fromJson(data['data'] ?? data);
      case 'instagram':
        return InstagramData.fromJson(data['data'] ?? data);
      case 'twitter':
        return TwitterData.fromJson(data['data'] ?? data);
      default:
        return null;
    }
  }

  /// No-op: subscription status no longer used (auth/premium removed).
  static Future<Map<String, dynamic>?> getSubscriptionStatus() async => null;
}
