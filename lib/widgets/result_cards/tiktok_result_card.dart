import 'package:flutter/material.dart';
import '../../models/tiktok_model.dart';
import '../../utils/formatters.dart';
import '../common/download_action_button_widget.dart';

/// Result card widget for TikTok media
class TikTokResultCard extends StatelessWidget {
  final TikTokData data;
  final Function(String url, String type) onDownload;
  final GlobalKey? tutorialDownloadKey;

  const TikTokResultCard({
    super.key,
    required this.data,
    required this.onDownload,
    this.tutorialDownloadKey,
  });

  @override
  Widget build(BuildContext context) {
    final isVideo = data.media.type == 'video';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(data.author.avatar),
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                  ),
                  title: Text(
                    data.author.nickname,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    data.title.isNotEmpty ? data.title : 'Sin descripción',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _buildNetworkImage(
                    data.cover,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 200,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _stat(context, Icons.visibility, data.playCount),
                    _stat(context, Icons.favorite, data.diggCount),
                    _stat(context, Icons.share, data.shareCount),
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
        if (isVideo)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (data.media.noWatermark?.hdPlay != null)
                  DownloadActionButton(
                    key: tutorialDownloadKey,
                    label: 'Video HD\n(Sin Marca)',
                    icon: Icons.hd,
                    color: Theme.of(context).colorScheme.primary,
                    onTap: () {
                      onDownload(data.media.noWatermark?.hdPlay ?? '', 'video');
                    },
                  ),
                if (data.media.noWatermark?.play != null)
                  DownloadActionButton(
                    label: 'Video SD\n(Sin Marca)',
                    icon: Icons.videocam,
                    color: Theme.of(context).colorScheme.secondary,
                    onTap: () =>
                        onDownload(data.media.noWatermark?.play ?? '', 'video'),
                  ),
                if (data.media.watermark?.play != null)
                  DownloadActionButton(
                    label: 'Video\n(Con Marca)',
                    icon: Icons.water_drop,
                    color: Theme.of(context).colorScheme.outline,
                    onTap: () =>
                        onDownload(data.media.watermark?.play ?? '', 'video'),
                  ),
                if (data.music?.playUrl != null)
                  DownloadActionButton(
                    label: 'Solo Audio\n(MP3)',
                    icon: Icons.music_note,
                    color: Theme.of(context).colorScheme.tertiary,
                    onTap: () => onDownload(data.music?.playUrl ?? '', 'audio'),
                  ),
              ],
            ),
          )
        else if (data.media.type == 'image') ...[
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: data.media.images.length,
            itemBuilder: (context, index) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildNetworkImage(
                      data.media.images[index],
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: FloatingActionButton.small(
                      heroTag: 'img$index',
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      child: Icon(
                        Icons.download,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      onPressed: () =>
                          onDownload(data.media.images[index], 'image'),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
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
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => Container(
        width: width,
        height: height,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Icon(Icons.broken_image),
      ),
    );
  }
}
