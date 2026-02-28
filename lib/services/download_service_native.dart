import 'dart:io';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'history_service.dart';
import '../core/types/typedefs.dart';
import '../core/responses/download_response.dart';

class DownloadService {
  static Future<DownloadResponse> startDownload({
    required String url,
    required String type,
    required String platform,
    String? title,
    String? sourceUrl,
    String? contentId,
    required ProgressCallback onProgress,
  }) async {
    try {
      final directory = await _getDownloadDirectory();
      if (directory == null) {
        return DownloadResponse.error('No se encontró carpeta de destino');
      }

      final mediaKeepDir = Directory(
        '${directory.path}${Platform.pathSeparator}MediaKeep',
      );
      if (!await mediaKeepDir.exists()) {
        await mediaKeepDir.create(recursive: true);
      }

      String subfolder = type == 'video'
          ? 'video'
          : (type == 'audio' ? 'audio' : 'imagen');
      final typeDir = Directory(
        '${mediaKeepDir.path}${Platform.pathSeparator}$subfolder',
      );
      if (!await typeDir.exists()) {
        await typeDir.create(recursive: true);
      }

      final fileName = _generateFileName(title, type);
      final savePath = '${typeDir.path}${Platform.pathSeparator}$fileName';

      final taskId = await FlutterDownloader.enqueue(
        url: url,
        savedDir: typeDir.path,
        fileName: fileName,
        showNotification: false,
        openFileFromNotification: false,
        saveInPublicStorage: true,
      );

      if (taskId == null) {
        return DownloadResponse.error('No se pudo inicializar la descarga.');
      }

      onProgress(0.1, 'Descarga delegada a segundo plano...');

      // History tracking
      await HistoryService.addDownload(
        fileName: fileName,
        filePath: savePath,
        platform: platform,
        type: type,
        fileSize: 0, // Set to 0 initially as it's background
        sourceUrl: sourceUrl,
        contentId: contentId,
      );

      return DownloadResponse.success(
        filePath: savePath,
        fileName: fileName,
        subfolder: subfolder,
      );
    } catch (e) {
      return DownloadResponse.error('Falló la descarga. Intenta de nuevo.');
    }
  }

  static Future<Directory?> _getDownloadDirectory() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return await getDownloadsDirectory();
    } else if (Platform.isAndroid) {
      Directory directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        return await getExternalStorageDirectory();
      }
      return directory;
    } else {
      return await getApplicationDocumentsDirectory();
    }
  }

  static String _generateFileName(String? title, String type) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = type == 'video'
        ? 'mp4'
        : (type == 'audio' ? 'mp3' : 'jpg');
    String safeTitle = title?.replaceAll(RegExp(r'[^\w\s\-]'), '') ?? 'media';
    safeTitle = safeTitle.trim().replaceAll(RegExp(r'\s+'), '_');
    if (safeTitle.length > 25) safeTitle = safeTitle.substring(0, 25);
    return 'MediaKeep_${safeTitle}_$timestamp.$extension';
  }
}
