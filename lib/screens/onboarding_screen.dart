import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/settings_service.dart';
import 'privacy_screen.dart';
import 'terms_screen.dart';
import 'download_screen.dart';

/// Onboarding Screen with multiple steps (Welcome/Legal, Storage, Notifications, Done)
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _acceptedLegal = false;

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _finishOnboarding() async {
    await SettingsService.completeOnboarding();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DownloadScreen()),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Top progress dots
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics:
                    const NeverScrollableScrollPhysics(), // Prevent manual swipe
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  _buildWelcomePage(),
                  _buildStoragePage(),
                  _buildNotificationsPage(),
                  _buildDonePage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Shared UI Helpers ───────────────────────────────────────────────────

  Widget _buildPageTemplate({
    required IconData icon,
    required String title,
    required String description,
    required Widget bottomContent,
  }) {
    // Add max bounds for desktop/tablet
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(
                icon,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 32),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              bottomContent,
            ],
          ),
        ),
      ),
    );
  }

  // ─── Step 1: Welcome & Legal ─────────────────────────────────────────────

  Widget _buildWelcomePage() {
    return _buildPageTemplate(
      icon: Icons.rocket_launch_rounded,
      title: 'Bienvenido a\nMedia Keep',
      description:
          'Descarga contenido de tus redes favoritas de forma rápida y sencilla.',
      bottomContent: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Checkbox(
                value: _acceptedLegal,
                onChanged: (val) =>
                    setState(() => _acceptedLegal = val ?? false),
              ),
              Expanded(
                child: Wrap(
                  children: [
                    const Text('He leído y acepto los '),
                    InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TermsScreen()),
                      ),
                      child: Text(
                        'Términos de Uso',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Text(' y la '),
                    InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PrivacyScreen(),
                        ),
                      ),
                      child: Text(
                        'Política de Privacidad',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Text('.'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _acceptedLegal ? _nextPage : null,
            child: const Text('Comenzar', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  // ─── Step 2: Storage Permission ──────────────────────────────────────────

  Widget _buildStoragePage() {
    final needsStorage = !kIsWeb && Platform.isAndroid;

    return _buildPageTemplate(
      icon: Icons.folder_rounded,
      title: 'Almacenamiento',
      description:
          'Media Keep necesita acceso a tu dispositivo para guardar los archivos descargados.',
      bottomContent: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (needsStorage) ...[
            FilledButton.icon(
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text(
                'Conceder Permiso',
                style: TextStyle(fontSize: 16),
              ),
              onPressed: () async {
                final status = await Permission.storage.request();
                final photos = await Permission.photos.request();
                final videos = await Permission.videos.request();

                // On Android 13+ storage is split into photos/videos
                if (status.isGranted ||
                    (photos.isGranted && videos.isGranted)) {
                  _nextPage();
                } else {
                  if (mounted) {
                    _showRequiredPermissionDialog('Almacenamiento');
                  }
                }
              },
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                if (mounted) {
                  _showRequiredPermissionDialog('Almacenamiento');
                }
              },
              child: const Text('Omitir'),
            ),
          ] else ...[
            FilledButton(
              onPressed: _nextPage,
              child: const Text('Continuar', style: TextStyle(fontSize: 16)),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Step 3: Notifications Permission ────────────────────────────────────

  Widget _buildNotificationsPage() {
    final needsNotifs = !kIsWeb && Platform.isAndroid;

    return _buildPageTemplate(
      icon: Icons.notifications_active_rounded,
      title: 'Notificaciones',
      description:
          'Te avisaremos cuando tus descargas finalicen o si ocurre algún error.',
      bottomContent: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (needsNotifs) ...[
            FilledButton.icon(
              icon: const Icon(Icons.notifications_rounded),
              label: const Text(
                'Habilitar Notificaciones',
                style: TextStyle(fontSize: 16),
              ),
              onPressed: () async {
                await Permission.notification.request();
                _nextPage();
              },
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                // Notificaciones NO son estrictamente obligatorias para funcionar
                _nextPage();
              },
              child: const Text('Omitir'),
            ),
          ] else ...[
            FilledButton(
              onPressed: _nextPage,
              child: const Text('Continuar', style: TextStyle(fontSize: 16)),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Step 4: All Set ───────────────────────────────────────────────────────

  Widget _buildDonePage() {
    return _buildPageTemplate(
      icon: Icons.check_circle_rounded,
      title: '¡Todo listo!',
      description:
          'Ya puedes empezar a descargar tu contenido favorito sin límites.',
      bottomContent: FilledButton(
        onPressed: _finishOnboarding,
        child: const Text(
          'Entrar a la aplicación',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  // ─── Dialogs ─────────────────────────────────────────────────────────────

  void _showRequiredPermissionDialog(String permissionName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Permiso Requerido: $permissionName'),
        content: const Text(
          'Media Keep no puede funcionar correctamente sin este permiso. Si no lo aceptas, la aplicación no podrá guardar tus descargas y tendrá que cerrarse.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              SystemChannels.platform.invokeMethod(
                'SystemNavigator.pop',
              ); // Close app
            },
            child: const Text(
              'Cerrar App',
              style: TextStyle(color: Colors.red),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              // Let user retry
            },
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
