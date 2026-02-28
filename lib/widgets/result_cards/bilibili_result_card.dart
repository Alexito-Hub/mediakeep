import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../models/bilibili_model.dart';
import '../common/download_action_button_widget.dart';

/// Result card widget for Bilibili videos
class BilibiliResultCard extends StatelessWidget {
  final BilibiliData data;
  final Function(String url, String type) onDownload;

  const BilibiliResultCard({
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
              children: [
                // Cover/Thumbnail
                if (data.info.cover != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _buildNetworkImage(
                      data.info.cover!,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: 150,
                    ),
                  ),
                const SizedBox(height: 16),
                // Title
                if (data.info.title != null)
                  Text(
                    data.info.title!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 8),
                // Description
                if (data.info.desc != null)
                  Text(
                    data.info.desc!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.outline,
                      fontSize: 12,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 12),
                // Stats (Bilibili-specific: coins, danmaku)
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceAround,
                  children: [
                    if (data.stats.views != null)
                      _stat(context, Icons.visibility, data.stats.views!),
                    if (data.stats.likes != null)
                      _stat(context, Icons.thumb_up, data.stats.likes!),
                    if (data.stats.coins != null)
                      _stat(context, Icons.monetization_on, data.stats.coins!),
                    if (data.stats.favorites != null)
                      _stat(context, Icons.favorite, data.stats.favorites!),
                    if (data.stats.danmaku != null)
                      _stat(context, Icons.chat_bubble, data.stats.danmaku!),
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
        // Video options
        if (data.videos.isNotEmpty) ...[
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
              children: data.videos.map((format) {
                return DownloadActionButton(
                  label: '${format.desc ?? "Video"}\\nQ${format.quality ?? ""}',
                  icon: Icons.videocam,
                  color: Theme.of(context).colorScheme.primary,
                  onTap: () => onDownload(format.url ?? '', 'video'),
                );
              }).toList(),
            ),
          ),
        ],
        // Audio options
        if (data.audios.isNotEmpty) ...[
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text('Audio', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: data.audios.map((format) {
                return DownloadActionButton(
                  label: 'Audio\\nQ${format.quality ?? ""}',
                  icon: Icons.music_note,
                  color: Theme.of(context).colorScheme.tertiary,
                  onTap: () => onDownload(format.url ?? '', 'audio'),
                );
              }).toList(),
            ),
          ),
        ],
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
    final imageUrl = kIsWeb
        ? 'https://corsproxy.io/?${Uri.encodeComponent(url)}'
        : url;

    return Image.network(
      imageUrl,
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
