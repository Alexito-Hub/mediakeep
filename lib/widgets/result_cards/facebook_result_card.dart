import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../models/facebook_model.dart';
import '../common/download_action_button_widget.dart';

/// Result card widget for Facebook media
class FacebookResultCard extends StatelessWidget {
  final FacebookData data;
  final Function(String url, String type) onDownload;

  const FacebookResultCard({
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
                Text(
                  data.author,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  data.title,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                const SizedBox(height: 8),
                Text(
                  data.creation,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.outline,
                    fontSize: 12,
                  ),
                ),
                if (data.thumbnail != null) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _buildNetworkImage(
                      data.thumbnail!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 200,
                    ),
                  ),
                ],
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
        if (data.isVideo && data.download != null)
          Center(
            child: DownloadActionButton(
              label: 'Descargar\nVideo',
              icon: Icons.videocam,
              color: Theme.of(context).colorScheme.primary,
              onTap: () => onDownload(data.download!, 'video'),
            ),
          )
        else if (data.isSingleImage && data.download != null)
          Center(
            child: DownloadActionButton(
              label: 'Descargar\nImagen',
              icon: Icons.image,
              color: Theme.of(context).colorScheme.primary,
              onTap: () => onDownload(data.download!, 'image'),
            ),
          )
        else if (data.isAlbum && data.images != null)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: data.images!.length,
            itemBuilder: (context, index) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildNetworkImage(
                      data.images![index],
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: FloatingActionButton.small(
                      heroTag: 'fb_img$index',
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      child: Icon(
                        Icons.download,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      onPressed: () => onDownload(data.images![index], 'image'),
                    ),
                  ),
                ],
              );
            },
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
