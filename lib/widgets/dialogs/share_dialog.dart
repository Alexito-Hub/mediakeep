import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../media/audio_preview_widget.dart';
import '../media/video_preview_widget.dart';
import '../../services/settings_service.dart';
import '../../screens/media_preview_screen.dart';

/// Shows a dialog with the downloaded file preview and share option
Future<void> showShareDialog({
  required BuildContext context,
  required String filePath,
  required String fileName,
  required String fileType,
  required Function(String) onError,
}) async {
  // Load custom share message
  final shareMessage = await SettingsService.getShareMessage();

  if (!context.mounted) return;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      final colorScheme = Theme.of(context).colorScheme;
      final isDark = Theme.of(context).brightness == Brightness.dark;

      return Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with success icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.green,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¡Descarga completada!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tu archivo está listo',
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close_rounded,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      tooltip: 'Cerrar',
                    ),
                  ],
                ),
              ),

              // Content with dynamic preview
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dynamic preview - adapts to content
                      Container(
                        constraints: const BoxConstraints(
                          maxHeight: 250,
                          minHeight: 120,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: _buildContentPreview(filePath, fileType),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // File info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.3,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withValues(
                              alpha: 0.2,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getFileIcon(fileType),
                              size: 20,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                fileName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                  color: colorScheme.onSurface,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Actions
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MediaPreviewScreen(
                                filePath: filePath,
                                fileName: fileName,
                                fileType: fileType,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.play_circle_outline_rounded,
                          size: 18,
                        ),
                        label: const Text('Ver'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () async {
                          try {
                            await Share.shareXFiles([
                              XFile(filePath),
                            ], text: shareMessage);
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                          } catch (e) {
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                            onError('No se pudo compartir el archivo');
                          }
                        },
                        icon: const Icon(Icons.share_rounded, size: 18),
                        label: const Text('Compartir'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildContentPreview(String filePath, String fileType) {
  if (fileType == 'video') {
    return VideoPreviewWidget(filePath: filePath);
  } else if (fileType == 'audio') {
    return AudioPreviewWidget(filePath: filePath);
  } else {
    return Image.file(
      File(filePath),
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: double.infinity,
          height: 200,
          color: Colors.grey[200],
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image, size: 64, color: Colors.grey),
              SizedBox(height: 8),
              Text('Imagen descargada'),
            ],
          ),
        );
      },
    );
  }
}

IconData _getFileIcon(String fileType) {
  switch (fileType) {
    case 'video':
      return Icons.video_library_rounded;
    case 'audio':
      return Icons.audio_file_rounded;
    case 'image':
      return Icons.image_rounded;
    default:
      return Icons.insert_drive_file_rounded;
  }
}
