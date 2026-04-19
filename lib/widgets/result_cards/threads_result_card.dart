import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/threads_model.dart';
import '../../utils/formatters.dart';
import '../common/app_network_image.dart';
import '../common/download_action_button_widget.dart';

/// Result card widget for Threads posts
class ThreadsResultCard extends StatelessWidget {
  final ThreadsData data;
  final Function(String url, String type) onDownload;

  const ThreadsResultCard({
    super.key,
    required this.data,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (data.author.profilePicUrl.isNotEmpty)
                      CircleAvatar(
                        backgroundImage: CachedNetworkImageProvider(
                          data.author.profilePicUrl,
                        ),
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '@${data.author.username}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              if (data.author.isVerified) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.verified,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(data.title, style: const TextStyle(fontSize: 14)),
                if (!data.hasMultipleMedia && data.media.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        _buildNetworkImage(
                          data.media[0].url,
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: 150,
                        ),
                        if (data.media[0].type == 'video')
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(100),
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _stat(context, Icons.favorite, data.likes),
                    _stat(context, Icons.repeat, data.repost),
                    _stat(context, Icons.share, data.reshare),
                    _stat(context, Icons.comment, data.comments),
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
        if (data.hasMultipleMedia)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: data.media.length,
            itemBuilder: (context, index) {
              final media = data.media[index];
              return Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: media.type == 'image'
                        ? _buildNetworkImage(media.url, fit: BoxFit.cover)
                        : Container(
                            color: Colors.black.withValues(alpha: 0.8),
                            child: Icon(
                              Icons.play_circle_outline,
                              size: 50,
                              color: Theme.of(context).colorScheme.surface,
                            ),
                          ),
                  ),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: FloatingActionButton.small(
                      heroTag: 'threads_${media.type}_$index',
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      child: Icon(
                        Icons.download,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      onPressed: () => onDownload(media.url, media.type),
                    ),
                  ),
                ],
              );
            },
          )
        else if (data.media.isNotEmpty)
          Center(
            child: DownloadActionButton(
              label: data.media[0].type == 'video'
                  ? 'Descargar\nVideo'
                  : data.media[0].type == 'audio'
                  ? 'Descargar\nAudio'
                  : 'Descargar\nImagen',
              icon: data.media[0].type == 'video'
                  ? Icons.videocam
                  : data.media[0].type == 'audio'
                  ? Icons.audiotrack
                  : Icons.image,
              color: Theme.of(context).colorScheme.primary,
              onTap: () => onDownload(data.media[0].url, data.media[0].type),
            ),
          ),
      ],
    );
  }

  Widget _stat(BuildContext context, IconData icon, int count) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.outline),
        Text(
          Formatters.formatNumber(count),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildNetworkImage(
    String url, {
    double? width,
    double? height,
    BoxFit? fit,
  }) {
    return AppNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit ?? BoxFit.cover,
    );
  }
}
