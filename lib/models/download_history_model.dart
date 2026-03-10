/// Model for download history items
class DownloadHistoryItem {
  final String id;
  final String fileName;
  String filePath;
  final String platform; // tiktok, facebook, spotify, threads
  final String type; // video, audio, image
  final DateTime downloadedAt;
  int fileSize; // in bytes
  final String? sourceUrl;
  final String? contentId;

  DownloadHistoryItem({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.platform,
    required this.type,
    required this.downloadedAt,
    required this.fileSize,
    this.sourceUrl,
    this.contentId,
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'filePath': filePath,
      'platform': platform,
      'type': type,
      'downloadedAt': downloadedAt.toIso8601String(),
      'fileSize': fileSize,
      'sourceUrl': sourceUrl,
      'contentId': contentId,
    };
  }

  /// Create from JSON
  factory DownloadHistoryItem.fromJson(Map<String, dynamic> json) {
    return DownloadHistoryItem(
      id: json['id'] ?? '',
      fileName: json['fileName'] ?? '',
      filePath: json['filePath'] ?? '',
      platform: json['platform'] ?? '',
      type: json['type'] ?? '',
      downloadedAt: DateTime.parse(
        json['downloadedAt'] ?? DateTime.now().toIso8601String(),
      ),
      fileSize: json['fileSize'] ?? 0,
      sourceUrl: json['sourceUrl'],
      contentId: json['contentId'],
    );
  }

  /// Get formatted date (e.g., "13 Dic 2025, 12:45 PM")
  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(downloadedAt);

    // Show relative time for recent downloads
    if (diff.inMinutes < 1) {
      return 'Justo ahora';
    } else if (diff.inMinutes < 60) {
      return 'Hace ${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      return 'Hace ${diff.inHours} h';
    } else if (diff.inDays < 7) {
      return 'Hace ${diff.inDays} ${diff.inDays == 1 ? 'día' : 'días'}';
    } else {
      // For older dates, use simple formatting without locale
      final day = downloadedAt.day.toString().padLeft(2, '0');
      final month = downloadedAt.month.toString().padLeft(2, '0');
      final year = downloadedAt.year;
      final hour = downloadedAt.hour > 12
          ? downloadedAt.hour - 12
          : (downloadedAt.hour == 0 ? 12 : downloadedAt.hour);
      final minute = downloadedAt.minute.toString().padLeft(2, '0');
      final period = downloadedAt.hour >= 12 ? 'PM' : 'AM';

      return '$day/$month/$year, $hour:$minute $period';
    }
  }

  /// Get formatted file size (e.g., "12.5 MB")
  String get formattedSize {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// Get platform display name
  String get platformName {
    switch (platform.toLowerCase()) {
      case 'tiktok':
        return 'TikTok';
      case 'facebook':
      case 'instagram':
        return 'Facebook';
      case 'spotify':
        return 'Spotify';
      case 'threads':
        return 'Threads';
      default:
        // Capitalize first letter if unknown
        return platform.isEmpty
            ? 'Desconocido'
            : platform[0].toUpperCase() + platform.substring(1);
    }
  }

  /// Get type display name
  String get typeName {
    switch (type) {
      case 'video':
        return 'Video';
      case 'audio':
        return 'Audio';
      case 'image':
        return 'Imagen';
      case 'threads':
        return 'Threads'; // Assuming this was the intended string for 'threads' type
      default:
        return type;
    }
  }
}
