import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../models/instagram_model.dart';
import '../common/download_action_button_widget.dart';

/// Result card widget for Instagram media
class InstagramResultCard extends StatefulWidget {
  final InstagramData data;
  final Function(String url, String type) onDownload;

  const InstagramResultCard({
    super.key,
    required this.data,
    required this.onDownload,
  });

  @override
  State<InstagramResultCard> createState() => _InstagramResultCardState();
}

class _InstagramResultCardState extends State<InstagramResultCard> {
  int _currentMediaIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.data.media.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 8),
              const Text(
                'No se encontró contenido para descargar',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Este post puede ser privado o no estar disponible',
                style: TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final currentMedia = widget.data.media[_currentMediaIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.photo_library,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Instagram',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${widget.data.media.length} ${widget.data.media.length == 1 ? "elemento" : "elementos"}',
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
              // Media preview
              if (currentMedia.thumb != null)
                Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(12),
                      ),
                      child: _buildNetworkImage(
                        currentMedia.thumb!,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: 200,
                      ),
                    ),
                    // Navigation arrows for multiple media
                    if (widget.data.media.length > 1) ...[
                      Positioned(
                        left: 8,
                        child: IconButton(
                          icon: const Icon(Icons.chevron_left, size: 32),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black.withValues(
                              alpha: 0.5,
                            ),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _currentMediaIndex > 0
                              ? () => setState(() => _currentMediaIndex--)
                              : null,
                        ),
                      ),
                      Positioned(
                        right: 8,
                        child: IconButton(
                          icon: const Icon(Icons.chevron_right, size: 32),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black.withValues(
                              alpha: 0.5,
                            ),
                            foregroundColor: Colors.white,
                          ),
                          onPressed:
                              _currentMediaIndex < widget.data.media.length - 1
                              ? () => setState(() => _currentMediaIndex++)
                              : null,
                        ),
                      ),
                      // Page indicator dots
                      Positioned(
                        bottom: 12,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            widget.data.media.length,
                            (index) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: index == _currentMediaIndex
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
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
        // Download options for current media
        if (currentMedia.options.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: currentMedia.options.map((option) {
                final isVideo = option.res.toLowerCase().contains('video');
                return DownloadActionButton(
                  label: option.res,
                  icon: isVideo ? Icons.videocam : Icons.image,
                  color: isVideo
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.secondary,
                  onTap: () => widget.onDownload(
                    option.url,
                    isVideo ? 'video' : 'image',
                  ),
                );
              }).toList(),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'No hay opciones de descarga disponibles para este elemento',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
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
