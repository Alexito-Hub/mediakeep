import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../models/twitter_model.dart';
import '../common/download_action_button_widget.dart';

/// Result card widget for Twitter/X media
class TwitterResultCard extends StatelessWidget {
  final TwitterData data;
  final Function(String url, String type) onDownload;

  const TwitterResultCard({
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
                // Title/Tweet text
                if (data.title != null)
                  Text(
                    data.title!,
                    style: const TextStyle(fontSize: 14),
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (data.title != null &&
                    data.media != null &&
                    data.media!.isNotEmpty)
                  const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Media items
        if (data.media != null && data.media!.isNotEmpty)
          ...data.media!.asMap().entries.map((entry) {
            final index = entry.key;
            final media = entry.value;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Column(
                children: [
                  // Thumbnail
                  if (media.thumbnail != null)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: _buildNetworkImage(
                        media.thumbnail!,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: 150,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Medio ${index + 1} - ${media.type ?? "Desconocido"}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Video variants (different resolutions)
                        if (media.variants != null &&
                            media.variants!.isNotEmpty) ...[
                          const Text(
                            'Calidades disponibles:',
                            style: TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: media.variants!.map((variant) {
                              return DownloadActionButton(
                                label: variant.resolution ?? 'Video',
                                icon: Icons.videocam,
                                color: Theme.of(context).colorScheme.primary,
                                onTap: () =>
                                    onDownload(variant.url ?? '', 'video'),
                              );
                            }).toList(),
                          ),
                        ],
                        // Direct URL (for images)
                        if (media.url != null &&
                            (media.type?.toLowerCase().contains('photo') ==
                                    true ||
                                media.variants == null ||
                                media.variants!.isEmpty)) ...[
                          const SizedBox(height: 8),
                          DownloadActionButton(
                            label: 'Descargar Imagen',
                            icon: Icons.image,
                            color: Theme.of(context).colorScheme.secondary,
                            onTap: () => onDownload(media.url!, 'image'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        if (data.media == null || data.media!.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No se encontró contenido multimedia para descargar'),
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
