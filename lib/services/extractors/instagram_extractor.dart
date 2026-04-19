import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../utils/constants.dart';
import 'extractor_utils.dart';
import 'scraper_config.dart';

class InstagramExtractor {
  static Future<Map<String, dynamic>> fetch(String sourceUrl) async {
    final verifyReq =
        http.MultipartRequest(
            'POST',
            Uri.parse(ScraperConfig.instagramVerifyUrl),
          )
          ..fields['url'] = sourceUrl
          ..headers.addAll({
            ...ScraperConfig.defaultHeaders(),
            'origin': 'https://savevid.net',
            'referer': 'https://savevid.net/',
          });

    final verifyResp = await verifyReq.send().timeout(AppConstants.apiTimeout);
    final verifyBodyText = await verifyResp.stream.bytesToString();
    final verifyBody = ExtractorUtils.decodeJsonMap(
      utf8.encode(verifyBodyText),
    );
    final token = verifyBody['token']?.toString();
    final verifySetCookie = verifyResp.headers['set-cookie'] ?? '';
    final verifyCookieHeader = ExtractorUtils.buildCookieHeader(
      verifySetCookie,
    );

    if (verifyResp.statusCode < 200 ||
        verifyResp.statusCode >= 400 ||
        token == null ||
        token.isEmpty) {
      throw Exception('Failed to get verification token');
    }

    final searchReq =
        http.MultipartRequest(
            'POST',
            Uri.parse(ScraperConfig.instagramSearchUrl),
          )
          ..fields['q'] = sourceUrl
          ..fields['t'] = 'media'
          ..fields['lang'] = 'es'
          ..fields['v'] = 'v2'
          ..fields['cftoken'] = token
          ..headers.addAll({
            ...ScraperConfig.defaultHeaders(),
            'authority': 'v3.savevid.net',
            'origin': 'https://savevid.net',
            'referer': 'https://savevid.net/',
            'priority': 'u=1, i',
            if (verifyCookieHeader.isNotEmpty) 'cookie': verifyCookieHeader,
          });

    final searchResp = await searchReq.send().timeout(
      const Duration(seconds: 25),
    );
    final searchBodyText = await searchResp.stream.bytesToString();
    final searchBody = ExtractorUtils.decodeJsonMap(
      utf8.encode(searchBodyText),
    );

    final html = searchBody['data']?.toString();
    if (searchResp.statusCode < 200 ||
        searchResp.statusCode >= 400 ||
        html == null ||
        html.isEmpty) {
      throw Exception('No data returned from Instagram provider');
    }

    final media = _parseInstagramMedia(html);
    if (media.isEmpty) {
      throw Exception(
        'No media found. The post may be private or unavailable.',
      );
    }

    return {
      'status': true,
      'data': {'media': media},
    };
  }

  static List<Map<String, dynamic>> _parseInstagramMedia(String html) {
    final items = <Map<String, dynamic>>[];

    final liMatches = RegExp(
      r'<li\b[^>]*>([\s\S]*?)<\/li>',
      caseSensitive: false,
    ).allMatches(html);

    for (final match in liMatches) {
      final block = match.group(1) ?? '';
      if (block.isEmpty) continue;

      final thumb = ExtractorUtils.firstMatch(
        block,
        RegExp(r'<img[^>]+src="([^"]+)"', caseSensitive: false),
      );

      final options = <Map<String, String>>[];

      final optionMatches = RegExp(
        r'<option[^>]*value="([^"]+)"[^>]*>([\s\S]*?)<\/option>',
        caseSensitive: false,
      ).allMatches(block);

      for (final opt in optionMatches) {
        final optUrl = opt.group(1)?.trim() ?? '';
        final optRes = ExtractorUtils.stripHtml(opt.group(2) ?? '').trim();
        if (optUrl.isEmpty || optRes.isEmpty) continue;
        options.add({'res': optRes, 'url': optUrl});
      }

      final buttonMatches = RegExp(
        r'<a[^>]*href="([^"]+)"[^>]*>([\s\S]*?)<\/a>',
        caseSensitive: false,
      ).allMatches(block);

      for (final btn in buttonMatches) {
        final href = btn.group(1)?.trim() ?? '';
        final text = ExtractorUtils.stripHtml(btn.group(2) ?? '').trim();
        if (href.isEmpty) continue;
        final exists = options.any((o) => o['url'] == href);
        if (!exists) {
          options.add({'res': text.isEmpty ? 'Download' : text, 'url': href});
        }
      }

      if ((thumb == null || thumb.isEmpty) && options.isEmpty) {
        continue;
      }

      items.add({
        if (thumb != null && thumb.isNotEmpty) 'thumb': thumb,
        'options': options,
        if (options.isNotEmpty) 'download': options.first['url'],
      });
    }

    return items;
  }
}
