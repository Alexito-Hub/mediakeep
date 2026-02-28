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
import 'firestore_service.dart';
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
      final String? authToken = await FirestoreService.getAuthToken();

      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'x-app-token': AppConstants.appSecret,
        'x-device-fingerprint': fingerprint,
      };

      if (authToken != null) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final response = await http
          .post(
            Uri.parse(apiEndpoint),
            headers: headers,
            body: jsonEncode({'url': url}),
          )
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode != 200) {
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

  /// Generates a MercadoPago init_point URL for a premium package
  static Future<ApiResponse> createCheckoutSession(String packageId) async {
    try {
      final String? authToken = await FirestoreService.getAuthToken();
      if (authToken == null) {
        return ApiResponse.error('Debes iniciar sesión primero.');
      }

      final url = '${AppConstants.apiBaseUrl}/payment/checkout';
      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $authToken',
              'x-app-token': AppConstants.appSecret,
            },
            body: jsonEncode({
              'packageId': packageId,
              // userId intentionally omitted — backend reads it from the Bearer token
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == true) {
        return ApiResponse.success(data: data, platform: 'payment');
      }
      return ApiResponse.error(data['msg'] ?? 'Error desconocido');
    } catch (e) {
      return ApiResponse.error('No se pudo generar el enlace de pago.');
    }
  }

  /// Syncs a download history entry to the backend Firestore collection.
  /// Called silently in the background — errors are ignored.
  static Future<void> addHistoryToBackend({
    required String fileName,
    required String filePath,
    required String platform,
    required String type,
    required int fileSize,
    String? sourceUrl,
    String? contentId,
  }) async {
    final String? authToken = await FirestoreService.getAuthToken();
    if (authToken == null) return;

    final Map<String, dynamic> bodyData = {
      'fileName': fileName,
      'filePath': filePath,
      'platform': platform,
      'type': type,
      'fileSize': fileSize,
    };
    if (sourceUrl != null) bodyData['sourceUrl'] = sourceUrl;
    if (contentId != null) bodyData['contentId'] = contentId;

    await http
        .post(
          Uri.parse('${AppConstants.apiBaseUrl}/auth/history'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $authToken',
            'x-app-token': AppConstants.appSecret,
          },
          body: jsonEncode(bodyData),
        )
        .timeout(const Duration(seconds: 10));
  }

  /// Fetches the current subscription status from the backend.
  static Future<Map<String, dynamic>?> getSubscriptionStatus() async {
    try {
      final String? authToken = await FirestoreService.getAuthToken();
      if (authToken == null) return null;

      final response = await http
          .get(
            Uri.parse('${AppConstants.apiBaseUrl}/payment/subscription'),
            headers: {
              'Authorization': 'Bearer $authToken',
              'x-app-token': AppConstants.appSecret,
            },
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == true) {
        return data['data'] as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Fetches usage limits from the backend for the authenticated user.
  static Future<Map<String, dynamic>?> getUsageLimits() async {
    try {
      final String? authToken = await FirestoreService.getAuthToken();
      if (authToken == null) return null;

      final response = await http
          .get(
            Uri.parse('${AppConstants.apiBaseUrl}/auth/limits'),
            headers: {
              'Authorization': 'Bearer $authToken',
              'x-app-token': AppConstants.appSecret,
            },
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == true) {
        return data['data'] as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Calls the backend to grant +X free requests after watching a rewarded ad.
  static Future<bool> grantRewardRequest(int amount) async {
    try {
      final String? authToken = await FirestoreService.getAuthToken();
      final String fingerprint = await _getDeviceFingerprint();

      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'x-app-token': AppConstants.appSecret,
        'x-device-fingerprint': fingerprint,
      };

      if (authToken != null) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final response = await http
          .post(
            Uri.parse('${AppConstants.apiBaseUrl}/auth/reward'),
            headers: headers,
            body: jsonEncode({'amount': amount}),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['status'] == true;
    } catch (_) {
      return false;
    }
  }
}
