import 'dart:convert';

import 'package:http/http.dart' as http;

import 'extractor_utils.dart';
import 'scraper_config.dart';

class FacebookExtractor {
  static Future<Map<String, dynamic>> fetch(String sourceUrl) async {
    if (!RegExp(r'facebook\.com|fb\.watch', caseSensitive: false)
        .hasMatch(sourceUrl)) {
      throw Exception('Invalid Facebook URL');
    }

    final response = await http
        .get(Uri.parse(sourceUrl), headers: ScraperConfig.facebookHeaders())
        .timeout(const Duration(seconds: 15));

    if (response.statusCode < 200 || response.statusCode >= 400) {
      throw Exception('Facebook respondió ${response.statusCode}');
    }

    final html = utf8
        .decode(response.bodyBytes, allowMalformed: true)
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&');

    final blobs = <dynamic>[];
    final scriptMatches = RegExp(
      r'<script[^>]*>(\{.+?})<\/script>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(html);

    for (final match in scriptMatches) {
      final jsonText = match.group(1);
      if (jsonText == null || jsonText.isEmpty) continue;
      try {
        blobs.add(jsonDecode(jsonText));
      } catch (_) {
        // Ignore malformed script blobs.
      }
    }

    dynamic get(String key) {
      dynamic found;
      for (final blob in blobs) {
        found ??= ExtractorUtils.pickRecursive(blob, key);
      }
      return found;
    }

    String? og(String propertyName) {
      final p = RegExp.escape(propertyName);
      final match = RegExp(
        '(?:property|name)="$p"\\s+content="([^"]+)"',
        caseSensitive: false,
      ).firstMatch(html);
      return match?.group(1);
    }

    final owner = get('owner');
    final owningProfile = get('owning_profile');
    final actors = get('actors');
    final actor0 = actors is List && actors.isNotEmpty ? actors.first : null;

    final rawAuthor =
        ExtractorUtils.pickRecursive(owner, 'name')?.toString() ??
        ExtractorUtils.pickRecursive(owningProfile, 'name')?.toString() ??
        ExtractorUtils.pickRecursive(actor0, 'name')?.toString() ??
        og('og:title') ??
        'Facebook User';

    final author = rawAuthor
            .replaceAll(RegExp(r'&#\w+;'), '')
            .split(' | ')[0]
            .split(' posted a ')[0]
            .trim()
            .isEmpty
        ? 'Facebook User'
        : rawAuthor
              .replaceAll(RegExp(r'&#\w+;'), '')
              .split(' | ')[0]
              .split(' posted a ')[0]
              .trim();

    final msg = get('message');
    final title = msg is Map
        ? msg['text']?.toString() ?? (og('og:description') ?? 'Facebook Post')
        : (msg?.toString() ?? (og('og:description') ?? 'Facebook Post'));

    final ts = ExtractorUtils.toNullableInt(get('creation_time')) ??
        ExtractorUtils.toNullableInt(get('publish_time'));

    final base = <String, dynamic>{
      'url': sourceUrl,
      'author': author,
      'title': title,
      'creation': ts != null
          ? DateTime.fromMillisecondsSinceEpoch(ts * 1000).toLocal().toString()
          : null,
    };

    final allSubattachments = ExtractorUtils.asMap(get('all_subattachments'));
    final nodes = ExtractorUtils.asList(allSubattachments?['nodes']);

    if (nodes.isNotEmpty) {
      final seen = <String>{};
      final images = <String>[];
      for (final node in nodes) {
        final viewerImage = ExtractorUtils.pickRecursive(node, 'viewer_image');
        final image = ExtractorUtils.pickRecursive(node, 'image');
        final uri =
            ExtractorUtils.decodeMaybeEscaped(
              ExtractorUtils.pickRecursive(viewerImage, 'uri'),
            ) ??
            ExtractorUtils.decodeMaybeEscaped(
              ExtractorUtils.pickRecursive(image, 'uri'),
            );
        if (uri != null && uri.isNotEmpty && seen.add(uri)) {
          images.add(uri);
        }
      }

      if (images.isNotEmpty) {
        return {
          'status': true,
          'data': {
            ...base,
            'type': 'album',
            'images': images,
          },
        };
      }
    }

    final videoUrl =
        ExtractorUtils.decodeMaybeEscaped(get('browser_native_hd_url')) ??
        ExtractorUtils.decodeMaybeEscaped(get('playable_url_quality_hd')) ??
        ExtractorUtils.decodeMaybeEscaped(get('browser_native_sd_url')) ??
        ExtractorUtils.decodeMaybeEscaped(get('playable_url'));

    if (videoUrl != null && videoUrl.isNotEmpty) {
      final preferredThumb =
          ExtractorUtils.pickRecursive(get('preferred_thumbnail'), 'uri');
      return {
        'status': true,
        'data': {
          ...base,
          'type': 'video',
          'download': videoUrl,
          'thumbnail':
              ExtractorUtils.decodeMaybeEscaped(preferredThumb) ?? og('og:image'),
          'duration': ExtractorUtils.toInt(get('playable_duration_in_ms')),
        },
      };
    }

    final photoImage = ExtractorUtils.pickRecursive(get('photo_image'), 'uri');
    final image = ExtractorUtils.pickRecursive(get('image'), 'uri');
    final imgUri =
        ExtractorUtils.decodeMaybeEscaped(photoImage) ??
        ExtractorUtils.decodeMaybeEscaped(image) ??
        og('og:image');

    if (imgUri != null && imgUri.isNotEmpty) {
      return {
        'status': true,
        'data': {
          ...base,
          'type': 'image',
          'download': imgUri,
        },
      };
    }

    throw Exception('Content not found (private or deleted)');
  }
}
