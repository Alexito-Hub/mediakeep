/// Application constants
class AppConstants {
  // API Configuration
  // Use 'http://localhost:8080' for local development if running the backend locally
  static const String apiBaseUrl = 'https://api.auralixpe.xyz';
  static const String appSecret =
      'a8f9c1d2b3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0';

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
  static const Duration debounceDelay = Duration(milliseconds: 500);
  static const Duration autoFetchDelay = Duration(milliseconds: 300);
  static const Duration autoPasteDelay = Duration(milliseconds: 800);

  // App Info
  static const String appName = 'Media Keep';
  static const String appVersion = '1.0.0';
  static const String companyName = 'Auralix Inc';
  static const String contactEmail = 'contact@auralix.inc';
  static const String privacyEmail = 'privacy@auralix.inc';
}
