import 'platform_schema.dart';

/// Central registry of all platform validation schemas
class PlatformSchemas {
  static final Map<String, PlatformSchema> schemas = {
    'tiktok': PlatformSchema(
      name: 'TikTok',
      hasDataWrapper: true,
      requiredFields: [
        FieldRule(path: 'id', type: FieldType.string),
        FieldRule(path: 'title', type: FieldType.string),
        FieldRule(
          path: 'media.nowatermark.play',
          type: FieldType.url,
          validators: [UrlValidator(), MediaUrlValidator()],
          errorMessage: 'TikTok video URL is missing or invalid',
        ),
        FieldRule(path: 'author.nickname', type: FieldType.string),
        FieldRule(path: 'views_count', type: FieldType.number),
      ],
      optionalFields: [
        FieldRule(path: 'music', type: FieldType.map),
        FieldRule(path: 'media.nowatermark.hd', type: FieldType.map),
        FieldRule(path: 'cover', type: FieldType.string),
      ],
    ),
    'facebook': PlatformSchema(
      name: 'Facebook',
      hasDataWrapper: true,
      requiredFields: [
        FieldRule(path: 'type', type: FieldType.string),
        FieldRule(path: 'author', type: FieldType.string),
        FieldRule(
          path: 'download',
          type: FieldType.url,
          validators: [UrlValidator(), MediaUrlValidator()],
          errorMessage: 'Facebook download URL is missing or invalid',
        ),
      ],
      optionalFields: [
        FieldRule(path: 'thumbnail', type: FieldType.url),
        FieldRule(path: 'duration', type: FieldType.number),
      ],
    ),
    'spotify': PlatformSchema(
      name: 'Spotify',
      hasDataWrapper: true,
      requiredFields: [
        FieldRule(path: 'id', type: FieldType.string),
        FieldRule(path: 'title', type: FieldType.string),
        FieldRule(
          path: 'artist',
          type: FieldType.list,
          validators: [MinLengthValidator(1)],
          errorMessage: 'Artist list is empty',
        ),
        FieldRule(
          path: 'download',
          type: FieldType.url,
          validators: [UrlValidator()],
          errorMessage: 'Spotify download URL is missing',
        ),
      ],
      optionalFields: [
        FieldRule(path: 'thumbnail', type: FieldType.url),
        FieldRule(path: 'popularity', type: FieldType.string),
      ],
    ),
    'threads': PlatformSchema(
      name: 'Threads',
      hasDataWrapper: false, // Threads doesn't use 'data' wrapper
      requiredFields: [
        FieldRule(path: 'title', type: FieldType.string),
        FieldRule(path: 'author.username', type: FieldType.string),
        FieldRule(
          path: 'download.url',
          type: FieldType.url,
          validators: [UrlValidator(), MediaUrlValidator()],
          errorMessage:
              'Threads download.url is missing or not a valid media URL',
        ),
        FieldRule(path: 'download.type', type: FieldType.string),
      ],
      optionalFields: [
        FieldRule(path: 'likes', type: FieldType.number),
        FieldRule(path: 'comments', type: FieldType.number),
      ],
    ),
  };

  /// Get schema for a platform, returns null if not found
  static PlatformSchema? getSchema(String platform) {
    return schemas[platform.toLowerCase()];
  }

  /// Check if platform has a validation schema
  static bool hasSchema(String platform) {
    return schemas.containsKey(platform.toLowerCase());
  }
}
