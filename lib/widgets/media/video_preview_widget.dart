import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

/// Versatile video player widget used in two modes:
///
/// 1. **Preview mode** (inside result cards, `fullscreen: false`):
///    - Fixed height, rounded corners, manual controls overlay.
///    - Used for previewing a network video URL before downloading.
///
/// 2. **Fullscreen mode** (`fullscreen: true`):
///    - Fills the parent, no rounded corners, auto-hide controls (3-second timer),
///    - Fullscreen native toggle, landscape lock, centered AspectRatio.
///    - Used inside MediaPreviewScreen for locally downloaded files.
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
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _showControlsOverlay = true;
  Timer? _hideControlsTimer;
  bool _isFullscreenNative = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      if (widget.filePath != null) {
        _controller = VideoPlayerController.file(File(widget.filePath!));
      } else {
        _controller = VideoPlayerController.networkUrl(
          Uri.parse(widget.url!),
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
        );
      }

      _controller.setLooping(widget.loop);
      await _controller.initialize();

      if (!mounted) return;
      setState(() {
        _isInitialized = true;
        if (widget.autoPlay) {
          _controller.play();
          _scheduleHideControls();
        }
      });

      _controller.addListener(_controllerListener);
    } catch (e) {
      debugPrint('[VideoPreviewWidget] Init error: $e');
      if (mounted) setState(() => _hasError = true);
    }
  }

  void _controllerListener() {
    // When video ends, show controls again
    if (!_controller.value.isPlaying &&
        _controller.value.position == _controller.value.duration) {
      if (mounted) setState(() => _showControlsOverlay = true);
      _cancelHideTimer();
    }
  }

  @override
  void dispose() {
    _cancelHideTimer();
    _controller.removeListener(_controllerListener);
    _controller.dispose();
    if (_isFullscreenNative) {
      _exitNativeFullscreen();
    }
    super.dispose();
  }

  // ─── Controls visibility ─────────────────────────────────────────────────

  void _scheduleHideControls() {
    _cancelHideTimer();
    if (!widget.fullscreen) return; // Only auto-hide in fullscreen mode
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _controller.value.isPlaying) {
        setState(() => _showControlsOverlay = false);
      }
    });
  }

  void _cancelHideTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = null;
  }

  void _togglePlay() {
    if (_controller.value.isPlaying) {
      _controller.pause();
      _cancelHideTimer();
      setState(() => _showControlsOverlay = true);
    } else {
      _controller.play();
      _scheduleHideControls();
      if (!mounted) return;
      setState(() {});
    }
  }

  void _onTapVideo() {
    setState(() => _showControlsOverlay = !_showControlsOverlay);
    if (_showControlsOverlay && _controller.value.isPlaying) {
      _scheduleHideControls();
    } else {
      _cancelHideTimer();
    }
  }

  // ─── Native fullscreen ───────────────────────────────────────────────────

  void _toggleNativeFullscreen() {
    if (_isFullscreenNative) {
      _exitNativeFullscreen();
    } else {
      _enterNativeFullscreen();
    }
    setState(() => _isFullscreenNative = !_isFullscreenNative);
  }

  void _enterNativeFullscreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void _exitNativeFullscreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_hasError) return _buildErrorState(colorScheme);
    if (!_isInitialized) return _buildLoadingState();

    if (widget.fullscreen) {
      return _buildFullscreenPlayer(colorScheme);
    } else {
      return _buildPreviewPlayer(colorScheme);
    }
  }

  /// Preview mode: bounded height, rounded card.
  Widget _buildPreviewPlayer(ColorScheme colorScheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseDecoration = BoxDecoration(
      color: Colors.black,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(
        color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final aspectRatio = _controller.value.aspectRatio;
        final calculatedHeight = constraints.maxWidth / aspectRatio;
        const maxHeight = 500.0;
        final isTall = calculatedHeight > maxHeight;

        return Container(
          width: double.infinity,
          height: isTall ? maxHeight : null,
          clipBehavior: Clip.antiAlias,
          decoration: baseDecoration,
          child: _buildVideoStack(colorScheme, isFullscreen: false),
        );
      },
    );
  }

  /// Fullscreen mode: fills parent, no rounded corners, auto-hide controls.
  Widget _buildFullscreenPlayer(ColorScheme colorScheme) {
    return Material(
      color: Colors.black,
      child: _buildVideoStack(colorScheme, isFullscreen: true),
    );
  }

  Widget _buildVideoStack(
    ColorScheme colorScheme, {
    required bool isFullscreen,
  }) {
    return Stack(
      fit: StackFit.expand,
      alignment: Alignment.center,
      children: [
        // 1. Video centered with correct aspect ratio
        Center(
          child: AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
        ),

        // 2. Tap detector (whole surface)
        Positioned.fill(
          child: GestureDetector(
            onTap: _onTapVideo,
            behavior: HitTestBehavior.opaque,
            child: const ColoredBox(color: Colors.transparent),
          ),
        ),

        // 3. Controls overlay
        if (widget.showControls)
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: (_showControlsOverlay || !_controller.value.isPlaying)
                  ? 1.0
                  : 0.0,
              duration: const Duration(milliseconds: 250),
              child: IgnorePointer(
                // When invisible, don't intercept taps
                ignoring: !_showControlsOverlay && _controller.value.isPlaying,
                child: Stack(
                  children: [
                    Container(color: Colors.black.withValues(alpha: 0.25)),
                    Center(child: _buildCenterPlayButton(colorScheme)),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: _buildBottomControls(
                        colorScheme,
                        showFullscreenBtn: isFullscreen,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ─── Sub-widgets ─────────────────────────────────────────────────────────

  Widget _buildCenterPlayButton(ColorScheme colorScheme) {
    return GestureDetector(
      onTap: _togglePlay,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Icon(
              _controller.value.isPlaying
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              size: 42,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls(
    ColorScheme colorScheme, {
    required bool showFullscreenBtn,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withValues(alpha: 0.85), Colors.transparent],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar
          VideoProgressIndicator(
            _controller,
            allowScrubbing: true,
            padding: const EdgeInsets.symmetric(vertical: 6),
            colors: VideoProgressColors(
              playedColor: colorScheme.primary,
              bufferedColor: Colors.white.withValues(alpha: 0.3),
              backgroundColor: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          const SizedBox(height: 4),
          // Time + optional fullscreen button
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Current position
              ValueListenableBuilder(
                valueListenable: _controller,
                builder: (_, VideoPlayerValue v, _) {
                  return Text(_formatDuration(v.position), style: _timeStyle);
                },
              ),
              const SizedBox(width: 6),
              const Text(
                '/',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(width: 6),
              // Duration
              Text(
                _formatDuration(_controller.value.duration),
                style: _timeStyle.copyWith(
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              const Spacer(),
              // Fullscreen toggle (only in fullscreen mode)
              if (showFullscreenBtn)
                GestureDetector(
                  onTap: _toggleNativeFullscreen,
                  child: Icon(
                    _isFullscreenNative
                        ? Icons.fullscreen_exit_rounded
                        : Icons.fullscreen_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static const TextStyle _timeStyle = TextStyle(
    color: Colors.white,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    shadows: [
      Shadow(offset: Offset(0, 1), blurRadius: 2, color: Colors.black54),
    ],
  );

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

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final m = twoDigits(duration.inMinutes.remainder(60));
    final s = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return '${twoDigits(duration.inHours)}:$m:$s';
    }
    return '$m:$s';
  }
}
