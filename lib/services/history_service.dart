import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/download_history_model.dart';
import 'widget_service.dart';

/// Manages download history.
/// - For **guest users**: reads/writes from SharedPreferences (local only).
/// - For **authenticated users**: dual-writes to SharedPreferences (for offline/fast load)
///   AND syncs with the backend Firestore collection via `/auth/history`.
class HistoryService {
  static const String _historyKey = 'download_history';
  static const int _maxHistoryItems = 100;

  // ─── Write ────────────────────────────────────────────────────────────────

  static Future<void> addDownload({
    required String fileName,
    required String filePath,
    required String platform,
    required String type,
    required int fileSize,
    String? sourceUrl,
    String? contentId,
  }) async {
    final historyItem = DownloadHistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fileName: fileName,
      filePath: filePath,
      platform: platform,
      type: type,
      downloadedAt: DateTime.now(),
      fileSize: fileSize,
      sourceUrl: sourceUrl,
      contentId: contentId,
    );

    // Save locally (works offline, no auth needed)
    await _writeLocal(historyItem);
    await _syncWidget();
  }

  /// Writes a history entry to local SharedPreferences (fire-and-forget from addDownload).
  static Future<void> _writeLocal(DownloadHistoryItem item) async {
    final prefs = await SharedPreferences.getInstance();
    List<DownloadHistoryItem> history = await _readLocal();

    history.insert(0, item);
    if (history.length > _maxHistoryItems) {
      history = history.take(_maxHistoryItems).toList();
    }

    final jsonList = history.map((item) => item.toJson()).toList();
    await prefs.setString(_historyKey, jsonEncode(jsonList));
  }

  // ─── Read ─────────────────────────────────────────────────────────────────

  /// Returns history items.
  /// - Guest: reads from SharedPreferences only.
  /// - Authenticated: returns local items immediately, then merges with backend.
  static Future<List<DownloadHistoryItem>> getHistory() async {
    return _readLocal();
  }

  static Future<List<DownloadHistoryItem>> _readLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_historyKey);

    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => DownloadHistoryItem.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ─── Filters ──────────────────────────────────────────────────────────────

  static Future<List<DownloadHistoryItem>> getFilteredHistory({
    String? platform,
    String? type,
  }) async {
    List<DownloadHistoryItem> history = await getHistory();

    if (platform != null && platform.isNotEmpty) {
      history = history.where((item) => item.platform == platform).toList();
    }

    if (type != null && type.isNotEmpty) {
      history = history.where((item) => item.type == type).toList();
    }

    return history;
  }

  // ─── Delete ───────────────────────────────────────────────────────────────

  static Future<void> deleteHistoryItem(String id) async {
    final prefs = await SharedPreferences.getInstance();
    List<DownloadHistoryItem> history = await _readLocal();

    history.removeWhere((item) => item.id == id);

    final jsonList = history.map((item) => item.toJson()).toList();
    await prefs.setString(_historyKey, jsonEncode(jsonList));

    await _syncWidget();
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
    await _syncWidget();
  }

  // ─── Utility ──────────────────────────────────────────────────────────────

  static Future<int> getHistoryCount() async {
    final history = await _readLocal();
    return history.length;
  }

  static Future<bool> isContentAlreadyDownloaded({
    String? contentId,
    String? sourceUrl,
  }) async {
    if (contentId == null && sourceUrl == null) return false;

    final history = await _readLocal();
    return history.any((item) {
      if (contentId != null && item.contentId == contentId) return true;
      if (sourceUrl != null && item.sourceUrl == sourceUrl) return true;
      return false;
    });
  }

  static Future<void> _syncWidget() async {
    try {
      final history = await _readLocal();
      final total = history.length;
      final recentItems = history.take(2).map((item) => item.toJson()).toList();
      final recentJson = jsonEncode(recentItems);

      await WidgetService.updateDownloadWidget(
        totalDownloads: total,
        lastDownload: total > 0 ? history.first.fileName : 'Sin descargas',
        recentDownloadsJson: recentJson,
      );
    } catch (e) {
      // Ignore widget sync errors in background
    }
  }
}
