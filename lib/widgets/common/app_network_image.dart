import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class AppNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? errorFallback;

  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.errorFallback,
  });

  @override
  Widget build(BuildContext context) {
    final image = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 180),
      placeholder: (context, url) => Container(
        width: width,
        height: height,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      errorWidget: (context, url, error) =>
          errorFallback ??
          Container(
            width: width,
            height: height,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Icon(Icons.broken_image),
          ),
    );

    if (borderRadius == null) {
      return image;
    }

    return ClipRRect(borderRadius: borderRadius!, child: image);
  }
}
