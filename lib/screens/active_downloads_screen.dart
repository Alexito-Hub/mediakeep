import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../utils/responsive.dart';
import '../utils/app_routes.dart';
import '../widgets/layout/responsive_shell_scaffold.dart';
import 'media_preview_screen.dart';

/// Displays all active and recently completed background downloads.
/// Backed by FlutterDownloader's task state on native platforms.
class ActiveDownloadsScreen extends StatefulWidget {
  const ActiveDownloadsScreen({super.key});

  @override
  State<ActiveDownloadsScreen> createState() => _ActiveDownloadsScreenState();
}

class _ActiveDownloadsScreenState extends State<ActiveDownloadsScreen> {
  List<DownloadTask> _tasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    if (kIsWeb) return; // FlutterDownloader is not available on web
    final tasks = await FlutterDownloader.loadTasks();
    if (mounted) {
      setState(() => _tasks = tasks ?? []);
    }
  }

  Future<void> _cancelTask(String taskId) async {
    await FlutterDownloader.cancel(taskId: taskId);
    _loadTasks();
  }

  Future<void> _retryTask(String taskId) async {
    final newTaskId = await FlutterDownloader.retry(taskId: taskId);
    if (newTaskId != null) _loadTasks();
  }

  Future<void> _openFile(String? savedDir, String? filename) async {
    if (savedDir == null || filename == null) return;
    final filePath = '$savedDir/$filename';

    // Validate existence before opening. Include Android 11+ fallback paths due to publicStorage shifting.
    File file = File(filePath);
    bool exists = file.existsSync();

    if (!exists && Platform.isAndroid) {
      final fallbackPaths = [
        '/storage/emulated/0/Download/$filename',
        '/storage/emulated/0/Download/MediaKeep/$filename',
        '/storage/emulated/0/Download/MediaKeep/video/$filename',
        '/storage/emulated/0/Download/MediaKeep/audio/$filename',
        '/storage/emulated/0/Download/MediaKeep/imagen/$filename',
      ];
      for (final fallback in fallbackPaths) {
        if (File(fallback).existsSync()) {
          file = File(fallback);
          exists = true;
          break;
        }
      }
    }

    if (!exists) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El archivo ya no existe o fue movido.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    // Derive fileType from extension
    final ext = filename.split('.').last.toLowerCase();
    final fileType = (ext == 'mp4' || ext == 'mkv' || ext == 'mov')
        ? 'video'
        : (ext == 'mp3' || ext == 'm4a' || ext == 'aac')
        ? 'audio'
        : 'image';
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MediaPreviewScreen(
            filePath: filePath,
            fileName: filename,
            fileType: fileType,
          ),
        ),
      );
    }
  }

  String _statusLabel(DownloadTaskStatus status, int progress) {
    if (status == DownloadTaskStatus.running) return 'Descargando $progress%';
    if (status == DownloadTaskStatus.complete) return 'Completado';
    if (status == DownloadTaskStatus.failed) return 'Error';
    if (status == DownloadTaskStatus.paused) return 'Pausado';
    if (status == DownloadTaskStatus.canceled) return 'Cancelado';
    if (status == DownloadTaskStatus.enqueued) return 'En cola';
    return 'Desconocido';
  }

  Color _statusColor(DownloadTaskStatus status, BuildContext context) {
    if (status == DownloadTaskStatus.complete) return Colors.green;
    if (status == DownloadTaskStatus.failed) {
      return Theme.of(context).colorScheme.error;
    }
    if (status == DownloadTaskStatus.paused) return Colors.orange;
    if (status == DownloadTaskStatus.running) {
      return Theme.of(context).colorScheme.primary;
    }
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveShellScaffold(
      title: 'Descargas Activas',
      currentRoute: AppRoutes.activeDownloads,
      extendBodyBehindAppBar: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Actualizar',
          onPressed: _loadTasks,
        ),
      ],
      body: SafeArea(
        child: kIsWeb
            ? const Center(
                child: Text(
                  'Las descargas en segundo plano no están disponibles en la versión web.',
                  textAlign: TextAlign.center,
                ),
              )
            : _tasks.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_done_outlined,
                      size: 80,
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No hay descargas activas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Las descargas iniciadas aparecerán aquí',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: Responsive.getContentPadding(context),
                itemCount: _tasks.length,
                itemBuilder: (context, index) {
                  final task = _tasks[index];
                  final isRunning = task.status == DownloadTaskStatus.running;
                  final isComplete = task.status == DownloadTaskStatus.complete;
                  final isFailed = task.status == DownloadTaskStatus.failed;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isComplete
                                    ? Icons.check_circle_rounded
                                    : isFailed
                                    ? Icons.error_rounded
                                    : Icons.downloading_rounded,
                                color: _statusColor(task.status, context),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  task.filename ?? 'Archivo descargando...',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (isRunning) ...[
                            LinearProgressIndicator(
                              value: task.progress / 100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            const SizedBox(height: 4),
                          ],
                          Row(
                            children: [
                              Text(
                                _statusLabel(task.status, task.progress),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _statusColor(task.status, context),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              if (isComplete)
                                TextButton.icon(
                                  icon: const Icon(
                                    Icons.open_in_new_rounded,
                                    size: 16,
                                  ),
                                  label: const Text('Ver'),
                                  onPressed: () =>
                                      _openFile(task.savedDir, task.filename),
                                ),
                              if (isFailed)
                                TextButton.icon(
                                  icon: const Icon(
                                    Icons.refresh_rounded,
                                    size: 16,
                                  ),
                                  label: const Text('Reintentar'),
                                  onPressed: () => _retryTask(task.taskId),
                                ),
                              if (!isComplete)
                                IconButton(
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 20,
                                  ),
                                  tooltip: 'Cancelar',
                                  onPressed: () => _cancelTask(task.taskId),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
