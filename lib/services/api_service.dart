import 'dart:async';

import '../core/responses/api_response.dart';
import '../models/bilibili_model.dart';
import '../models/facebook_model.dart';
import '../models/instagram_model.dart';
import '../models/spotify_model.dart';
import '../models/threads_model.dart';
import '../models/tiktok_model.dart';
import '../models/twitter_model.dart';
import '../models/youtube_model.dart';
import 'extractors/bilibili_extractor.dart';
import 'extractors/facebook_extractor.dart';
import 'extractors/instagram_extractor.dart';
import 'extractors/spotify_extractor.dart';
import 'extractors/threads_extractor.dart';
import 'extractors/tiktok_extractor.dart';
import 'extractors/twitter_extractor.dart';
import 'extractors/youtube_extractor.dart';

class ApiService {
  static final Map<String, Future<Map<String, dynamic>> Function(String)>
  _extractors = {
    'tiktok': TikTokExtractor.fetch,
    'facebook': FacebookExtractor.fetch,
    'spotify': SpotifyExtractor.fetch,
    'threads': ThreadsExtractor.fetch,
    'youtube': YouTubeExtractor.fetch,
    'bilibili': BilibiliExtractor.fetch,
    'instagram': InstagramExtractor.fetch,
    'twitter': TwitterExtractor.fetch,
  };

  static Future<ApiResponse> fetchMedia({
    required String url,
    required String platform,
  }) async {
    final sourceUrl = url.trim();
    if (sourceUrl.isEmpty) {
      return ApiResponse.error('La URL es requerida.');
    }

    final extractor = _extractors[platform];
    if (extractor == null) {
      return ApiResponse.error('Plataforma no soportada.');
    }

    try {
      final payload = await extractor(sourceUrl);

      if (!_payloadHasDownloadableMedia(payload, platform)) {
        return ApiResponse.error(
          'No se encontró contenido para descargar. El post puede ser privado o no disponible.',
        );
      }

      return ApiResponse.success(data: payload, platform: platform);
    } on TimeoutException {
      return ApiResponse.error(
        'La operación tardó demasiado. Intenta de nuevo.',
      );
    } catch (e) {
      return ApiResponse.error(_humanizeError(platform, e));
    }
  }

  static bool _payloadHasDownloadableMedia(
    Map<String, dynamic> payload,
    String platform,
  ) {
    final normalized = _normalizeData(payload);

    switch (platform) {
      case 'tiktok':
        final media = normalized['media'];
        if (media is! Map) return false;
        final type = media['type']?.toString();
        if (type == 'image') {
          final images = media['images'];
          return images is List && images.isNotEmpty;
        }
        final noWatermark = media['nowatermark'];
        if (noWatermark is! Map) return false;
        final play = noWatermark['play']?.toString();
        return play != null && play.isNotEmpty;
      case 'facebook':
        final download = normalized['download']?.toString();
        final images = normalized['images'];
        return (download != null && download.isNotEmpty) ||
            (images is List && images.isNotEmpty);
      case 'spotify':
        final download = normalized['download']?.toString();
        return download != null && download.isNotEmpty;
      case 'threads':
        final download = normalized['download'];
        if (download is List) return download.isNotEmpty;
        if (download is Map) {
          final url = download['url']?.toString();
          return url != null && url.isNotEmpty;
        }
        return false;
      case 'youtube':
      case 'bilibili':
        final videos = normalized['videos'];
        final audios = normalized['audios'];
        return (videos is List && videos.isNotEmpty) ||
            (audios is List && audios.isNotEmpty);
      case 'instagram':
        final media = normalized['media'];
        return media is List && media.isNotEmpty;
      case 'twitter':
        final media = normalized['media'];
        return media is List && media.isNotEmpty;
      default:
        return false;
    }
  }

  static String _humanizeError(String platform, Object error) {
    final raw = error.toString().replaceFirst('Exception: ', '').trim();
    if (raw.isNotEmpty && raw.length < 180) {
      return raw;
    }

    switch (platform) {
      case 'spotify':
        return 'No se pudo procesar Spotify. Intenta otro enlace público.';
      case 'instagram':
        return 'No se pudo extraer Instagram. El post puede ser privado.';
      case 'youtube':
        return 'No se pudo procesar YouTube en este momento.';
      default:
        return 'No se pudo procesar el enlace.';
    }
  }

  static dynamic parseResponseData(Map<String, dynamic> data, String platform) {
    final normalized = _normalizeData(data);

    switch (platform) {
      case 'tiktok':
        return TikTokData.fromJson(normalized);
      case 'facebook':
        return FacebookData.fromJson(normalized);
      case 'spotify':
        return SpotifyData.fromJson(normalized);
      case 'threads':
        return ThreadsData.fromJson(normalized);
      case 'youtube':
        return YouTubeData.fromJson(normalized);
      case 'bilibili':
        return BilibiliData.fromJson(normalized);
      case 'instagram':
        return InstagramData.fromJson(normalized);
      case 'twitter':
        return TwitterData.fromJson(normalized);
      default:
        return null;
    }
  }

  static Map<String, dynamic> _normalizeData(Map<String, dynamic> data) {
    final wrapped = data['data'];
    if (wrapped is Map<String, dynamic>) {
      return wrapped;
    }
    if (wrapped is Map) {
      return wrapped.map((key, value) => MapEntry('$key', value));
    }
    return data;
  }

  static Future<Map<String, dynamic>?> getSubscriptionStatus() async => null;
}
