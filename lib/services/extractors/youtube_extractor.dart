import 'package:http/http.dart' as http;

import 'extractor_utils.dart';
import 'scraper_config.dart';

class YouTubeExtractor {
  static Future<Map<String, dynamic>> fetch(String sourceUrl) async {
    final response = await http
        .post(
          Uri.parse(ScraperConfig.youtubeProxyUrl),
          headers: {
            ...ScraperConfig.defaultHeaders(),
            'Content-Type': 'application/x-www-form-urlencoded',
            'X-Requested-With': 'XMLHttpRequest',
          },
          body: {'url': sourceUrl},
        )
        .timeout(const Duration(seconds: 20));

    final body = ExtractorUtils.decodeJsonMap(response.bodyBytes);
    final api = ExtractorUtils.asMap(body['api']);

    if (response.statusCode != 200 || api == null) {
      throw Exception('YouTube provider error');
    }

    final status = api['status']?.toString().toUpperCase();
    if (status == 'ERROR') {
      throw Exception(api['message']?.toString() ?? 'YouTube API error');
    }

    final mediaItems = ExtractorUtils.asList(api['mediaItems']);
    final videos = <Map<String, dynamic>>[];
    final audios = <Map<String, dynamic>>[];

    for (final item in mediaItems) {
      final map = ExtractorUtils.asMap(item);
      if (map == null) continue;

      final mediaType = map['type']?.toString().toLowerCase() ?? '';
      final mediaUrl = map['mediaUrl']?.toString() ?? '';
      if (mediaUrl.isEmpty) continue;

      final resolvedUrl = await _pollUrl(mediaUrl);
      if (resolvedUrl.isEmpty) continue;

      final entry = {
        'quality': map['mediaQuality']?.toString(),
        'res': map['mediaRes']?.toString(),
        'size': map['mediaFileSize']?.toString(),
        'format': map['mediaExtension']?.toString(),
        'duration': map['mediaDuration']?.toString(),
        'url': resolvedUrl,
      };

      if (mediaType == 'video') {
        videos.add(entry);
      } else if (mediaType == 'audio') {
        audios.add(entry);
      }
    }

    return {
      'status': true,
      'version': 'v1',
      'data': {
        'info': {
          'id': api['id']?.toString(),
          'title': api['title']?.toString(),
          'desc': api['description']?.toString(),
          'thumb': api['imagePreviewUrl']?.toString(),
          'preview': api['previewUrl']?.toString(),
          'link': api['permanentLink']?.toString() ?? sourceUrl,
          'service': api['service']?.toString(),
        },
        'channel': {
          'name': ExtractorUtils.nested(api, ['userInfo', 'name'])?.toString(),
          'user':
              ExtractorUtils.nested(api, ['userInfo', 'username'])?.toString(),
          'id': ExtractorUtils.nested(api, ['userInfo', 'userId'])?.toString(),
          'avatar':
              ExtractorUtils.nested(api, ['userInfo', 'userAvatar'])?.toString(),
          'verified':
              ExtractorUtils.toBool(ExtractorUtils.nested(api, ['userInfo', 'isVerified'])),
          'site':
              ExtractorUtils.nested(api, ['userInfo', 'externalUrl'])?.toString(),
          'bio': ExtractorUtils.nested(api, ['userInfo', 'userBio'])?.toString(),
          'category':
              ExtractorUtils.nested(api, ['userInfo', 'userCategory'])?.toString(),
          'internal':
              ExtractorUtils.nested(api, ['userInfo', 'internalUrl'])?.toString(),
          'country':
              ExtractorUtils.nested(api, ['userInfo', 'accountCountry'])?.toString(),
          'joined':
              ExtractorUtils.nested(api, ['userInfo', 'dateJoined'])?.toString(),
        },
        'stats': {
          'views':
              ExtractorUtils.nested(api, ['mediaStats', 'viewsCount'])?.toString(),
          'vids':
              ExtractorUtils.nested(api, ['mediaStats', 'mediaCount'])?.toString(),
          'subs':
              ExtractorUtils.nested(api, ['mediaStats', 'followersCount'])?.toString(),
          'following':
              ExtractorUtils.nested(api, ['mediaStats', 'followingCount'])?.toString(),
          'likes':
              ExtractorUtils.nested(api, ['mediaStats', 'likesCount'])?.toString(),
          'comments':
              ExtractorUtils.nested(api, ['mediaStats', 'commentsCount'])?.toString(),
          'favorites':
              ExtractorUtils.nested(api, ['mediaStats', 'favouritesCount'])?.toString(),
          'shares':
              ExtractorUtils.nested(api, ['mediaStats', 'sharesCount'])?.toString(),
          'downloads':
              ExtractorUtils.nested(api, ['mediaStats', 'downloadsCount'])?.toString(),
        },
        'videos': videos,
        'audios': audios,
      },
    };
  }

  static Future<String> _pollUrl(
    String mediaUrl, {
    Duration delay = const Duration(seconds: 3),
    int maxRetries = 20,
  }) async {
    final headers = {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      'Referer': 'https://app.ytdown.to/',
      'X-Requested-With': 'XMLHttpRequest',
    };

    for (int i = 0; i < maxRetries; i++) {
      try {
        final response = await http
            .get(Uri.parse(mediaUrl), headers: headers)
            .timeout(const Duration(seconds: 20));

        final contentType = response.headers['content-type'] ?? '';
        if (!contentType.toLowerCase().contains('application/json')) {
          return mediaUrl;
        }

        final body = ExtractorUtils.decodeJsonMap(response.bodyBytes);
        final percent = body['percent']?.toString();
        final fileUrl = body['fileUrl']?.toString();

        if (percent == 'Completed' &&
            fileUrl != null &&
            fileUrl.isNotEmpty &&
            fileUrl != 'In Processing...') {
          return fileUrl;
        }
      } catch (_) {
        // Continue polling.
      }

      await Future.delayed(delay);
    }

    return '';
  }
}
