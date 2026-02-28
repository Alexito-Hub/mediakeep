import 'package:flutter/material.dart';

/// Animated platform icon widget
class PlatformIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final bool isActive;

  const PlatformIcon({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final finalColor = isActive
        ? (isDark && color == Colors.black ? Colors.white : color)
        : Colors.grey.withValues(alpha: 0.3);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isActive
                ? finalColor.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive
                  ? finalColor.withValues(alpha: 0.2)
                  : Colors.transparent,
            ),
          ),
          child: Icon(icon, color: finalColor, size: 28),
        ),
        const SizedBox(height: 4),
        AnimatedOpacity(
          opacity: isActive ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: finalColor,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}
