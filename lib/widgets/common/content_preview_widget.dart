import 'package:flutter/material.dart';

class ContentPreview extends StatefulWidget {
  final String coverUrl;
  final String? videoUrl;

  const ContentPreview({super.key, required this.coverUrl, this.videoUrl});

  @override
  State<ContentPreview> createState() => _ContentPreviewState();
}

class _ContentPreviewState extends State<ContentPreview> {
  bool _showVideo = false;

  @override
  Widget build(BuildContext context) {
    if (_showVideo && widget.videoUrl != null) {
      return _buildRemoteDisabledState();
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        _buildLocalFallback(
          width: double.infinity,
          height: 250,
          fit: BoxFit.cover,
        ),
        if (widget.videoUrl != null)
          GestureDetector(
            onTap: () => setState(() => _showVideo = true),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLocalFallback({double? width, double? height, BoxFit? fit}) {
    return Container(
      width: width,
      height: height,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(
        child: Icon(Icons.image_not_supported_rounded, size: 40),
      ),
    );
  }

  Widget _buildRemoteDisabledState() {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      child: Text(
        'La previsualización remota fue eliminada. Usa previsualización local BETA.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
