import 'package:flutter/material.dart';
import '../utils/responsive.dart';

/// Privacy policy screen
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('Política de Privacidad')),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Responsive.value(
              context,
              mobile: double.infinity,
              tablet: 800,
              desktop: 900,
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
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tu privacidad es importante',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            _buildSection(
                              context,
                              'Recopilación de datos',
                              'Media Keep NO recopila, almacena ni comparte ningún dato personal. '
                                  'Toda la información se procesa localmente en tu dispositivo.',
                            ),
                            const Divider(height: 32),
                            _buildSection(
                              context,
                              'Permisos',
                              'Media Keep solicita permisos de almacenamiento únicamente para guardar '
                                  'los archivos descargados en tu dispositivo. No se accede a ningún otro dato.',
                            ),
                            const Divider(height: 32),
                            _buildSection(
                              context,
                              'Almacenamiento local',
                              'Los archivos descargados se guardan en la carpeta "Media Keep" de tu dispositivo. '
                                  'El historial de descargas se almacena localmente y puedes eliminarlo en cualquier momento.',
                            ),
                            const Divider(height: 32),
                            _buildSection(
                              context,
                              'Conexiones externas',
                              'Media Keep se conecta a servicios de terceros (TikTok, Facebook, Spotify, Threads) '
                                  'únicamente para obtener el contenido que solicitas descargar. No compartimos tu información con estos servicios.',
                            ),
                            const Divider(height: 32),
                            _buildSection(
                              context,
                              'Actualizaciones',
                              'Esta política de privacidad puede actualizarse ocasionalmente. '
                                  'Te notificaremos de cualquier cambio significativo.',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.copyright,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onErrorContainer,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Descargo de Responsabilidad - Derechos de Autor',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onErrorContainer,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '© 2024-2025 Media Keep por Auralix Inc. Todos los derechos reservados.\n\n'
                              'IMPORTANTE: Media Keep es una herramienta de descarga diseñada ÚNICAMENTE para uso personal y privado. '
                              'Los usuarios son completamente responsables de:\n\n'
                              '• Respetar las leyes de derechos de autor de su jurisdicción\n'
                              '• Descargar solo contenido propio o con permiso explícito del autor\n'
                              '• NO redistribuir, vender o usar comercialmente contenido descargado\n'
                              '• NO remover marcas de agua o créditos del autor original\n\n'
                              'Media Keep NO afirma propiedad sobre ningún contenido descargado de terceros (TikTok, Instagram, Facebook, Spotify, Threads). '
                              'Todo el contenido descargado pertenece a sus respectivos creadores y está protegido por derechos de autor.\n\n'
                              'El uso indebido de esta herramienta puede resultar en consecuencias legales. '
                              'Media Keep y Auralix Inc. NO son responsables del mal uso de esta aplicación. '
                              'Al usar Media Keep, aceptas cumplir con todas las leyes aplicables de propiedad intelectual.',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onErrorContainer,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Media Keep respeta tu privacidad. Sin anuncios, sin rastreo, sin venta de datos.',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
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

  Widget _buildSection(BuildContext context, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(content, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
