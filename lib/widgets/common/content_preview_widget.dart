import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../media/video_preview_widget.dart';

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
      return VideoPreviewWidget(url: widget.videoUrl, autoPlay: true);
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        _buildNetworkImage(
          widget.coverUrl,
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
