import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'background_download_handler.dart';

// Entry point for the background process
@pragma('vm:entry-point')
void backgroundMain() {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the method channel for background communication
  const MethodChannel channel = MethodChannel('com.mediakeep.aur/background');

  // Set up the method call handler
  channel.setMethodCallHandler((MethodCall call) async {
    if (call.method == 'startDownload') {
      final String url = call.arguments as String;
      await _handleBackgroundDownload(url, channel);
    }
  });
}

Future<void> _handleBackgroundDownload(
  String url,
  MethodChannel channel,
) async {
  await BackgroundDownloadHandler.handleBackgroundDownload(url, channel);
}
