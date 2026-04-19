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

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      if (_isLikelyUnsupportedVideo()) {
        throw Exception(
          'Formato de video no soportado en este modo BETA. Usa MP4, MOV o WEBM.',
        );
      }

      final controller = await _buildController();
      await controller.initialize();

      flickManager = FlickManager(
        videoPlayerController: controller,
        autoPlay: widget.autoPlay,
      );

      await controller.setLooping(widget.loop);

      // Escuchar errores de inicialización
      controller.addListener(() {
        if (controller.value.hasError && mounted) {
          setState(() {
            _hasError = true;
            _errorMessage =
                controller.value.errorDescription ??
                'No se pudo cargar el video.';
          });
        }
      });

      if (mounted) {
        setState(() {
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

  Future<VideoPlayerController> _buildController() async {
    if (widget.bytes != null && widget.bytes!.isNotEmpty) {
      // video_player is more stable with file-backed sources on desktop/mobile.
      final tempDir = await getTemporaryDirectory();
      final extension = _resolveExtension();
      final tempPath =
          '${tempDir.path}/temp_video_${DateTime.now().millisecondsSinceEpoch}.$extension';
      _tempFile = await File(tempPath).writeAsBytes(widget.bytes!, flush: true);
      return VideoPlayerController.file(_tempFile!);
    }

    if (widget.filePath != null) {
      return _buildControllerFromFilePath(widget.filePath!);
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
    String filePath,
  ) async {
    // Android 11+: ExoPlayer may fail reading some public paths directly.
    File originalFile = File(filePath);
    bool exists = originalFile.existsSync();

    if (!exists && Platform.isAndroid) {
      final fileName = filePath.split('/').last;
      final fallbackPaths = [
        '/storage/emulated/0/Download/$fileName',
        '/storage/emulated/0/Download/MediaKeep/$fileName',
        '/storage/emulated/0/Download/MediaKeep/video/$fileName',
      ];
      for (final fallback in fallbackPaths) {
        if (File(fallback).existsSync()) {
          originalFile = File(fallback);
          exists = true;
          break;
        }
      }
    }

    if (!exists) {
      throw Exception('El archivo de video no existe en el dispositivo.');
    }

    final tempDir = await getTemporaryDirectory();
    final extension = _resolveExtension();
    final tempPath =
        '${tempDir.path}/temp_video_${DateTime.now().millisecondsSinceEpoch}.$extension';
    _tempFile = await originalFile.copy(tempPath);
    return VideoPlayerController.file(_tempFile!);
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.fullscreen ? 0 : 28),
        child: FlickVideoPlayer(
          flickManager: flickManager,
          flickVideoWithControls: const FlickVideoWithControls(
            controls: FlickPortraitControls(),
          ),
          flickVideoWithControlsFullscreen: const FlickVideoWithControls(
            controls: FlickLandscapeControls(),
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
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
            SizedBox(height: 16),
            Text(
              'Cargando video...',
              style: TextStyle(color: Colors.white60, fontSize: 14),
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
