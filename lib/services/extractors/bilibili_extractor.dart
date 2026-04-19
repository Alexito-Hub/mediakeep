import 'dart:convert';

import 'package:http/http.dart' as http;

import 'extractor_utils.dart';
import 'scraper_config.dart';

class BilibiliExtractor {
  static Future<Map<String, dynamic>> fetch(String sourceUrl) async {
    final numericMatch = RegExp(r'/video/(\d+)').firstMatch(sourceUrl);
    final bvMatch = RegExp(r'/video/(BV[a-zA-Z0-9]+)').firstMatch(sourceUrl);

    final aid = numericMatch?.group(1);
    final bvid = bvMatch?.group(1);

    if (aid == null && bvid == null) {
      throw Exception('Video ID not found');
    }

    final isBilibiliCn = sourceUrl.contains('bilibili.com');
    final isBilibiliTv = sourceUrl.contains('bilibili.tv');

    if (isBilibiliCn && bvid != null) {
      throw Exception(
        'Bilibili.com (BV IDs) requires API access. Use bilibili.tv links.',
      );
    }

    if (!isBilibiliTv || aid == null) {
      throw Exception('Solo se soportan enlaces bilibili.tv con AID numerico.');
    }

    final pageResp = await http
        .get(Uri.parse(sourceUrl), headers: ScraperConfig.defaultHeaders())
        .timeout(const Duration(seconds: 20));

    if (pageResp.statusCode < 200 || pageResp.statusCode >= 400) {
      throw Exception('Bilibili respondió ${pageResp.statusCode}');
    }

    final html = utf8.decode(pageResp.bodyBytes, allowMalformed: true);

    final title = ExtractorUtils.extractMetaContent(html, 'og:title')
        ?.split('|')
        .first
        .trim();
    final description = ExtractorUtils.extractMetaContent(html, 'og:description');
    final type = ExtractorUtils.extractMetaContent(html, 'og:video:type');
    final cover = ExtractorUtils.extractMetaContent(html, 'og:image');
    final duration = ExtractorUtils.extractMetaContent(html, 'og:video:duration');

    final playUri = Uri.parse(ScraperConfig.bilibiliPlayUrl).replace(
      queryParameters: {
        's_locale': 'id_ID',
        'platform': 'web',
        'aid': aid,
        'qn': '64',
        'type': '0',
        'device': 'wap',
        'tf': '0',
        'spm_id': 'bstar-web.ugc-video-detail.0.0',
        'from_spm_id': 'bstar-web.homepage.trending.all',
        'fnval': '16',
        'fnver': '0',
      },
    );

    final playResp = await http
        .get(playUri, headers: ScraperConfig.defaultHeaders())
        .timeout(const Duration(seconds: 20));

    final playBody = ExtractorUtils.decodeJsonMap(playResp.bodyBytes);
    final videosRaw = ExtractorUtils.asList(
      ExtractorUtils.nested(playBody, ['data', 'playurl', 'video']),
    );
    final audiosRaw = ExtractorUtils.asList(
      ExtractorUtils.nested(playBody, ['data', 'playurl', 'audio_resource']),
    );

    final videos = <Map<String, dynamic>>[];
    for (final item in videosRaw) {
      final map = ExtractorUtils.asMap(item);
      if (map == null) continue;

      final streamInfo = ExtractorUtils.asMap(map['stream_info']) ??
          <String, dynamic>{};
      final resource =
          ExtractorUtils.asMap(map['video_resource']) ?? <String, dynamic>{};
      final url = resource['url']?.toString() ?? '';
      if (url.isEmpty) continue;

      videos.add({
        'desc':
            streamInfo['desc_words']?.toString() ??
            streamInfo['quality_desc']?.toString() ??
            'Video',
        'quality': ExtractorUtils.toInt(streamInfo['quality']),
        'format': (resource['mime_type']?.toString().split('/').last ?? 'mp4'),
        'url': url,
        'backup': ExtractorUtils.toStringList(resource['backup_url']),
      });
    }

    final audios = <Map<String, dynamic>>[];
    for (final item in audiosRaw) {
      final map = ExtractorUtils.asMap(item);
      if (map == null) continue;
      final url = map['url']?.toString() ?? '';
      if (url.isEmpty) continue;

      audios.add({
        'quality': ExtractorUtils.toInt(map['quality']),
        'format': map['mime_type']?.toString().split('/').last ?? 'mp3',
        'url': url,
        'backup': ExtractorUtils.toStringList(map['backup_url']),
      });
    }

    return {
      'status': true,
      'data': {
        'info': {
          'aid': aid,
          'bvid': bvid,
          'title': title,
          'desc': description,
          'type': type,
          'cover': cover,
          'duration': duration,
        },
        'stats': {
          'views': null,
          'likes': null,
          'coins': null,
          'favorites': null,
          'shares': null,
          'comments': null,
          'danmaku': null,
        },
        'videos': videos,
        'audios': audios,
      },
    };
  }
}
