import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../utils/app_routes.dart';
import '../../utils/responsive.dart';

class ShellNavItem {
  final String route;
  final String label;
  final IconData icon;

  const ShellNavItem({
    required this.route,
    required this.label,
    required this.icon,
  });
}

const List<ShellNavItem> shellMainNavItems = [
  ShellNavItem(
    route: AppRoutes.download,
    label: 'Descargar',
    icon: Icons.download_rounded,
  ),
  ShellNavItem(
    route: AppRoutes.history,
    label: 'Historial',
    icon: Icons.history_rounded,
  ),
  ShellNavItem(
    route: AppRoutes.activeDownloads,
    label: 'Activas',
    icon: Icons.downloading_rounded,
  ),
  ShellNavItem(
    route: AppRoutes.settings,
    label: 'Ajustes',
    icon: Icons.settings_rounded,
  ),
];

const List<ShellNavItem> shellInfoNavItems = [
  ShellNavItem(
    route: AppRoutes.status,
    label: 'Estado',
    icon: Icons.monitor_heart_rounded,
  ),
  ShellNavItem(
    route: AppRoutes.changelog,
    label: 'Cambios',
    icon: Icons.update_rounded,
  ),
  ShellNavItem(
    route: AppRoutes.privacy,
    label: 'Privacidad',
    icon: Icons.privacy_tip_rounded,
  ),
  ShellNavItem(
    route: AppRoutes.author,
    label: 'Autor',
    icon: Icons.info_rounded,
  ),
  ShellNavItem(
    route: AppRoutes.checkout,
    label: 'Premium',
    icon: Icons.diamond_rounded,
  ),
];

class ResponsiveShellScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final String? currentRoute;
  final List<Widget>? actions;
  final bool extendBodyBehindAppBar;
  final bool showMobileAppBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  const ResponsiveShellScaffold({
    super.key,
    required this.title,
    required this.body,
    this.currentRoute,
    this.actions,
    this.extendBodyBehindAppBar = false,
    this.showMobileAppBar = true,
    this.bottomNavigationBar,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    if (isMobile) {
      return Scaffold(
        extendBodyBehindAppBar: extendBodyBehindAppBar,
        appBar: showMobileAppBar
            ? AppBar(
                title: Text(title),
                actions: actions,
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                forceMaterialTransparency: true,
                elevation: 0,
                scrolledUnderElevation: 0,
                automaticallyImplyLeading: true,
              )
            : null,
        body: body,
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
      );
    }

    final theme = Theme.of(context);

    return Scaffold(
      body: Row(
        children: [
          _DesktopSidebar(currentRoute: currentRoute),
          VerticalDivider(
            width: 1,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
          ),
          Expanded(child: body),
        ],
      ),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  final String? currentRoute;

  const _DesktopSidebar({this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 264,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Builder(
                    builder: (ctx) {
                      final isDark =
                          Theme.of(ctx).brightness == Brightness.dark;
                      return Image.asset(
                        isDark
                            ? 'assets/logo-nobg-white.png'
                            : 'assets/logo-nobg-black.png',
                        width: 34,
                        height: 34,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Theme.of(ctx).colorScheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.play_for_work_rounded,
                            color: Theme.of(ctx).colorScheme.onPrimary,
                            size: 18,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Media Keep',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ...shellMainNavItems
                .where(
                  (item) => !kIsWeb || item.route != AppRoutes.activeDownloads,
                )
                .map(
                  (item) => _SidebarItem(
                    item: item,
                    isSelected: currentRoute == item.route,
                  ),
                ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Divider(height: 1),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Text(
                'Información',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ...shellInfoNavItems.map(
              (item) => _SidebarItem(
                item: item,
                isSelected: currentRoute == item.route,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final ShellNavItem item;
  final bool isSelected;

  const _SidebarItem({required this.item, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: isSelected
            ? theme.colorScheme.primary.withValues(alpha: 0.14)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (isSelected) {
              return;
            }
            if (ModalRoute.of(context)?.settings.name == item.route) {
              return;
            }
            Navigator.pushReplacementNamed(context, item.route);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 20,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Text(
                  item.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
