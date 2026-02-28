/// Defines the expected structure for a platform's API response
class PlatformSchema {
  final String name;
  final List<FieldRule> requiredFields;
  final List<FieldRule> optionalFields;
  final bool hasDataWrapper; // Some APIs wrap in 'data', others don't

  const PlatformSchema({
    required this.name,
    required this.requiredFields,
    this.optionalFields = const [],
    this.hasDataWrapper = true,
  });
}

/// Rule for validating a single field
class FieldRule {
  final String path; // JSON path like 'data.media.nowatermark.play'
  final FieldType type;
  final List<FieldValidator>? validators;
  final String? errorMessage;

  const FieldRule({
    required this.path,
    required this.type,
    this.validators,
    this.errorMessage,
  });
}

enum FieldType { string, number, boolean, map, list, url, mediaUrl }

/// Custom validators for fields
abstract class FieldValidator {
  bool validate(dynamic value);
  String get errorMessage;
}

class UrlValidator extends FieldValidator {
  @override
  bool validate(dynamic value) {
    if (value is! String) return false;
    return value.startsWith('http://') || value.startsWith('https://');
  }

  @override
  String get errorMessage => 'Must be a valid HTTP(S) URL';
}

class MediaUrlValidator extends FieldValidator {
  static final _mediaPatterns = [
    'cdninstagram',
    'fbcdn',
    'tiktokcdn',
    'scdn.co',
    '.jpg',
    '.jpeg',
    '.png',
    '.mp4',
    '.webp',
    '.mp3',
  ];

  @override
  bool validate(dynamic value) {
    if (value is! String) return false;
    return _mediaPatterns.any((p) => value.toLowerCase().contains(p));
  }

  @override
  String get errorMessage => 'Must be a valid media URL';
}

class MinLengthValidator extends FieldValidator {
  final int minLength;
  MinLengthValidator(this.minLength);

  @override
  bool validate(dynamic value) {
    if (value is String) return value.length >= minLength;
    if (value is List) return value.length >= minLength;
    return false;
  }

  @override
  String get errorMessage => 'Must have at least $minLength items/characters';
}
