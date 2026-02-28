/// Abstract interface for the download service
abstract class DownloadServiceBase {
  static Future<dynamic> startDownload({
    required String url,
    required String type,
    required String platform,
    String? title,
    String? sourceUrl,
    String? contentId,
    required Function(double progress, String status) onProgress,
  }) async {
    throw UnimplementedError('Subclasses must implement startDownload');
  }
}
