class ScraperSecrets {
  // Inject at build/run time, for example:
  // flutter run --dart-define=SCRAPER_APP_TOKEN=...
  static const String appToken = String.fromEnvironment('SCRAPER_APP_TOKEN');

  // Allows changing header name without code changes.
  static const String appTokenHeader = String.fromEnvironment(
    'SCRAPER_APP_TOKEN_HEADER',
    defaultValue: 'x-app-token',
  );

  // Reserved for future providers that need OAuth credentials.
  static const String spotifyClientId = String.fromEnvironment(
    'SPOTIFY_CLIENT_ID',
  );
  static const String spotifyClientSecret = String.fromEnvironment(
    'SPOTIFY_CLIENT_SECRET',
  );

  static bool get hasSpotifyCredentials =>
      spotifyClientId.isNotEmpty && spotifyClientSecret.isNotEmpty;

  static void attachTokenIfPresent(Map<String, String> headers) {
    if (appToken.isEmpty) return;
    headers[appTokenHeader] = appToken;
  }
}
