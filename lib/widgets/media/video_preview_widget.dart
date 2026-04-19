import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flick_video_player/flick_video_player.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

class VideoPreviewWidget extends StatefulWidget {
  final String? filePath;
  final String? url;
  final Uint8List? bytes;
  final String? mimeType;
  final bool autoPlay;
  final bool showControls;
  final bool fullscreen;
  final bool loop;
  final bool allowNetworkSource;

  const VideoPreviewWidget({
    super.key,
    this.filePath,
    this.url,
    this.bytes,
    this.mimeType,
    this.autoPlay = false,
    this.showControls = true,
    this.fullscreen = false,
    this.loop = false,
    this.allowNetworkSource = true,
  }) : assert(
         filePath != null || url != null || bytes != null,
         'Must provide either filePath, url or bytes',
       );

  @override
  State<VideoPreviewWidget> createState() => _VideoPreviewWidgetState();
}

class _VideoPreviewWidgetState extends State<VideoPreviewWidget> {
  static const Set<String> _commonVideoExtensions = {
    'mp4',
    'mov',
    'm4v',
    'webm',
    'mkv',
    'avi',
  };

  late FlickManager flickManager;
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;
  File? _tempFile;
  double _aspectRatio = 16 / 9;
  String _loadingMessage = 'Cargando video...';

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer({bool forceAndroidTempCopy = false}) async {
    VideoPlayerController? controller;

    try {
      if (mounted) {
        setState(() {
          _hasError = false;
          _errorMessage = null;
          _loadingMessage = 'Preparando video...';
        });
      }

      if (_isLikelyUnsupportedVideo()) {
        throw Exception(
          'Formato de video no soportado en este modo BETA. Usa MP4, MOV o WEBM.',
        );
      }

      controller = await _buildController(
        forceAndroidTempCopy: forceAndroidTempCopy,
      );

      try {
        await controller.initialize();
        debugPrint(
          '[VideoPreviewWidget] initialize OK - aspectRatio=${controller.value.aspectRatio} filePath=${widget.filePath}',
        );
      } catch (error) {
        final initError = _resolveInitializeError(controller, error);
        debugPrint(
          '[VideoPreviewWidget] initialize FAILED - error=$initError filePath=${widget.filePath} forceAndroidTempCopy=$forceAndroidTempCopy',
        );

        await controller.dispose();

        if (!forceAndroidTempCopy &&
            widget.filePath != null &&
            Platform.isAndroid &&
            _shouldRetryWithTempCopy(error)) {
          debugPrint(
            '[VideoPreviewWidget] Retrying initialize with Android temp copy',
          );
          return _initializePlayer(forceAndroidTempCopy: true);
        }

        throw Exception(initError);
      }

      final resolvedController = controller;

      flickManager = FlickManager(
        videoPlayerController: resolvedController,
        autoPlay: widget.autoPlay,
      );

      await resolvedController.setLooping(widget.loop);

      // Escuchar errores de inicialización
      resolvedController.addListener(() {
        if (resolvedController.value.hasError && mounted) {
          setState(() {
            _hasError = true;
            _errorMessage =
                resolvedController.value.errorDescription ??
                'No se pudo cargar el video.';
          });
        }
      });

      if (mounted) {
        setState(() {
          _aspectRatio = _sanitizeAspectRatio(
            resolvedController.value.aspectRatio,
          );
          _isInitialized = true;
          _hasError = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      debugPrint('[VideoPreviewWidget] Init error: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<VideoPlayerController> _buildController({
    bool forceAndroidTempCopy = false,
  }) async {
    if (widget.bytes != null && widget.bytes!.isNotEmpty) {
      // video_player is more stable with file-backed sources on desktop/mobile.
      final tempDir = await getTemporaryDirectory();
      final extension = _resolveExtension();
      final tempPath =
          '${tempDir.path}/temp_video_${DateTime.now().millisecondsSinceEpoch}.$extension';
      _tempFile = await File(tempPath).writeAsBytes(widget.bytes!, flush: true);

      final size = await _tempFile!.length();
      debugPrint(
        '[VideoPreviewWidget] bytes source written at=$tempPath size=$size',
      );

      if (size <= 0) {
        throw Exception(
          'No se pudo preparar el video temporal (archivo vacio).',
        );
      }

      return VideoPlayerController.file(_tempFile!);
    }

    if (widget.filePath != null) {
      return _buildControllerFromFilePath(
        widget.filePath!,
        forceAndroidTempCopy: forceAndroidTempCopy,
      );
    }

    if (widget.url != null && widget.url!.isNotEmpty) {
      // Remote source support was removed to keep previews fully local.
      throw Exception(
        'La previsualización por URL remota fue eliminada. Selecciona un archivo local.',
      );
    }

    throw Exception('No se recibió una fuente de video local válida.');
  }

  Future<VideoPlayerController> _buildControllerFromFilePath(
    String filePath, {
    bool forceAndroidTempCopy = false,
  }) async {
    final readyFile = await _waitForReadyFile(filePath);
    final size = await readyFile.length();
    debugPrint(
      '[VideoPreviewWidget] ready file path=${readyFile.path} size=$size forceAndroidTempCopy=$forceAndroidTempCopy',
    );

    if (size <= 0) {
      throw Exception('El archivo de video esta vacio o incompleto.');
    }

    if (forceAndroidTempCopy && Platform.isAndroid) {
      _tempFile = await _copyToTempFile(readyFile);
      return VideoPlayerController.file(_tempFile!);
    }

    return VideoPlayerController.file(readyFile);
  }

  Future<File> _copyToTempFile(File originalFile) async {
    final tempDir = await getTemporaryDirectory();
    final extension = _resolveExtension();
    final tempPath =
        '${tempDir.path}/temp_video_${DateTime.now().millisecondsSinceEpoch}.$extension';
    final copied = await originalFile.copy(tempPath);
    final copiedSize = await copied.length();

    debugPrint(
      '[VideoPreviewWidget] copied to temp path=$tempPath size=$copiedSize from=${originalFile.path}',
    );

    if (copiedSize <= 0) {
      throw Exception(
        'No se pudo preparar una copia temporal valida del video.',
      );
    }

    return copied;
  }

  Future<File?> _resolveExistingVideoFile(String filePath) async {
    final direct = File(filePath);
    if (await direct.exists()) return direct;

    if (!Platform.isAndroid) return null;

    final normalized = filePath.replaceAll('\\', '/');
    final fileName = normalized.split('/').last;

    final fallbackPaths = [
      '/storage/emulated/0/Download/$fileName',
      '/storage/emulated/0/Download/MediaKeep/$fileName',
      '/storage/emulated/0/Download/MediaKeep/video/$fileName',
    ];

    for (final fallback in fallbackPaths) {
      final fallbackFile = File(fallback);
      if (await fallbackFile.exists()) {
        return fallbackFile;
      }
    }

    return null;
  }

  Future<File> _waitForReadyFile(String filePath) async {
    final completer = Completer<File>();
    Timer? timer;
    int elapsedSeconds = 0;
    bool checking = false;

    Future<void> checkFile() async {
      if (checking || completer.isCompleted) return;
      checking = true;

      try {
        final resolvedFile = await _resolveExistingVideoFile(filePath);
        final size = resolvedFile == null ? 0 : await resolvedFile.length();
        final exists = resolvedFile != null;

        debugPrint(
          '[VideoPreviewWidget] wait check elapsed=${elapsedSeconds}s path=${resolvedFile?.path ?? filePath} exists=$exists size=$size',
        );

        if (exists && size > 0) {
          timer?.cancel();
          if (!completer.isCompleted) {
            completer.complete(resolvedFile);
          }
          return;
        }

        if (elapsedSeconds >= 30) {
          timer?.cancel();
          if (!completer.isCompleted) {
            completer.completeError(
              Exception(
                'El archivo de video no estuvo listo a tiempo (30s). Intenta nuevamente.',
              ),
            );
          }
          return;
        }

        elapsedSeconds += 1;
        if (mounted) {
          setState(() {
            _loadingMessage =
                'Esperando archivo de video... $elapsedSeconds/30s';
          });
        }
      } finally {
        checking = false;
      }
    }

    await checkFile();

    if (!completer.isCompleted) {
      timer = Timer.periodic(const Duration(seconds: 1), (_) {
        unawaited(checkFile());
      });
    }

    return completer.future;
  }

  String _resolveInitializeError(
    VideoPlayerController controller,
    Object error,
  ) {
    final controllerError = controller.value.errorDescription;
    if (controllerError != null && controllerError.trim().isNotEmpty) {
      return controllerError.trim();
    }

    return error.toString().replaceFirst('Exception: ', '').trim();
  }

  bool _shouldRetryWithTempCopy(Object error) {
    final raw = error.toString().toLowerCase();
    return raw.contains('permission') ||
        raw.contains('denied') ||
        raw.contains('eacces') ||
        raw.contains('storage/emulated/0') ||
        raw.contains('source error') ||
        raw.contains('file is corrupted');
  }

  double _sanitizeAspectRatio(double ratio) {
    if (ratio.isFinite && ratio > 0) return ratio;
    return 16 / 9;
  }

  bool _isLikelyUnsupportedVideo() {
    final mimeType = widget.mimeType?.toLowerCase();
    if (mimeType != null &&
        mimeType.isNotEmpty &&
        !mimeType.startsWith('video/')) {
      return true;
    }

    final extension = _extractExtension(widget.filePath ?? widget.url);
    if (extension == null || extension.isEmpty) return false;
    return !_commonVideoExtensions.contains(extension);
  }

  String _resolveExtension() {
    final fromPath = _extractExtension(widget.filePath ?? widget.url);
    if (fromPath != null && fromPath.isNotEmpty) {
      return fromPath;
    }

    final fromMime = widget.mimeType?.split('/').last.toLowerCase();
    if (fromMime != null && fromMime.isNotEmpty) {
      return fromMime;
    }

    return 'mp4';
  }

  String? _extractExtension(String? source) {
    if (source == null || source.isEmpty) return null;
    final clean = source.split('?').first;
    final dotIndex = clean.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == clean.length - 1) return null;
    return clean.substring(dotIndex + 1).toLowerCase();
  }

  @override
  void dispose() {
    if (_isInitialized) {
      flickManager.dispose();
    }

    if (_tempFile != null) {
      try {
        if (_tempFile!.existsSync()) {
          _tempFile!.deleteSync();
        }
      } catch (_) {
        // Non-fatal cleanup error.
      }
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_hasError) return _buildErrorState(colorScheme);
    if (!_isInitialized) return _buildLoadingState();

    return Container(
      width: double.infinity,
      height: widget.fullscreen ? double.infinity : null,
      constraints: widget.fullscreen
          ? null
          : const BoxConstraints(maxHeight: 500),
      color: Colors.black,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.fullscreen ? 0 : 20),
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              final maxHeight = constraints.maxHeight.isFinite
                  ? constraints.maxHeight
                  : (widget.fullscreen
                        ? MediaQuery.of(context).size.height
                        : 500.0);

              final ratio = _sanitizeAspectRatio(_aspectRatio);
              double targetWidth = maxWidth;
              double targetHeight = targetWidth / ratio;

              if (targetHeight > maxHeight) {
                targetHeight = maxHeight;
                targetWidth = targetHeight * ratio;
              }

              return SizedBox(
                width: targetWidth,
                height: targetHeight,
                child: FlickVideoPlayer(
                  flickManager: flickManager,
                  flickVideoWithControls: const FlickVideoWithControls(
                    controls: FlickPortraitControls(),
                  ),
                  flickVideoWithControlsFullscreen:
                      const FlickVideoWithControls(
                        controls: FlickLandscapeControls(),
                      ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      width: double.infinity,
      height: widget.fullscreen ? double.infinity : 220,
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2.5,
            ),
            const SizedBox(height: 16),
            Text(
              _loadingMessage,
              style: const TextStyle(color: Colors.white60, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      height: widget.fullscreen ? double.infinity : 220,
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.videocam_off_rounded,
              size: 56,
              color: Colors.white30,
            ),
            const SizedBox(height: 16),
            const Text(
              'No se pudo reproducir el video',
              style: TextStyle(color: Colors.white60, fontSize: 15),
            ),
            if (_errorMessage != null && _errorMessage!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
            ],
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _isInitialized = false;
                  _errorMessage = null;
                });
                _initializePlayer();
              },
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              label: const Text(
                'Reintentar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
