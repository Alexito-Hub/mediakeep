import '../core/types/typedefs.dart';
import '../core/responses/download_response.dart';
import 'package:url_launcher/url_launcher.dart';

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
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return DownloadResponse.success(
          filePath: url,
          fileName: 'Abierto en navegador',
          subfolder: 'web',
        );
      }
      return DownloadResponse.error(
        'No se pudo abrir el enlace en el navegador.',
      );
    } catch (e) {
      return DownloadResponse.error('Error al intentar abrir el enlace.');
    }
  }
}
