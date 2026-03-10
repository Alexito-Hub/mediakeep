import 'package:flutter/material.dart';

class SpotlightOverlay extends StatelessWidget {
  final GlobalKey? targetKey;
  final String title;
  final String message;
  final IconData icon;
  final Widget? actionButton;
  final VoidCallback onSkipOrFinish;
  final String skipButtonText;
  final VoidCallback? onTargetTap;

  const SpotlightOverlay({
    super.key,
    required this.targetKey,
    required this.title,
    required this.message,
    required this.icon,
    this.actionButton,
    required this.onSkipOrFinish,
    this.skipButtonText = 'Omitir Tutorial',
    this.onTargetTap,
  });

  @override
  Widget build(BuildContext context) {
    Rect? targetRect;

    if (targetKey != null && targetKey!.currentContext != null) {
      final box = targetKey!.currentContext!.findRenderObject() as RenderBox?;
      if (box != null) {
        final Offset position = box.localToGlobal(Offset.zero);
        targetRect = position & box.size;
      }
    }

    return Stack(
      children: [
        // The darkened background with a hole punch
        CustomPaint(
          size: Size.infinite,
          painter: _SpotlightPainter(targetRect: targetRect),
        ),

        // Invisible button directly over the target to handle taps
        if (targetRect != null && onTargetTap != null)
          Positioned.fromRect(
            rect: targetRect,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: onTargetTap,
              child: const SizedBox.expand(),
            ),
          ),

        // The instructions UI (Tooltip Box)
        _buildTooltipBox(context, targetRect),
      ],
    );
  }

  Widget _buildTooltipBox(BuildContext context, Rect? targetRect) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    // Calculate vertical position (default to bottom if no target)
    double? top;
    double? bottom;

    if (targetRect != null) {
      if (targetRect.top > 300) {
        // Place above the target
        bottom = MediaQuery.of(context).size.height - targetRect.top + 20;
      } else {
        // Place below the target
        top = targetRect.bottom + 20;
      }
    } else {
      bottom = isMobile ? 120 : 60; // Center fallback
    }

    return Positioned(
      top: top,
      bottom: bottom,
      left: 20,
      right: 20,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 340),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(icon, size: 28, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
                textAlign: TextAlign.left,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: actionButton != null
                    ? MainAxisAlignment.spaceBetween
                    : MainAxisAlignment.end,
                children: [
                  if (actionButton != null) actionButton!,
                  TextButton(
                    onPressed: onSkipOrFinish,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: Text(
                      skipButtonText,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final Rect? targetRect;

  _SpotlightPainter({this.targetRect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    if (targetRect == null) {
      canvas.drawRect(Offset.zero & size, paint);
      return;
    }

    final path = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(
        RRect.fromRectAndRadius(
          targetRect!.inflate(4.0), // Give it a little padding
          const Radius.circular(12),
        ),
      )
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect;
  }
}
