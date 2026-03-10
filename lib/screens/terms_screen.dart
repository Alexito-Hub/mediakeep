import 'package:flutter/material.dart';
import '../utils/responsive.dart';
import '../utils/app_routes.dart';
import '../widgets/layout/responsive_shell_scaffold.dart';

/// Terms of Use screen
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = !Responsive.isMobile(context);

    if (isDesktop) {
      return ResponsiveShellScaffold(
        title: 'Términos de Uso',
        currentRoute: AppRoutes.terms,
        body: SingleChildScrollView(
          padding: Responsive.kDesktop,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Términos de Uso',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildMainTermsCard(context),
                  const SizedBox(height: 24),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 3, child: _buildDisclaimerCard(context)),
                        const SizedBox(width: 16),
                        Expanded(flex: 1, child: _buildNoteCard(context)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return ResponsiveShellScaffold(
      title: 'Términos de Uso',
      currentRoute: AppRoutes.terms,
      extendBodyBehindAppBar: true,
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
                    _buildMainTermsCard(context),
                    const SizedBox(height: 16),
                    _buildDisclaimerCard(context),
                    const SizedBox(height: 16),
                    _buildNoteCard(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainTermsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Condiciones Generales',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildSection(
              context,
              'Propósito de la aplicación',
              'Media Keep es una herramienta técnica que facilita la descarga de contenido '
                  'multimedia disponible públicamente. Está diseñada estricta y únicamente para uso personal y privado.',
            ),
            const Divider(height: 32),
            _buildSection(
              context,
              'Uso aceptable',
              'Al utilizar Media Keep, te comprometes a:\n\n'
                  '• Descargar únicamente contenido del cual seas propietario o tengas permiso explícito del creador.\n'
                  '• Respetar las leyes de propiedad intelectual vigentes en tu país.\n'
                  '• No utilizar la aplicación para fines comerciales o de lucro.',
            ),
            const Divider(height: 32),
            _buildSection(
              context,
              'Restricciones explícitas',
              'Queda estrictamente prohibido el uso del contenido descargado para:\n\n'
                  '• Redistribución, publicación o retransmisión no autorizada.\n'
                  '• Remover marcas de agua o información de derechos de autor con fines de plagio.\n'
                  '• Crear contenido derivado sin la autorización pertinente.',
            ),
            const Divider(height: 32),
            _buildSection(
              context,
              'Actualizaciones',
              'Estos términos pueden ser modificados en el futuro. El uso continuo '
                  'de la aplicación implica la aceptación de cualquier actualización.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisclaimerCard(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Limitación de Responsabilidad',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Auralix Inc. y los desarrolladores de Media Keep proporcionan esta herramienta "tal cual" '
              'y no se hacen responsables del uso que los usuarios le den.\n\n'
              'Media Keep no aloja, posee ni tiene derechos sobre ningún contenido descargado '
              '(incluyendo contenido de TikTok, Instagram, Facebook, Spotify, etc.).\n\n'
              'Nos desligamos completamente de cualquier responsabilidad legal, mediática o penal '
              'derivada del mal uso de la herramienta. Eres enteramente responsable de tus descargas '
              'y de lo que decidas hacer con ellas.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteCard(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.gavel_rounded,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Al continuar utilizando esta aplicación, aceptas regirte por estos términos.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
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
