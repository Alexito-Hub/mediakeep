import 'package:http/http.dart' as http;

import '../../utils/constants.dart';
import 'extractor_utils.dart';
import 'scraper_config.dart';

class TikTokExtractor {
  static Future<Map<String, dynamic>> fetch(String sourceUrl) async {
    final response = await http
        .post(
          Uri.parse(ScraperConfig.tiktokApiUrl),
          headers: ScraperConfig.tiktokHeaders(),
          body: {'url': sourceUrl, 'hd': '1'},
        )
        .timeout(AppConstants.apiTimeout);

    final body = ExtractorUtils.decodeJsonMap(response.bodyBytes);
    final data = ExtractorUtils.asMap(body['data']);

    if (response.statusCode != 200 || data == null) {
      final msg = body['msg']?.toString() ?? 'No se pudo procesar TikTok.';
      throw Exception(msg);
    }

    final duration = ExtractorUtils.toInt(data['duration']);
    final images = ExtractorUtils.toStringList(data['images']);

    final authorRaw = ExtractorUtils.asMap(data['author']) ?? <String, dynamic>{};
    final author = {
      'nickname':
          authorRaw['nickname']?.toString() ??
          authorRaw['unique_id']?.toString() ??
          'TikTok User',
      'avatar': authorRaw['avatar']?.toString() ?? '',
    };

    final musicRaw =
        ExtractorUtils.asMap(data['music_info']) ?? <String, dynamic>{};
    final music = {
      'title': musicRaw['title']?.toString() ?? 'Sonido original',
      'play':
          musicRaw['play']?.toString() ?? musicRaw['url']?.toString() ?? '',
      'author': musicRaw['author']?.toString() ?? '',
    };

    final media = duration == 0
        ? {
            'type': 'image',
            'images': images,
            'image_count': images.length,
          }
        : {
            'type': 'video',
            'duration': duration,
            'nowatermark': {
              'size': ExtractorUtils.toInt(data['size']),
              'play': data['play']?.toString() ?? '',
              'hd': {
                'size': ExtractorUtils.toInt(data['hd_size']),
                'play':
                    data['hdplay']?.toString() ?? data['play']?.toString() ?? '',
              },
            },
            'watermark': {
              'size': ExtractorUtils.toInt(data['wm_size']),
              'play':
                  data['wmplay']?.toString() ?? data['play']?.toString() ?? '',
            },
          };

    return {
      'status': true,
      'data': {
        'id': data['id']?.toString() ?? '',
        'title': data['title']?.toString() ?? 'Sin titulo',
        'cover': data['cover']?.toString() ?? '',
        'media': media,
        'creation': ExtractorUtils.toInt(data['create_time']),
        'views_count': ExtractorUtils.toInt(data['play_count']),
        'like_count': ExtractorUtils.toInt(data['digg_count']),
        'comment_count': ExtractorUtils.toInt(data['comment_count']),
        'share_count': ExtractorUtils.toInt(data['share_count']),
        'author': author,
        'music': music,
      },
    };
  }
}
