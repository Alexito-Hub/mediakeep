import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/download_history_model.dart';
import '../services/history_service.dart';
import '../screens/media_preview_screen.dart';
import '../utils/constants.dart';
import '../utils/platform_config.dart';

import '../utils/responsive.dart';
import '../utils/app_routes.dart';
import '../widgets/layout/responsive_shell_scaffold.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<DownloadHistoryItem> _historyItems = [];
  bool _isLoading = true;
  String? _selectedPlatformFilter;
  String? _selectedTypeFilter;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // banner state is now managed by AdBanner widget, so we no longer need
  // _bannerAd or _isBannerAdLoaded fields.

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _searchController.addListener(_filterSearch);

    // no longer load manually; AdBanner handles everything internally
    // (the previous code is kept for reference but not executed)
    // AdManager.loadBanner(() {
    //   if (mounted) setState(() => _isBannerAdLoaded = true);
    // }).then((ad) {
    //   if (mounted) setState(() => _bannerAd = ad);
    // });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _filterSearch() {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final items = await HistoryService.getFilteredHistory(
      platform: _selectedPlatformFilter,
      type: _selectedTypeFilter,
    );

    final query = _searchController.text.toLowerCase();
    _historyItems = items.where((item) {
      return item.fileName.toLowerCase().contains(query);
    }).toList();

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteItem(String id) async {
    await HistoryService.deleteHistoryItem(id);
    _loadHistory();
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Limpiar historial?'),
        content: const Text(
          'Esta acción no eliminará los archivos de tu dispositivo, solo el registro en la app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Limpiar Todo'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await HistoryService.clearHistory();
      _loadHistory();
    }
  }

  Map<String, List<DownloadHistoryItem>> _groupItems(
    List<DownloadHistoryItem> items,
  ) {
    final Map<String, List<DownloadHistoryItem>> groups = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (var item in items) {
      final itemDate = DateTime(
        item.downloadedAt.year,
        item.downloadedAt.month,
        item.downloadedAt.day,
      );

      String groupTitle;
      if (itemDate == today) {
        groupTitle = 'Hoy';
      } else if (itemDate == yesterday) {
        groupTitle = 'Ayer';
      } else if (itemDate.isAfter(today.subtract(const Duration(days: 7)))) {
        groupTitle = 'Esta semana';
      } else {
        groupTitle = DateFormat('MMMM d, yyyy', 'es').format(itemDate);
        // Capitalize first letter
        groupTitle = groupTitle[0].toUpperCase() + groupTitle.substring(1);
      }

      if (!groups.containsKey(groupTitle)) {
        groups[groupTitle] = [];
      }
      groups[groupTitle]!.add(item);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final groupedItems = _groupItems(_historyItems);

    return ResponsiveShellScaffold(
      title: 'Tu Historial',
      currentRoute: AppRoutes.history,
      showMobileAppBar: false,
      actions: [
        if (_historyItems.isNotEmpty)
          IconButton(
            onPressed: _clearAll,
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: 'Limpiar todo',
          ),
      ],
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(),
              _buildSearchAndFilters(),
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_historyItems.isEmpty)
                SliverFillRemaining(child: _buildEmptyState())
              else if (Responsive.isMobile(context))
                // Mobile: grouped chronological list (existing behavior)
                ...groupedItems.entries.map((entry) {
                  return SliverMainAxisGroup(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                          child: Text(
                            entry.key,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            return RepaintBoundary(
                              child: _buildHistoryCard(entry.value[index]),
                            );
                          }, childCount: entry.value.length),
                        ),
                      ),
                    ],
                  );
                })
              else
                // Desktop: grouped 3-column grid with date section headers
                ...groupedItems.entries.map((entry) {
                  return SliverMainAxisGroup(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(40, 28, 40, 12),
                          child: Row(
                            children: [
                              Text(
                                entry.key,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Divider(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outlineVariant
                                      .withValues(alpha: 0.4),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${entry.value.length} archivo${entry.value.length == 1 ? '' : 's'}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outline,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: 3.2,
                              ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => RepaintBoundary(
                              child: _buildHistoryCardGrid(entry.value[index]),
                            ),
                            childCount: entry.value.length,
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ],
      ),
      bottomNavigationBar: null,
    );
  }

  Widget _buildSliverAppBar() {
    final isDesktop = !Responsive.isMobile(context);
    if (isDesktop) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(40, 32, 40, 0),
          child: Row(
            children: [
              Text(
                'Tu Historial',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (_historyItems.isNotEmpty)
                IconButton(
                  onPressed: _clearAll,
                  icon: const Icon(Icons.delete_sweep_rounded),
                  tooltip: 'Limpiar todo',
                ),
            ],
          ),
        ),
      );
    }
    return SliverAppBar(
      floating: true,
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: true,
      title: const Text(
        'Tu Historial',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      centerTitle: false,
      actions: [
        if (_historyItems.isNotEmpty)
          IconButton(
            onPressed: _clearAll,
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: 'Limpiar todo',
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    final hp = Responsive.isMobile(context) ? 16.0 : 40.0;
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(hp, 8, hp, 8),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar en descargas...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildFilterChip('Todo', null, null),
                  _buildFilterChip('Videos', 'type', 'video'),
                  _buildFilterChip('Audios', 'type', 'audio'),
                  ...AppConstants.platformPatterns.keys.map((platform) {
                    return _buildFilterChip(
                      PlatformConfigs.getDisplayName(platform),
                      'platform',
                      platform,
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String? group, String? value) {
    bool isSelected = false;
    if (group == null) {
      isSelected =
          _selectedPlatformFilter == null && _selectedTypeFilter == null;
    } else if (group == 'platform') {
      isSelected = _selectedPlatformFilter == value;
    } else if (group == 'type') {
      isSelected = _selectedTypeFilter == value;
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            if (group == null) {
              _selectedPlatformFilter = null;
              _selectedTypeFilter = null;
            } else if (group == 'platform') {
              _selectedPlatformFilter = selected ? value : null;
            } else if (group == 'type') {
              _selectedTypeFilter = selected ? value : null;
            }
          });
          _loadHistory();
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        showCheckmark: false,
        backgroundColor: Colors.transparent,
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }

  // Grid variant of history card: no outer horizontal margin (grid manages spacing).
  Widget _buildHistoryCardGrid(DownloadHistoryItem item) {
    IconData typeIcon;
    Color iconColor;
    switch (item.type) {
      case 'video':
        typeIcon = Icons.movie_creation_rounded;
        iconColor = Colors.redAccent;
        break;
      case 'audio':
        typeIcon = Icons.music_note_rounded;
        iconColor = Colors.greenAccent.shade700;
        break;
      case 'image':
        typeIcon = Icons.image_rounded;
        iconColor = Colors.blueAccent;
        break;
      default:
        typeIcon = Icons.insert_drive_file_rounded;
        iconColor = Colors.grey;
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MediaPreviewScreen(
                  filePath: item.filePath,
                  fileName: item.fileName,
                  fileType: item.type,
                  platform: item.platformName,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: item.type == 'image'
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(
                            File(item.filePath),
                            fit: BoxFit.cover,
                            cacheWidth: 256,
                            cacheHeight: 256,
                            errorBuilder: (context, error, stackTrace) =>
                                Icon(typeIcon, color: iconColor, size: 24),
                          ),
                        )
                      : Icon(typeIcon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _platformBadge(item.platform),
                          const SizedBox(width: 6),
                          Text(
                            item.formattedSize,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.outline,
                              fontSize: 11,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            DateFormat('HH:mm').format(item.downloadedAt),
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.outline.withValues(alpha: 0.6),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildActionsMenu(item),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(DownloadHistoryItem item) {
    IconData typeIcon;
    Color iconColor;

    switch (item.type) {
      case 'video':
        typeIcon = Icons.movie_creation_rounded;
        iconColor = Colors.redAccent;
        break;
      case 'audio':
        typeIcon = Icons.music_note_rounded;
        iconColor = Colors.greenAccent.shade700;
        break;
      case 'image':
        typeIcon = Icons.image_rounded;
        iconColor = Colors.blueAccent;
        break;
      default:
        typeIcon = Icons.insert_drive_file_rounded;
        iconColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () {
            if (!File(item.filePath).existsSync()) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Descargando o el archivo no existe. Por favor espera.',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MediaPreviewScreen(
                  filePath: item.filePath,
                  fileName: item.fileName,
                  fileType: item.type,
                  platform: item.platformName,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Hero(
                  tag: item.id,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: iconColor.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (item.type == 'image' &&
                            File(item.filePath).existsSync())
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.file(
                              File(item.filePath),
                              fit: BoxFit.cover,
                              width: 72,
                              height: 72,
                              cacheWidth: 256,
                              cacheHeight: 256,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(typeIcon, color: iconColor, size: 28),
                            ),
                          )
                        else
                          Icon(typeIcon, color: iconColor, size: 30),

                        // Overlay platform icon small
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: _getPlatformIconSmall(item.platform),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _platformBadge(item.platform),
                          const SizedBox(width: 8),
                          Text(
                            item.formattedSize,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.outline,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            DateFormat('HH:mm').format(item.downloadedAt),
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.outline.withValues(alpha: 0.6),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildActionsMenu(item),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _getPlatformIconSmall(String platform) {
    IconData icon;
    Color color;
    switch (platform.toLowerCase()) {
      case 'tiktok':
        icon = Icons.music_note_rounded;
        color = Colors.black; // Better icon needed but using Material for now
        break;
      case 'facebook':
        icon = Icons.facebook_rounded;
        color = const Color(0xFF1877F2);
        break;
      case 'spotify':
        icon = Icons.audiotrack_rounded;
        color = const Color(0xFF1DB954);
        break;
      case 'threads':
        icon = Icons.alternate_email_rounded;
        color = Colors.black;
        break;
      default:
        icon = Icons.link_rounded;
        color = Colors.grey;
    }
    return Icon(icon, size: 12, color: color);
  }

  Widget _platformBadge(String platform) {
    Color badgeColor;
    Color textColor = Colors.white;
    String name = platform.toUpperCase();

    switch (platform.toLowerCase()) {
      case 'tiktok':
        badgeColor = const Color(0xFFEE1D52);
        name = 'TIKTOK';
        break;
      case 'facebook':
        badgeColor = const Color(0xFF1877F2);
        name = 'FACEBOOK';
        break;
      case 'spotify':
        badgeColor = const Color(0xFF1DB954);
        name = 'SPOTIFY';
        break;
      case 'threads':
        badgeColor = Colors.black;
        name = 'THREADS';
        break;
      default:
        badgeColor = Theme.of(context).colorScheme.primaryContainer;
        textColor = Theme.of(context).colorScheme.onPrimaryContainer;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome_motion_rounded,
              size: 80,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Tu historial está vacío',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Descarga videos o música para verlos aquí.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsMenu(DownloadHistoryItem item) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz_rounded, size: 22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (value) {
        if (value == 'share') {
          if (!File(item.filePath).existsSync()) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'El archivo aún está descargando o fue eliminado.',
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }
          Share.shareXFiles([XFile(item.filePath)]);
        }
        if (value == 'delete') _deleteItem(item.id);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'share',
          child: Row(
            children: [
              Icon(Icons.share_rounded, size: 20),
              SizedBox(width: 12),
              Text('Compartir'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red),
              SizedBox(width: 12),
              const Text('Eliminar', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }
}
