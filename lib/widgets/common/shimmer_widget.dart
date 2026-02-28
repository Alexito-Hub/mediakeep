import 'package:flutter/material.dart';

/// Reusable shimmer loading widget with animation
class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final bool isCircle;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.isCircle = false,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: -2.0, end: 2.0),
      duration: const Duration(milliseconds: 1500),
      builder: (context, value, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: isCircle ? null : BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment(value - 1, 0),
              end: Alignment(value + 1, 0),
              colors: isDark
                  ? [
                      Colors.grey.shade800,
                      Colors.grey.shade700,
                      Colors.grey.shade800,
                    ]
                  : [
                      Colors.grey.shade300,
                      Colors.grey.shade100,
                      Colors.grey.shade300,
                    ],
            ),
          ),
        );
      },
      onEnd: () {
        // Animation will restart automatically when widget rebuilds
      },
    );
  }
}

/// Shimmer loading for result cards (TikTok, Facebook, etc.)
class ShimmerResultCard extends StatefulWidget {
  const ShimmerResultCard({super.key});

  @override
  State<ShimmerResultCard> createState() => _ShimmerResultCardState();
}

class _ShimmerResultCardState extends State<ShimmerResultCard> {
  @override
  void initState() {
    super.initState();
    // Trigger rebuild every 1.5s to restart animation
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const ShimmerBox(width: 60, height: 60, borderRadius: 12),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ShimmerBox(width: double.infinity, height: 16),
                    SizedBox(height: 8),
                    ShimmerBox(width: 150, height: 12),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const ShimmerBox(width: double.infinity, height: 12),
          const SizedBox(height: 6),
          const ShimmerBox(width: 200, height: 12),
          const SizedBox(height: 16),
          Row(
            children: const [
              ShimmerBox(width: 100, height: 36, borderRadius: 20),
              SizedBox(width: 12),
              ShimmerBox(width: 100, height: 36, borderRadius: 20),
            ],
          ),
        ],
      ),
    );
  }
}

/// Shimmer loading for platform icons section
class ShimmerPlatformIcons extends StatefulWidget {
  const ShimmerPlatformIcons({super.key});

  @override
  State<ShimmerPlatformIcons> createState() => _ShimmerPlatformIconsState();
}

class _ShimmerPlatformIconsState extends State<ShimmerPlatformIcons> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        5,
        (i) => Column(
          children: const [
            ShimmerBox(width: 56, height: 56, isCircle: true),
            SizedBox(height: 8),
            ShimmerBox(width: 60, height: 10),
          ],
        ),
      ),
    );
  }
}
