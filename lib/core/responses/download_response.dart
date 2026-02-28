/// Response wrapper for download operations
class DownloadResponse {
  final bool success;
  final String? errorMessage;
  final String? filePath;
  final String? fileName;
  final String? subfolder;

  DownloadResponse._({
    required this.success,
    this.errorMessage,
    this.filePath,
    this.fileName,
    this.subfolder,
  });

  factory DownloadResponse.success({
    required String filePath,
    required String fileName,
    required String subfolder,
  }) {
    return DownloadResponse._(
      success: true,
      filePath: filePath,
      fileName: fileName,
      subfolder: subfolder,
    );
  }

  factory DownloadResponse.error(String message) {
    return DownloadResponse._(success: false, errorMessage: message);
  }
}
