import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/responsive.dart';
import '../utils/app_routes.dart';
import '../widgets/layout/responsive_shell_scaffold.dart';

/// About author screen
class AuthorScreen extends StatelessWidget {
  const AuthorScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  Widget _buildDesktopBody(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: Responsive.kDesktop,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Acerca del Autor',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: avatar + links
                  SizedBox(
                    width: 300,
                    child: Column(
                      children: [
                        _buildAvatarCard(context),
                        const SizedBox(height: 16),
                        _buildLinksCard(context),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Right: about + chips + tagline
                  Expanded(
                    child: Column(
                      children: [
                        _buildAboutCard(context),
                        const SizedBox(height: 16),
                        _buildTaglineCard(context),
                      ],
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

  Widget _buildAvatarCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.business,
                size: 50,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Auralix Inc',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Desarrollando soluciones innovadoras',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinksCard(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.web),
            title: const Text('Sitio Web'),
            subtitle: const Text('auralixpe.xyz'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => _launchUrl('https://auralixpe.xyz'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('Contacto'),
            subtitle: const Text('support@auralixpe.xyz'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => _launchUrl('mailto:support@auralixpe.xyz'),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Media Keep',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Una herramienta gratuita y de código abierto para descargar contenido '
              'de tus plataformas sociales favoritas sin marcas de agua.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFeatureChip(context, 'Sin anuncios'),
                _buildFeatureChip(context, 'Sin marca de agua'),
                _buildFeatureChip(context, 'Gratis'),
                _buildFeatureChip(context, 'Open Source'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaglineCard(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.favorite,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Hecho con ❤️ por Auralix Inc',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!Responsive.isMobile(context)) {
      return ResponsiveShellScaffold(
        title: 'Acerca del Autor',
        currentRoute: AppRoutes.author,
        body: _buildDesktopBody(context),
      );
    }

    return ResponsiveShellScaffold(
      title: 'Acerca del Autor',
      currentRoute: AppRoutes.author,
      extendBodyBehindAppBar: true,
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Responsive.value(
              context,
              mobile: double.infinity,
              tablet: 700,
              desktop: 800,
            ),
          ),
          child: ListView(
            padding: Responsive.getContentPadding(context),
            children: [
              SafeArea(
                child: Column(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.business,
                                size: 50,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Auralix Inc',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Desarrollando soluciones innovadoras',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.web),
                            title: const Text('Sitio Web'),
                            subtitle: const Text('auralixpe.xyz'),
                            trailing: const Icon(Icons.open_in_new),
                            onTap: () => _launchUrl('https://auralixpe.xyz'),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.email),
                            title: const Text('Contacto'),
                            subtitle: const Text('support@auralixpe.xyz'),
                            trailing: const Icon(Icons.open_in_new),
                            onTap: () =>
                                _launchUrl('mailto:support@auralixpe.xyz'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Media Keep',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Una herramienta gratuita y de código abierto para descargar contenido '
                              'de tus plataformas sociales favoritas sin marcas de agua.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildFeatureChip(context, 'Sin anuncios'),
                                _buildFeatureChip(context, 'Sin marca de agua'),
                                _buildFeatureChip(context, 'Gratis'),
                                _buildFeatureChip(context, 'Open Source'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.favorite,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSecondaryContainer,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Hecho con amor por Auralix Inc',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSecondaryContainer,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildFeatureChip(BuildContext context, String label) {
    return Chip(
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 12,
        color: Theme.of(context).colorScheme.onSecondaryContainer,
      ),
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      side: BorderSide.none,
    );
  }
}
