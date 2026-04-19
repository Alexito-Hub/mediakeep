import 'dart:ui';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioPreviewWidget extends StatefulWidget {
  final String? filePath;
  final String? url;
  final Uint8List? bytes;
  final String? mimeType;
  final String? title;
  final String? artist;
  final String? albumCover;
  final Uint8List? albumCoverBytes;
  final bool isPreview;
  final bool allowNetworkSource;

  const AudioPreviewWidget({
    super.key,
    this.filePath,
    this.url,
    this.bytes,
    this.mimeType,
    this.title,
    this.artist,
    this.albumCover,
    this.albumCoverBytes,
    this.isPreview = false,
    this.allowNetworkSource = true,
  }) : assert(
         filePath != null || url != null || bytes != null,
         'Must provide either filePath, url or bytes',
       );

  @override
  State<AudioPreviewWidget> createState() => _AudioPreviewWidgetState();
}

class _AudioPreviewWidgetState extends State<AudioPreviewWidget> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _isBuffering = false;
  bool _sourcePrepared = false;
  String? _errorMessage;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  bool get _hasArtwork {
    if (widget.albumCoverBytes != null && widget.albumCoverBytes!.isNotEmpty) {
      return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.setReleaseMode(ReleaseMode.stop);

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          if (state == PlayerState.playing) {
            _isLoading = false;
            _isBuffering = false;
          }
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
          if (_isLoading && position > Duration.zero) {
            _isLoading = false;
            _isBuffering = false;
          }
        });
      }
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
          _isLoading = false;
          _isBuffering = false;
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
      if (!_sourcePrepared) {
        setState(() {
          _isLoading = true;
          _isBuffering = true;
          _errorMessage = null;
        });
        try {
          await _prepareSource();
          await _audioPlayer.resume();
          _sourcePrepared = true;
        } catch (e) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _isBuffering = false;
              _errorMessage = e.toString().replaceFirst('Exception: ', '');
            });
          }
          debugPrint('Error playing audio: $e');
        }
      } else {
        if (_position == Duration.zero) {
          await _audioPlayer.seek(Duration.zero);
        }
        await _audioPlayer.resume();
      }
    }
  }

  Future<void> _prepareSource() async {
    if (widget.bytes != null && widget.bytes!.isNotEmpty) {
      // Memory source enables local previews on web without filesystem access.
      await _audioPlayer.setSource(BytesSource(widget.bytes!));
      return;
    }

    if (widget.filePath != null && widget.filePath!.isNotEmpty) {
      await _audioPlayer.setSource(DeviceFileSource(widget.filePath!));
      return;
    }

    if (widget.url != null && widget.url!.isNotEmpty) {
      // Remote source support was removed to keep previews fully local.
      throw Exception(
        'La previsualización por URL remota fue eliminada. Selecciona un archivo local.',
      );
    }

    throw Exception('No hay una fuente de audio local válida.');
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
                if (_hasArtwork && !isMicro)
                  Positioned.fill(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.memory(
                          widget.albumCoverBytes!,
                          fit: BoxFit.cover,
                        ),
                        BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                          child: Container(
                            color: colorScheme.surface.withValues(alpha: 0.85),
                          ),
                        ),
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
                            if (_hasArtwork && maxHeight > 220) ...[
                              _buildAlbumCover(isCompact ? 100 : 160),
                              SizedBox(height: isCompact ? 16 : 24),
                            ],

                            _buildHeader(colorScheme, isCompact),
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: colorScheme.error,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ],
                            SizedBox(height: isCompact ? 12 : 24),

                            _buildProgressBar(colorScheme, isCompact),
                            SizedBox(height: isCompact ? 8 : 16),

                            _buildControls(colorScheme, isCompact),

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

  Widget _buildMicroLayout(ColorScheme colorScheme) {
    return Row(
      children: [
        if (_hasArtwork) ...[_buildAlbumCover(48), const SizedBox(width: 12)],
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
          icon: _isLoading || _isBuffering
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: colorScheme.primary,
                  ),
                )
              : Icon(
                  _isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                  size: 40,
                  color: colorScheme.primary,
                ),
        ),
      ],
    );
  }

  Widget _buildAlbumCover(double size) {
    return Hero(
      tag: widget.url ?? widget.filePath ?? widget.title ?? 'album_art',
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
          child: widget.albumCoverBytes != null
              ? Image.memory(widget.albumCoverBytes!, fit: BoxFit.cover)
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
        IconButton(
          onPressed: () => _seekRelative(-10),
          icon: const Icon(Icons.replay_10_rounded),
          color: colorScheme.onSurfaceVariant,
          iconSize: 26,
          tooltip: '-10s',
        ),

        const SizedBox(width: 16),

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
                child: _isLoading || _isBuffering
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
