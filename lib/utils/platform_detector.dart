import 'constants.dart';

/// Utility class for platform detection
class PlatformDetector {
  /// Detects which social media platform a URL belongs to
  static String? detectPlatform(String url) {
    for (final entry in AppConstants.platformPatterns.entries) {
      for (final pattern in entry.value) {
        if ((pattern as Pattern).allMatches(url).isNotEmpty) {
          return entry.key;
        }
      }
    }
    return null;
  }
}
