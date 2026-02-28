import 'dart:ui'; // Necesario para ImageFilter
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioPreviewWidget extends StatefulWidget {
  final String? filePath;
  final String? url;
  final String? title;
  final String? artist;
  final String? albumCover;
  final bool isPreview;

  const AudioPreviewWidget({
    super.key,
    this.filePath,
    this.url,
    this.title,
    this.artist,
    this.albumCover,
    this.isPreview = false,
  }) : assert(
         filePath != null || url != null,
         'Must provide either filePath or url',
       );

  @override
  State<AudioPreviewWidget> createState() => _AudioPreviewWidgetState();
}

class _AudioPreviewWidgetState extends State<AudioPreviewWidget> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          _isLoading =
              state == PlayerState.playing && _position == Duration.zero;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
          _isLoading = false;
        });
      }
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      if (_position == Duration.zero) {
        setState(() => _isLoading = true);
        try {
          if (widget.filePath != null) {
            await _audioPlayer.play(DeviceFileSource(widget.filePath!));
          } else {
            await _audioPlayer.play(UrlSource(widget.url!));
          }
        } catch (e) {
          setState(() => _isLoading = false);
          // Manejo de error opcional aquí
        }
      } else {
        await _audioPlayer.resume();
      }
    }
  }

  Future<void> _seekTo(double value) async {
    final position = Duration(milliseconds: value.toInt());
    await _audioPlayer.seek(position);
  }

  Future<void> _seekRelative(int seconds) async {
    final newPosition = _position + Duration(seconds: seconds);
    if (newPosition < Duration.zero) {
      await _audioPlayer.seek(Duration.zero);
    } else if (newPosition > _duration) {
      await _audioPlayer.seek(_duration);
    } else {
      await _audioPlayer.seek(newPosition);
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxHeight = constraints.maxHeight;
        // Si es muy pequeño, usa un layout horizontal (tipo lista)
        final bool isMicro = maxHeight < 120;
        final bool isCompact = maxHeight < 350;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
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
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                // 1. Capa de Fondo (Imagen borrosa o color sólido)
                if (widget.albumCover != null && !isMicro)
                  Positioned.fill(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          widget.albumCover!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const SizedBox(),
                        ),
                        // Blur effect (Glassmorphism)
                        BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                          child: Container(
                            color: colorScheme.surface.withValues(alpha: 0.85),
                          ),
                        ),
                        // Gradient overlay para legibilidad
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                colorScheme.surface.withValues(alpha: 0.3),
                                colorScheme.surface,
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // 2. Contenido Principal
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: isMicro ? 12 : 20,
                  ),
                  child: isMicro
                      ? _buildMicroLayout(colorScheme)
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Album Art
                            if (widget.albumCover != null &&
                                maxHeight > 220) ...[
                              _buildAlbumCover(isCompact ? 100 : 160),
                              SizedBox(height: isCompact ? 16 : 24),
                            ],

                            // Info
                            _buildHeader(colorScheme, isCompact),
                            SizedBox(height: isCompact ? 12 : 24),

                            // Slider & Times
                            _buildProgressBar(colorScheme, isCompact),
                            SizedBox(height: isCompact ? 8 : 16),

                            // Controls
                            _buildControls(colorScheme, isCompact),

                            // Badge
                            if (widget.isPreview && !isCompact) ...[
                              const Spacer(),
                              _buildPreviewBadge(colorScheme),
                            ],
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

  // Layout para cuando el widget es muy bajito (estilo fila)
  Widget _buildMicroLayout(ColorScheme colorScheme) {
    return Row(
      children: [
        if (widget.albumCover != null) ...[
          _buildAlbumCover(48),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.title ?? 'Sin título',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                widget.artist ?? 'Desconocido',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _togglePlayPause,
          icon: Icon(
            _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
            size: 40,
            color: colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildAlbumCover(double size) {
    return Hero(
      tag: widget.url ?? widget.filePath ?? 'album_art',
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: widget.albumCover != null
              ? Image.network(
                  widget.albumCover!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildPlaceholder(size),
                )
              : _buildPlaceholder(size),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(double size) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.music_note_rounded,
        size: size * 0.4,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme, bool isCompact) {
    return Column(
      children: [
        Text(
          widget.title ?? 'Audio de Media Keep',
          style:
              (isCompact
                      ? Theme.of(context).textTheme.titleLarge
                      : Theme.of(context).textTheme.headlineSmall)
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          widget.artist ?? 'Media Keep Downloader',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildProgressBar(ColorScheme colorScheme, bool isCompact) {
    return Column(
      children: [
        SizedBox(
          height: 20,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              trackShape: const RoundedRectSliderTrackShape(),
              activeTrackColor: colorScheme.primary,
              inactiveTrackColor: colorScheme.outlineVariant.withValues(
                alpha: 0.4,
              ),
              thumbColor: colorScheme.primary,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 6,
                pressedElevation: 4,
              ),
              overlayColor: colorScheme.primary.withValues(alpha: 0.1),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(
              value: _position.inMilliseconds.toDouble(),
              min: 0,
              max: _duration.inMilliseconds.toDouble() > 0
                  ? _duration.inMilliseconds.toDouble()
                  : 1,
              onChanged: _seekTo,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(_position),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontFeatures: [const FontFeature.tabularFigures()],
                ),
              ),
              Text(
                _formatDuration(_duration),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontFeatures: [const FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControls(ColorScheme colorScheme, bool isCompact) {
    final double playSize = isCompact ? 56 : 64;
    final double iconSize = isCompact ? 28 : 32;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Replay 10s
        IconButton(
          onPressed: () => _seekRelative(-10),
          icon: const Icon(Icons.replay_10_rounded),
          color: colorScheme.onSurfaceVariant,
          iconSize: 26,
          tooltip: '-10s',
        ),

        const SizedBox(width: 16),

        // Play/Pause Button
        Container(
          width: playSize,
          height: playSize,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _togglePlayPause,
              borderRadius: BorderRadius.circular(50),
              child: Center(
                child: _isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: colorScheme.onPrimary,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Icon(
                        _isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: iconSize,
                        color: colorScheme.onPrimary,
                      ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 16),

        // Forward 10s
        IconButton(
          onPressed: () => _seekRelative(10),
          icon: const Icon(Icons.forward_10_rounded),
          color: colorScheme.onSurfaceVariant,
          iconSize: 26,
          tooltip: '+10s',
        ),
      ],
    );
  }

  Widget _buildPreviewBadge(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.secondary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 14,
            color: colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 6),
          Text(
            'Previsualización',
            style: TextStyle(
              color: colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
