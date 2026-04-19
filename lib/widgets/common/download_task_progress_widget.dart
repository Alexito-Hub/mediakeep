import 'package:flutter/material.dart';

import '../../services/download_progress_service.dart';

class DownloadTaskProgressWidget extends StatelessWidget {
  final DownloadTaskProgress progress;
  final VoidCallback? onRetry;
  final bool compact;

  const DownloadTaskProgressWidget({
    super.key,
    required this.progress,
    this.onRetry,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      child: _buildCurrentState(context),
    );
  }

  Widget _buildCurrentState(BuildContext context) {
    if (progress.isCompleted) {
      return _buildCompleted(context);
    }

    if (progress.isError) {
      return _buildError(context);
    }

    return _buildInProgress(context);
  }

  Widget _buildInProgress(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      key: ValueKey('running_${progress.taskId}'),
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.35,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            progress.fileName ?? 'Descargando archivo...',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (progress.progress.clamp(0, 100)) / 100,
            minHeight: compact ? 6 : 8,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 6),
          Text(
            'Descargando ${progress.progress}%',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleted(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      key: ValueKey('completed_${progress.taskId}'),
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.7, end: 1),
            duration: const Duration(milliseconds: 260),
            builder: (context, value, child) {
              return Transform.scale(scale: value, child: child);
            },
            child: const Icon(Icons.check_circle_rounded, color: Colors.green),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Descarga completada',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      key: ValueKey('error_${progress.taskId}'),
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_rounded, color: theme.colorScheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Error en la descarga',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (onRetry != null)
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Reintentar'),
            ),
        ],
      ),
    );
  }
}
