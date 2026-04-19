import 'dart:convert';

import 'package:http/http.dart' as http;

import 'extractor_utils.dart';
import 'scraper_config.dart';

class ThreadsExtractor {
  static Future<Map<String, dynamic>> fetch(String sourceUrl) async {
    final response = await http
        .get(Uri.parse(sourceUrl), headers: ScraperConfig.threadsHeaders())
        .timeout(const Duration(seconds: 20));

    if (response.statusCode < 200 || response.statusCode >= 400) {
      throw Exception('Threads respondió ${response.statusCode}');
    }

    final html = utf8.decode(response.bodyBytes, allowMalformed: true);
    final cleaned =
        ExtractorUtils.extractJsonArrayAfterKey(html, '"thread_items":');
    if (cleaned == null) {
      return {'status': false, 'url': sourceUrl};
    }

    final decoded = jsonDecode(cleaned);
    if (decoded is! List || decoded.isEmpty) {
      return {'status': false, 'url': sourceUrl};
    }

    final first = ExtractorUtils.asMap(decoded.first);
    final post = ExtractorUtils.asMap(first?['post']);
    if (post == null) {
      return {'status': false, 'url': sourceUrl};
    }

    final caption = ExtractorUtils.asMap(post['caption']);
    final postInfo =
        ExtractorUtils.asMap(post['text_post_app_info']) ?? <String, dynamic>{};
    final user = ExtractorUtils.asMap(post['user']) ?? <String, dynamic>{};

    final resultBase = {
      'status': true,
      'title':
          ExtractorUtils.parseEscaped(caption?['text']?.toString() ?? 'unknown'),
      'likes': ExtractorUtils.toInt(post['like_count']),
      'repost': ExtractorUtils.toInt(postInfo['repost_count']),
      'reshare': ExtractorUtils.toInt(postInfo['reshare_count']),
      'comments': ExtractorUtils.toInt(postInfo['direct_reply_count']),
      'creation': ExtractorUtils.toInt(post['taken_at']),
      'author': {
        'username': user['username']?.toString() ?? 'unknown',
        'profile_pic_url': user['profile_pic_url']?.toString() ?? '',
        'id': user['id']?.toString() ?? '',
        'is_verified': ExtractorUtils.toBool(user['is_verified']),
      },
    };

    final videoVersions = ExtractorUtils.asList(post['video_versions']);
    if (videoVersions.isNotEmpty) {
      final picked = ExtractorUtils.pickIndex(videoVersions, 1) ??
          ExtractorUtils.pickIndex(videoVersions, 0);
      final vMap = ExtractorUtils.asMap(picked) ?? <String, dynamic>{};
      return {
        ...resultBase,
        'download': {
          'type': 'video',
          'width': ExtractorUtils.toInt(post['original_width']),
          'height': ExtractorUtils.toInt(post['original_height']),
          'url': vMap['url']?.toString() ?? '',
        },
      };
    }

    final audio = ExtractorUtils.asMap(post['audio']);
    if (audio != null && audio['audio_src'] != null) {
      return {
        ...resultBase,
        'download': {
          'type': 'audio',
          'url': audio['audio_src']?.toString() ?? '',
        },
      };
    }

    final carousel = ExtractorUtils.asList(post['carousel_media']);
    if (carousel.isNotEmpty) {
      final media = <Map<String, dynamic>>[];
      for (final item in carousel) {
        final map = ExtractorUtils.asMap(item);
        if (map == null) continue;

        String? type;
        String? url;
        int? width;
        int? height;

        final imageVersions = ExtractorUtils.asMap(map['image_versions2']);
        final candidates = ExtractorUtils.asList(imageVersions?['candidates']);
        if (candidates.isNotEmpty) {
          final c0 = ExtractorUtils.asMap(candidates.first);
          url = c0?['url']?.toString();
          type = 'image';
          width = ExtractorUtils.toNullableInt(c0?['width']);
          height = ExtractorUtils.toNullableInt(c0?['height']);
        }

        final vv = ExtractorUtils.asList(map['video_versions']);
        if (vv.isNotEmpty) {
          final v1 = ExtractorUtils.pickIndex(vv, 1) ??
              ExtractorUtils.pickIndex(vv, 0);
          final vMap = ExtractorUtils.asMap(v1);
          url = vMap?['url']?.toString();
          type = 'video';
          width = ExtractorUtils.toNullableInt(map['original_width']);
          height = ExtractorUtils.toNullableInt(map['original_height']);
        }

        if (url == null || url.isEmpty || type == null) continue;

        media.add({
          'url': url,
          'type': type,
          ...?(width != null ? {'width': width} : null),
          ...?(height != null ? {'height': height} : null),
        });
      }

      if (media.isNotEmpty) {
        return {
          ...resultBase,
          'download': media,
        };
      }
    }

    final imageVersions = ExtractorUtils.asMap(post['image_versions2']);
    final candidates = ExtractorUtils.asList(imageVersions?['candidates']);
    if (candidates.isNotEmpty) {
      final c0 = ExtractorUtils.asMap(candidates.first) ?? <String, dynamic>{};
      return {
        ...resultBase,
        'download': {
          'url': c0['url']?.toString() ?? '',
          'type': 'image',
          'width': ExtractorUtils.toInt(c0['width']),
          'height': ExtractorUtils.toInt(c0['height']),
        },
      };
    }

    return {'status': false, 'url': sourceUrl};
  }
}
