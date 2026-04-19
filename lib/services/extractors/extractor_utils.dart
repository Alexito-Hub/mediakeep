import 'dart:convert';

class ExtractorUtils {
  static Map<String, dynamic> decodeJsonMap(List<int> bytes) {
    final text = utf8.decode(bytes, allowMalformed: true);
    final decoded = jsonDecode(text);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry('$key', value));
    }
    return <String, dynamic>{};
  }

  static Map<String, dynamic>? asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, v) => MapEntry('$key', v));
    }
    return null;
  }

  static List<dynamic> asList(dynamic value) {
    if (value is List) return value;
    return const <dynamic>[];
  }

  static int toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static int? toNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static bool toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final v = value.toLowerCase().trim();
      return v == 'true' || v == '1' || v == 'yes';
    }
    return false;
  }

  static List<String> toStringList(dynamic value) {
    if (value is! List) return const <String>[];
    return value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
  }

  static String? decodeMaybeEscaped(dynamic value) {
    if (value == null) return null;
    final text = value.toString();
    if (text.isEmpty) return null;
    return text
        .replaceAll(r'\u002F', '/')
        .replaceAll(r'\u0026', '&')
        .replaceAll(r'\/', '/')
        .replaceAll('&amp;', '&')
        .trim();
  }

  static String parseEscaped(String input) {
    final esc = <String, String>{
      '"': r'\"',
      '\n': r'\n',
      '\r': r'\r',
      '\t': r'\t',
    };

    final escaped = input.replaceAllMapped(
      RegExp(r'["\n\r\t]'),
      (m) => esc[m.group(0)] ?? '',
    );

    try {
      final parsed = jsonDecode('{"text":"$escaped"}');
      if (parsed is Map && parsed['text'] is String) {
        return (parsed['text'] as String).trim();
      }
    } catch (_) {
      // Fallback below
    }

    return input.trim();
  }

  static String? extractJsonArrayAfterKey(String data, String key) {
    final start = data.indexOf(key);
    if (start == -1) return null;

    final arrayStart = data.indexOf('[', start);
    if (arrayStart == -1) return null;

    int count = 1;
    int i = arrayStart + 1;

    while (i < data.length && count > 0) {
      if (data[i] == '[') count++;
      if (data[i] == ']') count--;
      i++;
    }

    if (count != 0) return null;
    return data.substring(arrayStart, i);
  }

  static dynamic pickIndex(List<dynamic> list, int index) {
    if (index < 0 || index >= list.length) return null;
    return list[index];
  }

  static String? extractMetaContent(String html, String propertyName) {
    final escaped = RegExp.escape(propertyName);
    final match = RegExp(
      '<meta[^>]+(?:property|name)="$escaped"[^>]+content="([^"]+)"',
      caseSensitive: false,
    ).firstMatch(html);

    return match?.group(1);
  }

  static String stripHtml(String input) {
    return input
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String? firstMatch(String text, RegExp regex) {
    final match = regex.firstMatch(text);
    return match?.group(1);
  }

  static String? extractCookieValue(String setCookie, String key) {
    final regex = RegExp('$key=([^;]+)');
    return regex.firstMatch(setCookie)?.group(1);
  }

  static String buildCookieHeader(String setCookie) {
    if (setCookie.isEmpty) return '';
    final pairs = <String>[];
    final seen = <String>{};

    final cookieChunks = setCookie.split(RegExp(r',(?=[A-Za-z0-9_\-]+=)'));

    for (final chunk in cookieChunks) {
      final firstPart = chunk.split(';').first.trim();
      final eq = firstPart.indexOf('=');
      if (eq <= 0) continue;

      final key = firstPart.substring(0, eq).trim();
      final value = firstPart.substring(eq + 1).trim();
      if (key.isEmpty || value.isEmpty) continue;

      if (seen.add(key)) {
        pairs.add('$key=$value');
      }
    }

    return pairs.join('; ');
  }

  static dynamic nested(dynamic source, List<String> path) {
    dynamic current = source;
    for (final key in path) {
      if (current is Map && current.containsKey(key)) {
        current = current[key];
      } else {
        return null;
      }
    }
    return current;
  }

  static dynamic pickRecursive(dynamic source, String key) {
    if (source == null) return null;

    if (source is Map) {
      if (source.containsKey(key)) {
        return source[key];
      }
      for (final value in source.values) {
        final nestedValue = pickRecursive(value, key);
        if (nestedValue != null) return nestedValue;
      }
      return null;
    }

    if (source is List) {
      for (final item in source) {
        final nestedValue = pickRecursive(item, key);
        if (nestedValue != null) return nestedValue;
      }
      return null;
    }

    return null;
  }
}
