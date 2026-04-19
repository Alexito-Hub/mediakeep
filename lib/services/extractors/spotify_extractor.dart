import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;

import '../../utils/constants.dart';
import 'extractor_utils.dart';
import 'scraper_config.dart';
import 'scraper_secrets.dart';

class SpotifyExtractor {
  static Future<Map<String, dynamic>> fetch(String sourceUrl) async {
    final info = await _getSpotifyInfo(sourceUrl);
    final downloadUrl = await _getSpotifyDownloadUrl(sourceUrl);

    if (downloadUrl.isEmpty) {
      throw Exception('No se pudo generar el audio de Spotify.');
    }

    return {
      'status': true,
      'data': {...info, 'download': downloadUrl, 'preview': null},
    };
  }

  static Future<Map<String, dynamic>> _getSpotifyInfo(String sourceUrl) async {
    final trackId = _extractTrackId(sourceUrl);
    if (trackId == null || trackId.isEmpty) {
      throw Exception('Track ID no válido para Spotify.');
    }

    final accessToken = await _getSpotifyAccessToken();

    final response = await http
        .get(
          Uri.parse('https://api.spotify.com/v1/tracks/$trackId'),
          headers: {
            ...ScraperConfig.defaultHeaders(),
            'Authorization': 'Bearer $accessToken',
          },
        )
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode < 200 || response.statusCode >= 400) {
      throw Exception('Spotify API respondió ${response.statusCode}');
    }

    final data = ExtractorUtils.decodeJsonMap(response.bodyBytes);
    final album = ExtractorUtils.asMap(data['album']) ?? <String, dynamic>{};
    final images = ExtractorUtils.asList(album['images']);
    String thumbnail = '';

    for (final image in images) {
      final map = ExtractorUtils.asMap(image);
      if (map == null) continue;
      final height = ExtractorUtils.toInt(map['height']);
      if (height == 640) {
        thumbnail = map['url']?.toString() ?? '';
        break;
      }
    }
    if (thumbnail.isEmpty && images.isNotEmpty) {
      final first = ExtractorUtils.asMap(images.first);
      thumbnail = first?['url']?.toString() ?? '';
    }

    final artistsRaw = ExtractorUtils.asList(data['artists']);
    final artists = <Map<String, dynamic>>[];
    for (final artist in artistsRaw) {
      final map = ExtractorUtils.asMap(artist);
      if (map == null) continue;
      artists.add({
        'name': map['name']?.toString() ?? 'Unknown Artist',
        'type': map['type']?.toString() ?? 'artist',
        'id': map['id']?.toString() ?? '',
      });
    }

    final externalUrls =
        ExtractorUtils.asMap(data['external_urls']) ?? <String, dynamic>{};

    return {
      'id': data['id']?.toString() ?? trackId,
      'title': data['name']?.toString() ?? 'Unknown Track',
      'duration': ExtractorUtils.toInt(data['duration_ms']),
      'popularity': '${ExtractorUtils.toInt(data['popularity'])}%',
      'thumbnail': thumbnail,
      'date': album['release_date']?.toString() ?? '',
      'artist': artists,
      'url': externalUrls['spotify']?.toString() ?? sourceUrl,
    };
  }

  static Future<String> _getSpotifyAccessToken() async {
    if (!ScraperSecrets.hasSpotifyCredentials) {
      throw Exception(
        'Faltan SPOTIFY_CLIENT_ID y SPOTIFY_CLIENT_SECRET. '
        'Define ambos con --dart-define.',
      );
    }

    final raw =
        '${ScraperSecrets.spotifyClientId}:${ScraperSecrets.spotifyClientSecret}';
    final basic = base64Encode(utf8.encode(raw));

    final response = await http
        .post(
          Uri.parse('https://accounts.spotify.com/api/token'),
          headers: {
            'Authorization': 'Basic $basic',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: {'grant_type': 'client_credentials'},
        )
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode < 200 || response.statusCode >= 400) {
      throw Exception(
        'No se pudo obtener token Spotify (${response.statusCode})',
      );
    }

    final body = ExtractorUtils.decodeJsonMap(response.bodyBytes);
    final token = body['access_token']?.toString() ?? '';
    if (token.isEmpty) {
      throw Exception('Spotify no devolvió access_token.');
    }

    return token;
  }

  static String? _extractTrackId(String sourceUrl) {
    final match = RegExp(r'/track/([a-zA-Z0-9]+)').firstMatch(sourceUrl);
    return match?.group(1);
  }

  static Future<String> _getSpotifyDownloadUrl(String sourceUrl) async {
    final dio = Dio(
      BaseOptions(
        headers: ScraperConfig.defaultHeaders(),
        followRedirects: true,
        validateStatus: (_) => true,
      ),
    );

    final homeResponse = await dio
        .get<dynamic>(ScraperConfig.spotifyHomeUrl)
        .timeout(AppConstants.apiTimeout);

    final setCookies =
        homeResponse.headers.map['set-cookie'] ?? const <String>[];
    final token = _extractCookieFromSetCookies(setCookies, 'XSRF-TOKEN');
    if (token == null || token.isEmpty) {
      throw Exception('CSRF Token missing');
    }

    final cookieHeader = _buildCookieHeaderFromSetCookies(setCookies);

    final convertResponse = await dio
        .post<dynamic>(
          ScraperConfig.spotifyConvertUrl,
          data: {'urls': sourceUrl},
          options: Options(
            headers: {
              ...ScraperConfig.defaultHeaders(),
              'Content-Type': 'application/json',
              'X-XSRF-TOKEN': Uri.decodeComponent(token),
              'Origin': 'https://spotmate.online',
              'Referer': 'https://spotmate.online/',
              if (cookieHeader.isNotEmpty) 'Cookie': cookieHeader,
            },
          ),
        )
        .timeout(const Duration(seconds: 25));

    final statusCode = convertResponse.statusCode ?? 0;
    if (statusCode < 200 || statusCode >= 400) {
      throw Exception('Spotmate respondió $statusCode');
    }

    final body = _asJsonMap(convertResponse.data);
    final url = body['url']?.toString() ?? '';
    if (url.isEmpty) {
      throw Exception('Spotmate no devolvió URL de descarga.');
    }

    return url;
  }

  static String? _extractCookieFromSetCookies(
    List<String> setCookies,
    String key,
  ) {
    for (final cookie in setCookies) {
      final value = ExtractorUtils.extractCookieValue(cookie, key);
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  static String _buildCookieHeaderFromSetCookies(List<String> setCookies) {
    final pairs = <String>[];
    final seen = <String>{};

    for (final cookie in setCookies) {
      final firstPart = cookie.split(';').first.trim();
      final eq = firstPart.indexOf('=');
      if (eq <= 0) continue;

      final name = firstPart.substring(0, eq).trim();
      final value = firstPart.substring(eq + 1).trim();
      if (name.isEmpty || value.isEmpty) continue;

      if (seen.add(name)) {
        pairs.add('$name=$value');
      }
    }

    return pairs.join('; ');
  }

  static Map<String, dynamic> _asJsonMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry('$key', value));
    }
    if (data is String && data.isNotEmpty) {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry('$key', value));
      }
    }
    return <String, dynamic>{};
  }
}
