/// Application constants
class AppConstants {
  // Local extraction mode (no custom backend endpoints).

  // Platform detection patterns
  static const Map<String, List<String>> platformPatterns = {
    'tiktok': [
      r'tiktok.com',
      r'vm.tiktok.com',
      r'vt.tiktok.com',
      r'www.tiktok.com',
      r'm.tiktok.com',
    ],
    'facebook': [r'facebook.com', r'fb.watch', r'www.facebook.com'],
    'spotify': [r'spotify.com', r'open.spotify.com'],
    'threads': [r'threads.net', r'thread.com', r'www.threads.com'],
    'youtube': [
      r'youtube.com',
      r'www.youtube.com',
      r'youtu.be',
      r'm.youtube.com',
    ],
    'bilibili': [r'bilibili.tv', r'www.bilibili.tv', r'bilibili.com'],
    'instagram': [r'instagram.com', r'www.instagram.com', r'instagr.am'],
    'twitter': [r'twitter.com', r'x.com', r'www.x.com', r'mobile.twitter.com'],
  };

  // Timeout durations
  static const Duration apiTimeout = Duration(seconds: 15);
  static const Duration debounceDelay = Duration(milliseconds: 200);
  static const Duration autoFetchDelay = Duration(milliseconds: 100);
  static const Duration autoPasteDelay = Duration(milliseconds: 600);

  // App Info
  static const String appName = 'Media Keep';
  static const String appVersion = '1.0.0';
  static const String companyName = 'Auralix Inc';
  static const String contactEmail = 'contact@auralix.inc';
  static const String privacyEmail = 'privacy@auralix.inc';
}
