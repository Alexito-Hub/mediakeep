import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/youtube_model.dart';
import '../common/app_network_image.dart';
import '../common/download_action_button_widget.dart';

/// Result card widget for YouTube videos
class YouTubeResultCard extends StatelessWidget {
  final YouTubeData data;
  final Function(String url, String type) onDownload;

  const YouTubeResultCard({
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with channel info
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    if (data.channel.avatar != null)
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: CachedNetworkImageProvider(
                          data.channel.avatar!,
                        ),
                      )
                    else
                      const CircleAvatar(radius: 20, child: Icon(Icons.person)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  data.channel.name ?? 'YouTube',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (data.channel.verified) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.verified,
                                  size: 16,
                                  color: Colors.blue,
                                ),
                              ],
                            ],
                          ),
                          if (data.stats.subs != null)
                            Text(
                              '${data.stats.subs} suscriptores',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Thumbnail
              if (data.info.thumb != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(0),
                  child: _buildNetworkImage(
                    data.info.thumb!,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: 200,
                  ),
                ),
              // Title and stats
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (data.info.title != null)
                      Text(
                        data.info.title!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 12),
                    // Stats row
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      alignment: WrapAlignment.spaceAround,
                      children: [
                        if (data.stats.views != null)
                          _stat(context, Icons.visibility, data.stats.views!),
                        if (data.stats.likes != null)
                          _stat(context, Icons.thumb_up, data.stats.likes!),
                        if (data.stats.comments != null)
                          _stat(context, Icons.comment, data.stats.comments!),
                        if (data.stats.shares != null)
                          _stat(context, Icons.share, data.stats.shares!),
                        if (data.stats.favorites != null)
                          _stat(context, Icons.favorite, data.stats.favorites!),
                        if (data.stats.downloads != null)
                          _stat(context, Icons.download, data.stats.downloads!),
                      ],
                    ),
                  ],
                ),
              ),
            ],
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
        // Video options
        if (data.videos
            .where((f) => f.url != null && f.url!.isNotEmpty)
            .isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              'Videos',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: data.videos
                  .where(
                    (format) => format.url != null && format.url!.isNotEmpty,
                  )
                  .map((format) {
                    return DownloadActionButton(
                      label:
                          '${format.quality ?? format.res ?? "Video"}\\n${format.size ?? ""}',
                      icon:
                          format.res?.contains('1080') == true ||
                              format.quality?.contains('1080') == true
                          ? Icons.hd
                          : Icons.videocam,
                      color: Theme.of(context).colorScheme.primary,
                      onTap: () => onDownload(format.url!, 'video'),
                    );
                  })
                  .toList(),
            ),
          ),
        ],
        // Audio options
        if (data.audios
            .where((f) => f.url != null && f.url!.isNotEmpty)
            .isNotEmpty) ...[
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text('Audio', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: data.audios
                  .where(
                    (format) => format.url != null && format.url!.isNotEmpty,
                  )
                  .map((format) {
                    return DownloadActionButton(
                      label:
                          'Audio ${format.quality ?? ""}\\n${format.size ?? ""}',
                      icon: Icons.music_note,
                      color: Theme.of(context).colorScheme.tertiary,
                      onTap: () => onDownload(format.url!, 'audio'),
                    );
                  })
                  .toList(),
            ),
          ),
        ],
        // Fallback when no download options available
        if (data.videos
                .where((f) => f.url != null && f.url!.isNotEmpty)
                .isEmpty &&
            data.audios
                .where((f) => f.url != null && f.url!.isNotEmpty)
                .isEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No se encontraron opciones de descarga',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'El video puede estar protegido o no disponible',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _stat(BuildContext context, IconData icon, String count) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.outline),
        Text(
          count,
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
