/// Response wrapper for download operations
class DownloadResponse {
  final bool success;
  final String? errorMessage;
  final String? filePath;
  final String? fileName;
  final String? subfolder;
  final String? taskId;

  DownloadResponse._({
    required this.success,
    this.errorMessage,
    this.filePath,
    this.fileName,
    this.subfolder,
    this.taskId,
  });

  factory DownloadResponse.success({
    required String filePath,
    required String fileName,
    required String subfolder,
    String? taskId,
  }) {
    return DownloadResponse._(
      success: true,
      filePath: filePath,
      fileName: fileName,
      subfolder: subfolder,
      taskId: taskId,
    );
  }

  factory DownloadResponse.error(String message) {
    return DownloadResponse._(success: false, errorMessage: message);
  }
}
