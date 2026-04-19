import 'package:http/http.dart' as http;

import '../../utils/constants.dart';
import 'extractor_utils.dart';
import 'scraper_config.dart';

class TwitterExtractor {
  static Future<Map<String, dynamic>> fetch(String sourceUrl) async {
    final valid = RegExp(
      r'^https?:\/\/(www\.)?(twitter\.com|x\.com)\/[a-zA-Z0-9_]+\/status\/\d+(\?.*)?$',
      caseSensitive: false,
    ).hasMatch(sourceUrl);

    if (!valid) {
      throw Exception('Invalid twitter url');
    }

    final uri = Uri.parse(
      '${ScraperConfig.twitterApiUrl}?link=${Uri.encodeQueryComponent(sourceUrl)}',
    );

    final response = await http
        .get(uri, headers: ScraperConfig.twitterHeaders())
        .timeout(AppConstants.apiTimeout);

    final body = ExtractorUtils.decodeJsonMap(response.bodyBytes);
    if (response.statusCode != 200 || body.isEmpty) {
      throw Exception('No result found');
    }

    final filtered = <String, dynamic>{};
    for (final entry in body.entries) {
      if (entry.key == 'cursor') continue;
      filtered[entry.key] = entry.value;
    }

    return {'status': true, 'data': filtered};
  }
}
