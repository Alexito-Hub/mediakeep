import 'package:flutter/services.dart' show rootBundle;
import 'package:yaml/yaml.dart';

/// Service to get app version from pubspec.yaml
class AppVersionService {
  static String? _version;

  /// Get the app version
  static Future<String> getVersion() async {
    if (_version != null) return _version!;

    try {
      final yamlString = await rootBundle.loadString('pubspec.yaml');
      final yaml = loadYaml(yamlString);
      _version = yaml['version'] ?? '1.0.0';
      return _version!;
    } catch (e) {
      // Fallback version if pubspec.yaml can't be loaded
      return '1.0.0';
    }
  }
}
