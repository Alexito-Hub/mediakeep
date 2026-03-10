import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/media/video_preview_widget.dart';
import '../widgets/media/audio_preview_widget.dart';

/// Full-screen viewer for downloaded media (video, audio, image).
///
/// Video: black screen with overlay controls, fullscreen toggle, auto-hide.
/// Image: InteractiveViewer with double-tap zoom cycle (1× → 3× → 1×).
/// Audio: Dark glassmorphic player card centered in screen.
class MediaPreviewScreen extends StatefulWidget {
  final String filePath;
  final String fileName;
  final String fileType;
  final String? platform;
  final String? thumbnail;

  const MediaPreviewScreen({
    super.key,
    required this.filePath,
    required this.fileName,
    required this.fileType,
    this.platform,
    this.thumbnail,
  });

  @override
  State<MediaPreviewScreen> createState() => _MediaPreviewScreenState();
}

class _MediaPreviewScreenState extends State<MediaPreviewScreen>
    with SingleTickerProviderStateMixin {
  // Image zoom state
  final TransformationController _transformController =
      TransformationController();
  TapDownDetails? _doubleTapDetails;
  bool _isZoomed = false;
  bool _isFileReady = false;

  @override
  void initState() {
    super.initState();
    // Remove status bar for immersive experience on video/image
    if (widget.fileType == 'video' || widget.fileType == 'image') {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
    _waitForFile();
  }

  Future<void> _waitForFile() async {
    final file = File(widget.filePath);
    int attempts = 0;
    while (!file.existsSync() && attempts < 10) {
      await Future.delayed(const Duration(milliseconds: 500));
      attempts++;
    }
    if (mounted) {
      setState(() {
        _isFileReady = file.existsSync();
      });
    }
  }

  @override
  void dispose() {
    // Restore system UI on exit
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _transformController.dispose();
    super.dispose();
  }

  void _onDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _onDoubleTap() {
    if (_isZoomed) {
      // Zoom out to 1×
      _transformController.value = Matrix4.identity();
      setState(() => _isZoomed = false);
    } else {
      // Zoom in to 3× centered on tap point
      final position = _doubleTapDetails!.localPosition;
      const scale = 3.0;
      final x = -position.dx * (scale - 1);
      final y = -position.dy * (scale - 1);
      final zoomed = Matrix4.identity()
        ..setEntry(0, 0, scale)
        ..setEntry(1, 1, scale)
        ..setEntry(0, 3, x)
        ..setEntry(1, 3, y);
      _transformController.value = zoomed;
      setState(() => _isZoomed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = widget.fileType == 'video';
    final isImage = widget.fileType == 'image';
    final isAudio = widget.fileType == 'audio';

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: _buildAppBar(context, isVideo || isImage),
      body: _buildBody(context, isVideo, isImage, isAudio),
      // Show share bar only for audio/unknown — video/image have in-overlay sharing
      bottomNavigationBar: isVideo || isImage ? null : _buildShareBar(),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool transparent) {
    return AppBar(
      backgroundColor: transparent
          ? Colors.black.withValues(alpha: 0.3)
          : Colors.black,
      elevation: 0,
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        widget.fileName,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share_rounded, color: Colors.white),
          onPressed: () => Share.shareXFiles([XFile(widget.filePath)]),
          tooltip: 'Compartir',
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    bool isVideo,
    bool isImage,
    bool isAudio,
  ) {
    if (!_isFileReady) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 16),
            Text(
              'Preparando archivo...',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
          ],
        ),
      );
    }

    if (isVideo) return _buildVideoView();
    if (isImage) return _buildImageView();
    if (isAudio) return _buildAudioView(context);
    return const _UnsupportedTypeView();
  }

  // ── VIDEO ────────────────────────────────────────────────────────────────

  Widget _buildVideoView() {
    return SizedBox.expand(
      child: VideoPreviewWidget(
        filePath: widget.filePath,
        autoPlay: true,
        showControls: true,
        fullscreen: true,
      ),
    );
  }

  // ── IMAGE ────────────────────────────────────────────────────────────────

  Widget _buildImageView() {
    return GestureDetector(
      onDoubleTapDown: _onDoubleTapDown,
      onDoubleTap: _onDoubleTap,
      child: InteractiveViewer(
        transformationController: _transformController,
        minScale: 1.0,
        maxScale: 6.0,
        boundaryMargin: const EdgeInsets.all(40),
        onInteractionEnd: (details) {
          // Track zoom state based on transformation
          final scale = _transformController.value.getMaxScaleOnAxis();
          if (scale <= 1.01) setState(() => _isZoomed = false);
        },
        child: Center(
          child: Hero(
            tag: widget.filePath,
            child: Image.file(
              File(widget.filePath),
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Icon(
                  Icons.broken_image_rounded,
                  size: 100,
                  color: Colors.white30,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── AUDIO ────────────────────────────────────────────────────────────────

  Widget _buildAudioView(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              height: 400,
              child: AudioPreviewWidget(
                filePath: widget.filePath,
                title: widget.fileName,
                artist: widget.platform ?? 'Media Keep',
                albumCover: widget.thumbnail,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── BOTTOM BAR ───────────────────────────────────────────────────────────

  Widget _buildShareBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton.icon(
              onPressed: () => Share.shareXFiles([XFile(widget.filePath)]),
              icon: const Icon(Icons.share_rounded),
              label: const Text('Compartir Archivo'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.12),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── WIDGET para extensiones no reconocidas ────────────────────────────────

class _UnsupportedTypeView extends StatelessWidget {
  const _UnsupportedTypeView();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insert_drive_file_rounded,
            size: 80,
            color: Colors.white24,
          ),
          SizedBox(height: 16),
          Text(
            'Vista previa no disponible\npara este tipo de archivo',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
