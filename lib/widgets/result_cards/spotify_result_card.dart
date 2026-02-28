import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../models/spotify_model.dart';
import '../common/download_action_button_widget.dart';

/// Result card widget for Spotify tracks
class SpotifyResultCard extends StatefulWidget {
  final SpotifyData data;
  final Function(String url, String type) onDownload;

  const SpotifyResultCard({
    super.key,
    required this.data,
    required this.onDownload,
  });

  @override
  State<SpotifyResultCard> createState() => _SpotifyResultCardState();
}

class _SpotifyResultCardState extends State<SpotifyResultCard> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (widget.data.thumbnail.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        _buildNetworkImage(
                          widget.data.thumbnail,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                height: 200,
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                                child: const Icon(Icons.music_note, size: 80),
                              ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  widget.data.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.data.artistNames,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 20,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        Text(
                          widget.data.durationFormatted,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Icon(
                          Icons.favorite,
                          size: 20,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        Text(
                          widget.data.popularity,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 20,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        Text(
                          widget.data.date,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'Opciones de Descarga',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: DownloadActionButton(
            label: 'Descargar\nMP3',
            icon: Icons.audiotrack,
            color: Theme.of(context).colorScheme.primary,
            onTap: () => widget.onDownload(widget.data.download, 'audio'),
          ),
        ),
      ],
    );
  }

  Widget _buildNetworkImage(
    String url, {
    double? width,
    double? height,
    BoxFit? fit,
    Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
  }) {
    final imageUrl = kIsWeb
        ? 'https://corsproxy.io/?${Uri.encodeComponent(url)}'
        : url;

    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: errorBuilder,
    );
  }
}
