// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../services/history_service.dart';
import '../services/app_version_service.dart';
import '../services/permission_service.dart';
import '../main.dart';
import '../utils/responsive.dart';
import '../utils/app_routes.dart';
import '../widgets/layout/responsive_shell_scaffold.dart';
import 'privacy_screen.dart';
import 'author_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'status_screen.dart';
import 'changelog_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Settings screen for app configuration
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  ThemeMode _currentThemeMode = ThemeMode.system;
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = true;
  bool _autoDownloadEnabled = false;
  String _appVersion = 'Cargando...';
  static const _kSectionTitles = [
    'Apariencia',
    'Compartir',
    'Almacenamiento',
    'Beta',
  ];
  static const _kSectionIcons = [
    Icons.palette_rounded,
    Icons.share_rounded,
    Icons.folder_rounded,
    Icons.science_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final themeMode = await SettingsService.getThemeMode();
    final shareMessage = await SettingsService.getShareMessage();
    final version = await AppVersionService.getVersion();
    final autoDownload = await SettingsService.getAutoDownloadEnabled();

    setState(() {
      _currentThemeMode = themeMode;
      _messageController.text = shareMessage;
      _appVersion = version;
      _autoDownloadEnabled = autoDownload;
      _isLoading = false;
    });
  }

  Future<void> _updateThemeMode(ThemeMode mode) async {
    await SettingsService.setThemeMode(mode);
    setState(() => _currentThemeMode = mode);

    // Update app theme - capture context before async gap
    if (mounted) {
      final appState = context.findAncestorStateOfType<DownloaderAppState>();
      appState?.updateThemeMode(mode);
      _showToast('Tema actualizado');
    }
  }

  Future<void> _saveShareMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      _showToast('El mensaje no puede estar vacío', isError: true);
      return;
    }

    await SettingsService.setShareMessage(message);
    _showToast('Mensaje guardado');
  }

  Future<void> _resetShareMessage() async {
    await SettingsService.resetShareMessage();
    setState(() {
      _messageController.text = SettingsService.defaultShareMessage;
    });
    _showToast('Mensaje restaurado');
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpiar historial'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar todo el historial de descargas?',
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
            ),
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await HistoryService.clearHistory();
      if (mounted) _showToast('Historial eliminado');
    }
  }

  Future<void> _openDownloadsFolder() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final mediakeepPath = '${directory.path}/MediaKeep';

      if (Platform.isAndroid) {
        // On Android, try to open file manager at the location
        final uri = Uri.parse(
          'content://com.android.externalstorage.documents/document/primary:MediaKeep',
        );
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          _showToast('Ubicación: MediaKeep/');
        }
      } else {
        _showToast('Ubicación: $mediakeepPath');
      }
    } catch (e) {
      _showToast('No se pudo acceder a la carpeta', isError: true);
    }
  }

  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.inverseSurface,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── Auto-Download beta ───────────────────────────────────────────────────

  Future<void> _toggleAutoDownload(bool value) async {
    if (value) {
      // Show instruction bottom sheet — user must confirm before enabling
      await _showAutoDownloadInstructionSheet();
    } else {
      await SettingsService.setAutoDownloadEnabled(false);
      setState(() => _autoDownloadEnabled = false);
      _showToast('Descargas automáticas desactivadas');
    }
  }

  Future<void> _showAutoDownloadInstructionSheet() async {
    bool _permissionsGranted = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.65,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              builder: (_, scrollCtrl) {
                return SingleChildScrollView(
                  controller: scrollCtrl,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // drag handle
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Theme.of(ctx).colorScheme.outlineVariant,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),

                        // Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade700,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.science_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'BETA',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Descargas Automáticas',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Cuando está activo, MediaKeep monitorea el portapapeles en segundo plano '
                          'y descarga automáticamente cualquier enlace compatible que copies.',
                          style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Instructions
                        Text(
                          'Cómo habilitarlo',
                          style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildStep(
                          ctx,
                          number: 1,
                          icon: Icons.toggle_on_rounded,
                          text:
                              'Activa esta función desde la sección Beta en Configuración (ya estás aquí).',
                        ),
                        _buildStep(
                          ctx,
                          number: 2,
                          icon: Icons.content_paste_rounded,
                          text:
                              'Concede el permiso de almacenamiento y notificaciones cuando se solicite.',
                        ),
                        _buildStep(
                          ctx,
                          number: 3,
                          icon: Icons.copy_rounded,
                          text:
                              'Copia cualquier enlace de TikTok, Instagram, Facebook, Spotify u otras plataformas soportadas — MediaKeep lo detectará y descargará automáticamente.',
                        ),

                        // Warning
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.amber.shade700,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.amber.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Esta función está en fase beta. Puede presentar inconsistencias. '
                                  'El monitoreo de portapapeles solo está disponible en Android.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.amber.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Action buttons
                        if (!kIsWeb && Platform.isAndroid) ...[
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.lock_open_rounded),
                              label: const Text('Solicitar permisos'),
                              onPressed: () async {
                                final storage =
                                    await PermissionService.requestStorageWithRationale(
                                      context,
                                    );
                                if (!context.mounted) return;
                                final notif =
                                    await PermissionService.requestNotificationWithRationale(
                                      context,
                                    );
                                setSheetState(
                                  () => _permissionsGranted = storage && notif,
                                );
                                if (_permissionsGranted) {
                                  _showToast('Permisos concedidos ✓');
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            icon: const Icon(Icons.check_rounded),
                            label: const Text('Activar'),
                            onPressed:
                                (!kIsWeb &&
                                    Platform.isAndroid &&
                                    !_permissionsGranted)
                                ? null // disabled until permissions granted
                                : () async {
                                    Navigator.pop(sheetCtx);
                                    await SettingsService.setAutoDownloadEnabled(
                                      true,
                                    );
                                    if (mounted) {
                                      setState(
                                        () => _autoDownloadEnabled = true,
                                      );
                                      _showToast(
                                        'Descargas automáticas activadas',
                                      );
                                    }
                                  },
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () => Navigator.pop(sheetCtx),
                            child: const Text('Cancelar'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildStep(
    BuildContext ctx, {
    required int number,
    required IconData icon,
    required String text,
  }) {
    final theme = Theme.of(ctx);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }

  Widget _buildAparienciaSection() => _buildSection(
    title: 'Apariencia',
    icon: Icons.palette,
    children: [
      _buildThemeOption('Modo claro', Icons.light_mode, ThemeMode.light),
      _buildThemeOption('Modo oscuro', Icons.dark_mode, ThemeMode.dark),
      _buildThemeOption(
        'Automático (sistema)',
        Icons.brightness_auto,
        ThemeMode.system,
      ),
    ],
  );

  Widget _buildCompartirSection() => _buildSection(
    title: 'Compartir',
    icon: Icons.share,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mensaje personalizado',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Ingresa tu mensaje...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _resetShareMessage,
                      tooltip: 'Restaurar por defecto',
                    ),
                    IconButton(
                      icon: const Icon(Icons.save),
                      onPressed: _saveShareMessage,
                      tooltip: 'Guardar',
                    ),
                  ],
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            Text(
              'Vista previa: ${_messageController.text}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _buildAlmacenamientoSection() => _buildSection(
    title: 'Almacenamiento',
    icon: Icons.folder,
    children: [
      ListTile(
        leading: const Icon(Icons.folder_open),
        title: const Text('Ubicación de descargas'),
        subtitle: const Text('MediaKeep/'),
        trailing: const Icon(Icons.chevron_right),
        onTap: _openDownloadsFolder,
      ),
    ],
  );

  Widget _buildFuncionesBetaSection() => _buildSection(
    title: 'Funciones Beta',
    icon: Icons.science_rounded,
    children: [
      SwitchListTile(
        secondary: const Icon(Icons.download_for_offline_rounded),
        title: const Text('Descargas automáticas'),
        subtitle: const Text(
          'Descarga automáticamente los enlaces que copies al portapapeles',
        ),
        value: _autoDownloadEnabled,
        onChanged: _toggleAutoDownload,
      ),
    ],
  );

  // Desktop-only Almacenamiento section: adds version + clear history
  // (replacing the Acerca de tab which is now accessible via sidebar).
  Widget _buildAlmacenamientoDesktopSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildAlmacenamientoSection(),
        const SizedBox(height: 24),
        _buildSection(
          title: 'Aplicación',
          icon: Icons.info_outline_rounded,
          children: [
            ListTile(
              leading: const Icon(Icons.code_rounded),
              title: const Text('Versión'),
              subtitle: Text(_appVersion),
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                Icons.delete_forever_rounded,
                color: theme.colorScheme.error,
              ),
              title: Text(
                'Limpiar historial',
                style: TextStyle(color: theme.colorScheme.error),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _clearHistory,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAcercaDeSection() => _buildSection(
    title: 'Acerca de',
    icon: Icons.info,
    children: [
      ListTile(
        leading: const Icon(Icons.new_releases),
        title: const Text('Novedades'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChangelogScreen()),
        ),
      ),
      ListTile(
        leading: const Icon(Icons.signal_cellular_alt),
        title: const Text('Estado del Sistema'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StatusScreen()),
        ),
      ),
      ListTile(
        leading: const Icon(Icons.privacy_tip),
        title: const Text('Privacidad'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PrivacyScreen()),
        ),
      ),
      ListTile(
        leading: const Icon(Icons.business),
        title: const Text('Autor'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AuthorScreen()),
        ),
      ),
      ListTile(
        leading: const Icon(Icons.code),
        title: const Text('Versión'),
        subtitle: Text(_appVersion),
      ),
      const Divider(),
      ListTile(
        leading: Icon(
          Icons.delete_forever,
          color: Theme.of(context).colorScheme.error,
        ),
        title: Text(
          'Limpiar historial',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: _clearHistory,
      ),
    ],
  );

  // ── Mobile: stacked list (original) ──────────────────────────────────────

  Widget _buildMobileBody() {
    return ListView(
      padding: Responsive.getContentPadding(context),
      children: [
        SafeArea(
          child: Column(
            children: [
              _buildAparienciaSection(),
              const SizedBox(height: 24),
              _buildCompartirSection(),
              const SizedBox(height: 24),
              _buildAlmacenamientoSection(),
              const SizedBox(height: 24),
              _buildFuncionesBetaSection(),
              const SizedBox(height: 24),
              _buildAcercaDeSection(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ],
    );
  }

  // ── Desktop: tab bar at top + scrollable content (NO secondary sidebar) ───

  Widget _buildDesktopBody() {
    final theme = Theme.of(context);
    final sections = [
      _buildAparienciaSection,
      _buildCompartirSection,
      () => _buildAlmacenamientoDesktopSection(theme),
      _buildFuncionesBetaSection,
    ];

    return DefaultTabController(
      length: _kSectionTitles.length,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header with title + horizontal tab bar ───────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(40, 32, 40, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Configuración',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  dividerColor: Colors.transparent,
                  tabs: List.generate(
                    _kSectionTitles.length,
                    (i) => Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_kSectionIcons[i], size: 16),
                          const SizedBox(width: 6),
                          Text(_kSectionTitles[i]),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
          // ── Tab content ───────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              children: sections.map((builder) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(40, 32, 40, 40),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: builder(),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveShellScaffold(
      title: 'Configuración',
      currentRoute: AppRoutes.settings,
      extendBodyBehindAppBar: true,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Responsive.isMobile(context)
          ? _buildMobileBody()
          : _buildDesktopBody(),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildThemeOption(String label, IconData icon, ThemeMode mode) {
    final isSelected = _currentThemeMode == mode;

    return RadioListTile<ThemeMode>(
      value: mode,
      groupValue: _currentThemeMode,
      onChanged: (value) {
        if (value != null) _updateThemeMode(value);
      },
      title: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
      selected: isSelected,
    );
  }
}
