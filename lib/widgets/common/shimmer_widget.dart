import 'package:flutter/material.dart';

/// Reusable shimmer loading widget with animation
class ShimmerBox extends StatefulWidget {
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
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _position;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _position = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _position,
      builder: (context, child) {
        final value = _position.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: widget.isCircle
                ? null
                : BorderRadius.circular(widget.borderRadius),
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
    );
  }
}

/// Shimmer loading for result cards (TikTok, Facebook, etc.)
class ShimmerResultCard extends StatelessWidget {
  const ShimmerResultCard({super.key});

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
class ShimmerPlatformIcons extends StatelessWidget {
  const ShimmerPlatformIcons({super.key});

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
