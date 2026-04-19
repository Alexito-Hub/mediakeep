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
      final args = call.arguments;
      if (args is! Map) {
        await channel.invokeMethod('downloadError', {
          'message':
              'Solicitud rechazada: accion en segundo plano no autorizada.',
        });
        return;
      }

      final dynamic urlValue = args['url'];
      final dynamic triggerValue = args['trigger'];
      if (urlValue is! String ||
          urlValue.trim().isEmpty ||
          triggerValue != 'share_confirmation') {
        await channel.invokeMethod('downloadError', {
          'message':
              'Solicitud rechazada: se requiere confirmacion explicita del usuario.',
        });
        return;
      }

      await _handleBackgroundDownload(urlValue.trim(), channel);
    }
  });
}

Future<void> _handleBackgroundDownload(
  String url,
  MethodChannel channel,
) async {
  await BackgroundDownloadHandler.handleBackgroundDownload(url, channel);
}
