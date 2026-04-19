import 'package:flutter/services.dart';

import '../models/facebook_model.dart';
import '../models/instagram_model.dart';
import '../models/spotify_model.dart';
import '../models/threads_model.dart';
import '../models/tiktok_model.dart';
import '../models/twitter_model.dart';
import '../models/youtube_model.dart';
import '../utils/platform_detector.dart';
import 'api_service.dart';
import 'download_service.dart';
import 'history_service.dart';

class BackgroundDownloadHandler {
  static Future<void> handleBackgroundDownload(
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

      // Check duplicate source URL in history.
      final isDuplicate = await HistoryService.isContentAlreadyDownloaded(
        sourceUrl: url,
      );
      if (isDuplicate) {
        await channel.invokeMethod('downloadError', {
          'message': 'Este contenido ya fue descargado previamente.',
        });
        return;
      }

      // 2. Fetch media info
      final response = await ApiService.fetchMedia(
        url: url,
        platform: platform,
      );
      if (!response.success || response.data == null) {
        await channel.invokeMethod('downloadError', {
          'message': response.errorMessage ?? 'Error fetching media',
        });
        return;
      }

      // 3. Parse and extract best candidate media URL
      String? downloadUrl;
      String title = 'media';
      String type = 'video';

      final parsedData = ApiService.parseResponseData(response.data!, platform);

      if (platform == 'tiktok' && parsedData is TikTokData) {
        title = parsedData.title;
        downloadUrl = parsedData.media.noWatermark?.hdPlay;

        if (downloadUrl == null || downloadUrl.isEmpty) {
          downloadUrl = parsedData.media.noWatermark?.play;
        }
        if (downloadUrl == null || downloadUrl.isEmpty) {
          downloadUrl = parsedData.media.watermark?.play;
        }

        type = 'video';
        if (parsedData.media.images.isNotEmpty &&
            (downloadUrl == null || downloadUrl.isEmpty)) {
          downloadUrl = parsedData.media.images.first;
          type = 'image';
        }
      } else if (platform == 'facebook' && parsedData is FacebookData) {
        title = parsedData.title;
        downloadUrl = parsedData.download;
        if (downloadUrl == null || downloadUrl.isEmpty) {
          downloadUrl = parsedData.url;
        }
        type = parsedData.type;
      } else if (platform == 'instagram' && parsedData is InstagramData) {
        if (parsedData.media.isNotEmpty) {
          final media = parsedData.media.first;
          downloadUrl = media.download;
          if ((downloadUrl == null || downloadUrl.isEmpty) &&
              media.options.isNotEmpty) {
            downloadUrl = media.options.first.url;
          }
          title = 'instagram_media';
          type = (downloadUrl != null && downloadUrl.contains('.jpg'))
              ? 'image'
              : 'video';
        }
      } else if (platform == 'youtube' && parsedData is YouTubeData) {
        title = parsedData.info.title ?? 'youtube_video';
        if (parsedData.videos.isNotEmpty) {
          downloadUrl = parsedData.videos.first.url;
        }
        type = 'video';
      } else if (platform == 'spotify' && parsedData is SpotifyData) {
        title = parsedData.title;
        downloadUrl = parsedData.download;
        type = 'audio';
      } else if (platform == 'twitter' && parsedData is TwitterData) {
        title = parsedData.title ?? 'twitter_media';
        if (parsedData.media != null && parsedData.media!.isNotEmpty) {
          final media = parsedData.media!.first;
          downloadUrl = media.url;
          type = media.type ?? 'video';
        }
      } else if (platform == 'threads' && parsedData is ThreadsData) {
        if (parsedData.media.isNotEmpty) {
          downloadUrl = parsedData.media.first.url;
          type = parsedData.media.first.type;
        }
      }

      if (downloadUrl == null || downloadUrl.isEmpty) {
        await channel.invokeMethod('downloadError', {
          'message': 'No se pudo extraer el enlace de descarga.',
        });
        return;
      }

      final statusMsg =
          'Descargando $type de ${platform.substring(0, 1).toUpperCase()}${platform.substring(1)}...';
      await channel.invokeMethod('updateStatus', {'status': statusMsg});

      // 4. Start download in background
      final result = await DownloadService.startDownload(
        url: downloadUrl,
        type: type,
        platform: platform,
        title: title,
        sourceUrl: url,
        onProgress: (progress, status) {},
      );

      if (result.success) {
        await channel.invokeMethod('downloadComplete', {
          'filename': result.fileName,
          'filepath': result.filePath,
          'title': title,
        });
      } else {
        await channel.invokeMethod('downloadError', {
          'message': result.errorMessage ?? 'Download failed',
        });
      }
    } catch (e) {
      await channel.invokeMethod('downloadError', {'message': e.toString()});
    }
  }
}
