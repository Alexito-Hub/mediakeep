import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:flutter/services.dart';

/// Service to manage the home screen widget
class WidgetService {
  static const String _appGroupId = 'group.com.mediakeep.aur';
  static const String _androidName = 'MediaKeepWidgetProvider';
  static const String _channelName = 'com.mediakeep.aur/widget_actions';
  static const _channel = MethodChannel(_channelName);

  /// Callback for widget actions
  static Function(String action, String? url)? onActionReceived;

  /// Verifica si el widget es soportado en la plataforma actual
  static bool get isSupported {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  static Future<void> initialize() async {
    if (!isSupported) return;

    try {
      await HomeWidget.setAppGroupId(_appGroupId);

      // Configurar listener para acciones nativas
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'onWidgetAction') {
          final data = call.arguments as String;
          _processActionString(data);
        }
      });

      // Revisar si hay una acción inicial (si la app se abrió desde el widget)
      final initialData = await _channel.invokeMethod<String>(
        'getInitialAction',
      );
      if (initialData != null) {
        _processActionString(initialData);
      }
    } catch (e) {
      debugPrint('Error initializing WidgetService: $e');
    }
  }

  static void _processActionString(String data) {
    final parts = data.split('|');
    final action = parts[0];
    final url = parts.length > 1 ? parts[1] : null;

    if (onActionReceived != null) {
      onActionReceived!(action, url);
    }
  }

  /// Updates the download data shown in the widget
  static Future<void> updateDownloadWidget({
    required int totalDownloads,
    required String lastDownload,
    String? recentDownloadsJson,
  }) async {
    if (!isSupported) return;

    try {
      // Save data
      await HomeWidget.saveWidgetData<int>('total_downloads', totalDownloads);
      await HomeWidget.saveWidgetData<String>('last_download', lastDownload);

      if (recentDownloadsJson != null) {
        await HomeWidget.saveWidgetData<String>(
          'recent_downloads',
          recentDownloadsJson,
        );
      }

      // Trigger update
      await HomeWidget.updateWidget(
        name: _androidName,
        androidName: _androidName,
      );
    } catch (e) {
      debugPrint('Error updating widget: $e');
    }
  }

  /// Obtiene un dato guardado en el widget
  static Future<T?> getWidgetData<T>(String key) async {
    if (!isSupported) return null;
    try {
      return await HomeWidget.getWidgetData<T>(key);
    } catch (e) {
      debugPrint('Error getting widget data: $e');
      return null;
    }
  }
}
