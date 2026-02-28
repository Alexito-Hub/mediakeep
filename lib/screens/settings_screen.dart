// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../services/history_service.dart';
import '../services/app_version_service.dart';
import '../main.dart';

import '../utils/responsive.dart';
import 'privacy_screen.dart';
import 'author_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'status_screen.dart';
import 'changelog_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import 'auth_screen.dart';
import 'checkout_screen.dart';

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
  String _appVersion = 'Cargando...';
  User? _currentUser;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted) {
        setState(() => _currentUser = user);
        if (user != null) {
          _fetchUserData();
        } else {
          setState(() => _userData = null);
        }
      }
    });
  }

  Future<void> _fetchUserData() async {
    FirestoreService.getUserDataStream().listen((snapshot) {
      if (mounted && snapshot != null && snapshot.exists) {
        setState(() => _userData = snapshot.data());
      }
    });
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

    setState(() {
      _currentThemeMode = themeMode;
      _messageController.text = shareMessage;
      _appVersion = version;
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

  Future<void> _handleAuthAction() async {
    if (_currentUser == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cerrar sesión'),
          content: const Text('¿Estás seguro de que deseas salir?'),
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
              child: const Text('Salir'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await FirebaseAuth.instance.signOut();
        _showToast('Sesión cerrada');
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('Configuración')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: Responsive.value(
                    context,
                    mobile: double.infinity,
                    tablet: 900,
                    desktop: 1100,
                  ),
                ),
                child: ListView(
                  padding: Responsive.getContentPadding(context),
                  children: [
                    SafeArea(
                      child: Column(
                        children: [
                          _buildSection(
                            title: 'Apariencia',
                            icon: Icons.palette,
                            children: [
                              _buildThemeOption(
                                'Modo claro',
                                Icons.light_mode,
                                ThemeMode.light,
                              ),
                              _buildThemeOption(
                                'Modo oscuro',
                                Icons.dark_mode,
                                ThemeMode.dark,
                              ),
                              _buildThemeOption(
                                'Automático (sistema)',
                                Icons.brightness_auto,
                                ThemeMode.system,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildSection(
                            title: 'Cuenta',
                            icon: Icons.person,
                            children: [
                              if (_currentUser != null) ...[
                                ListTile(
                                  leading: const Icon(Icons.email),
                                  title: Text(_currentUser!.email ?? 'Usuario'),
                                  subtitle: Text(
                                    'Plan: ${_userData?['plan']?.toString().toUpperCase() ?? 'GRATIS'}',
                                  ),
                                ),
                                if (_userData != null) ...[
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    child: LinearProgressIndicator(
                                      value:
                                          (_userData!['requestsCount'] ?? 0) /
                                          (_userData!['totalLimit'] ?? 10),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Descargas usadas: ${_userData!['requestsCount'] ?? 0} / ${_userData!['totalLimit'] ?? 10}',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const CheckoutScreen(),
                                              ),
                                            );
                                          },
                                          child: Text(
                                            _userData!['plan'] == 'premium'
                                                ? 'Ver Suscripción'
                                                : 'MÁS DESCARGAS',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                              ListTile(
                                leading: Icon(
                                  _currentUser == null
                                      ? Icons.login
                                      : Icons.logout,
                                ),
                                title: Text(
                                  _currentUser == null
                                      ? 'Iniciar Sesión / Registro'
                                      : 'Cerrar Sesión',
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: _handleAuthAction,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildSection(
                            title: 'Compartir',
                            icon: Icons.share,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Mensaje personalizado',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: _messageController,
                                      onChanged: (_) => setState(() {}),
                                      decoration: InputDecoration(
                                        hintText: 'Ingresa tu mensaje...',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
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
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.outline,
                                            fontStyle: FontStyle.italic,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildSection(
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
                          ),
                          const SizedBox(height: 24),
                          _buildSection(
                            title: 'Acerca de',
                            icon: Icons.info,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.new_releases),
                                title: const Text('Novedades'),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ChangelogScreen(),
                                    ),
                                  );
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.signal_cellular_alt),
                                title: const Text('Estado del Sistema'),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const StatusScreen(),
                                    ),
                                  );
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.privacy_tip),
                                title: const Text('Privacidad'),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const PrivacyScreen(),
                                    ),
                                  );
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.business),
                                title: const Text('Autor'),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const AuthorScreen(),
                                    ),
                                  );
                                },
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
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: _clearHistory,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
