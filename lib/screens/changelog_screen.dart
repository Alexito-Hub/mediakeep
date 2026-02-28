import 'package:flutter/material.dart';
import '../models/changelog_model.dart';
import '../services/changelog_service.dart';
import '../utils/responsive.dart';

class ChangelogScreen extends StatefulWidget {
  const ChangelogScreen({super.key});

  @override
  State<ChangelogScreen> createState() => _ChangelogScreenState();
}

class _ChangelogScreenState extends State<ChangelogScreen> {
  List<ChangelogEntry> _changelog = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChangelog();
  }

  Future<void> _loadChangelog() async {
    final data = await ChangelogService.getChangelog();
    if (mounted) {
      setState(() {
        _changelog = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Cambios'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _changelog.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: Responsive.getContentPadding(context),
              itemCount: _changelog.length,
              itemBuilder: (context, index) {
                return _buildVersionNode(_changelog[index], index == 0, theme);
              },
            ),
    );
  }

  Widget _buildVersionNode(
    ChangelogEntry entry,
    bool isLatest,
    ThemeData theme,
  ) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: isLatest
                      ? theme.colorScheme.primary
                      : theme.dividerColor,
                  shape: BoxShape.circle,
                  border: isLatest
                      ? Border.all(
                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                          width: 4,
                        )
                      : null,
                ),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: theme.dividerColor.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'v${entry.version}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isLatest ? theme.colorScheme.primary : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        entry.date,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 
                            0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    entry.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...entry.changes.map((item) => _buildChangeItem(item, theme)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangeItem(ChangeItem item, ThemeData theme) {
    IconData icon;
    Color color;

    switch (item.type) {
      case 'feature':
        icon = Icons.add_circle_outline;
        color = Colors.green;
        break;
      case 'fix':
        icon = Icons.bug_report_outlined;
        color = Colors.red;
        break;
      case 'improvement':
        icon = Icons.trending_up;
        color = Colors.blue;
        break;
      default:
        icon = Icons.info_outline;
        color = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color.withValues(alpha: 0.8)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.description,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text('No hay registros de cambios disponibles.'),
    );
  }
}

