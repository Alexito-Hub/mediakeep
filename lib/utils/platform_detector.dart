import 'constants.dart';

/// Utility class for platform detection
class PlatformDetector {
  /// Detects which social media platform a URL belongs to
  static String? detectPlatform(String url) {
    final normalized = url.toLowerCase();

    for (final entry in AppConstants.platformPatterns.entries) {
      for (final pattern in entry.value) {
        if (normalized.contains(pattern.toLowerCase())) {
          return entry.key;
        }
      }
    }
    return null;
  }
}
