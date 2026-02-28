import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'api_service.dart';
import 'download_service.dart';
import '../utils/platform_detector.dart';

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
  try {
    // 1. Detect platform
    final platform = PlatformDetector.detectPlatform(url);
    if (platform == null) {
      await channel.invokeMethod('downloadError', {
        'message': 'Plataforma no soportada',
      });
      return;
    }

    // 2. Fetch media info
    final response = await ApiService.fetchMedia(url: url, platform: platform);
    if (!response.success || response.data == null) {
      await channel.invokeMethod('downloadError', {
        'message': response.errorMessage ?? 'Error fetching media',
      });
      return;
    }

    // Parse data to get title/type (simplified for background)
    // We need to parse enough to get the title and type for the download
    final parsedData = ApiService.parseResponseData(response.data!, platform);

    // Extract title and type from known models
    String title = 'media';
    // Default to video, but we should try to detect if it's image/audio
    // For simplicity in background, we'll default to video unless it's specific
    String type = 'video';

    // Helper to extract data dynamically if possible, or use specific casts
    // Since we don't have a unified interface properties, we check likely types
    // Note: This is a simplified extraction.
    dynamic data = parsedData;
    try {
      title = data.title ?? 'media';
    } catch (_) {}

    // Some logic to determine type based on platform or data
    if (platform == 'spotify') {
      type = 'audio';
    } else if (platform == 'instagram' && url.contains('/p/')) {
      // Instagram posts might be images, but for now we might default to whatever logic matches
      // If we want to support images, we need better detection.
      // For this implementation, we proceed with 'video' as primary target for TikTok/Reels which are main use cases.
    }

    // 3. Start Download
    final result = await DownloadService.startDownload(
      url: url,
      type: type,
      platform: platform,
      title: title,
      onProgress: (progress, status) {
        // Optional: Send progress back to native if we wanted a progress bar notification
      },
    );

    if (result.success) {
      await channel.invokeMethod('downloadComplete', {
        'filename': result.fileName,
        'filepath': result.filePath,
      });
    } else {
      await channel.invokeMethod('downloadError', {
        'message': result.errorMessage ?? 'Download failed',
      });
    }
  } catch (e) {
    debugPrint("Background download error: $e");
    await channel.invokeMethod('downloadError', {'message': e.toString()});
  }
}
