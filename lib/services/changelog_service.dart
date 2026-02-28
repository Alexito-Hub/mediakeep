import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/changelog_model.dart';

/// Service to load and parse history of app changes
class ChangelogService {
  static const String _assetPath = 'assets/changelog.json';

  /// Loads the changelog from the local JSON asset
  static Future<List<ChangelogEntry>> getChangelog() async {
    try {
      final jsonString = await rootBundle.loadString(_assetPath);
      final List<dynamic> jsonList = jsonDecode(jsonString);

      return jsonList.map((json) => ChangelogEntry.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Gets only the latest version info
  static Future<ChangelogEntry?> getLatestUpdate() async {
    final changelog = await getChangelog();
    return changelog.isNotEmpty ? changelog.first : null;
  }
}
