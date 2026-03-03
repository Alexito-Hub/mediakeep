import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:flick_video_player/flick_video_player.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class VideoPreviewWidget extends StatefulWidget {
  final String? filePath;
  final String? url;
  final bool autoPlay;
  final bool showControls;
  final bool fullscreen;
  final bool loop;

  const VideoPreviewWidget({
    super.key,
    this.filePath,
    this.url,
    this.autoPlay = false,
    this.showControls = true,
    this.fullscreen = false,
    this.loop = false,
  }) : assert(
         filePath != null || url != null,
         'Must provide either filePath or url',
       );

  @override
  State<VideoPreviewWidget> createState() => _VideoPreviewWidgetState();
}

class _VideoPreviewWidgetState extends State<VideoPreviewWidget> {
  late FlickManager flickManager;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      VideoPlayerController controller;
      if (widget.filePath != null) {
        controller = VideoPlayerController.file(File(widget.filePath!));
      } else {
        // Optimización: Intentar obtener del cache si es posible
        final fileInfo = await DefaultCacheManager().getFileFromCache(widget.url!);
        if (fileInfo != null) {
          controller = VideoPlayerController.file(fileInfo.file);
        } else {
          controller = VideoPlayerController.networkUrl(
            Uri.parse(widget.url!),
            videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
          );
          // Opcional: Podrías descargar en background el video para cachearlo
          // DefaultCacheManager().downloadFile(widget.url!);
        }
      }

      flickManager = FlickManager(
        videoPlayerController: controller,
        autoPlay: widget.autoPlay,
      );

      controller.setLooping(widget.loop);
      
      // Escuchar errores de inicialización
      controller.addListener(() {
        if (controller.value.hasError && mounted) {
          setState(() => _hasError = true);
        }
      });

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('[VideoPreviewWidget] Init error: $e');
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    if (_isInitialized) {
      flickManager.dispose();
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
      constraints: widget.fullscreen ? null : const BoxConstraints(maxHeight: 500),
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
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _isInitialized = false;
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
