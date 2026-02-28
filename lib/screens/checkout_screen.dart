import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../services/ad_manager.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isLoading = false;
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
  }

  Future<void> _checkPremiumStatus() async {
    final isPrem = await AdManager.isPremium();
    if (mounted) {
      setState(() => _isPremium = isPrem);
    }
  }

  Future<void> _handleSubscription(String packageId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showToast('Por favor, inicia sesión primero.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.createCheckoutSession(packageId);

      if (response.success && response.data != null) {
        final initPoint = response.data?['init_point'] as String?;
        if (initPoint != null && initPoint.isNotEmpty) {
          final uri = Uri.parse(initPoint);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            _showToast('No se pudo abrir MercadoPago.', isError: true);
          }
        } else {
          _showToast('Error: Enlace de pago inválido.', isError: true);
        }
      } else {
        _showToast(
          response.errorMessage ?? 'Error al procesar pago',
          isError: true,
        );
      }
    } catch (e) {
      _showToast('Ocurrió un error inesperado.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isPremium) {
      return Scaffold(
        appBar: AppBar(title: const Text('Suscripción Premium')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star_rounded, color: Colors.amber, size: 80),
              const SizedBox(height: 24),
              Text(
                '¡Ya eres Premium!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Disfruta de descargas ilimitadas y sin publicidad.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Volver'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Actualizar a Premium')),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Generando enlace seguro...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.diamond_outlined,
                    size: 64,
                    color: Colors.blueAccent,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Mejora tu experiencia',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Descargas ilimitadas, sin anuncios comerciales y máxima prioridad en nuestros servidores.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 48),

                  // Pack 50 Descargas
                  _buildPlanCard(
                    context: context,
                    title: 'Pack 50 Descargas',
                    price: '\$15.00 MXN',
                    features: [
                      '50 enlaces de descarga sin anuncios',
                      'Alta velocidad',
                      'Sin caducidad (One-Time)',
                    ],
                    buttonText: 'Comprar Pack 50',
                    isPopular: false,
                    onTap: () => _handleSubscription('pack_50'),
                  ),

                  const SizedBox(height: 24),

                  // Pack 100 Descargas (Popular)
                  _buildPlanCard(
                    context: context,
                    title: 'Pack 100 Descargas',
                    price: '\$25.00 MXN',
                    features: [
                      'El doble por menos',
                      '100 enlaces de descarga sin anuncios',
                      'Ideal para uso frecuente',
                    ],
                    buttonText: 'Ahorrar con Pack 100',
                    isPopular: true,
                    onTap: () => _handleSubscription('pack_100'),
                  ),

                  const SizedBox(height: 24),

                  // Suscripción Premium
                  _buildPlanCard(
                    context: context,
                    title: 'Auralix Premium',
                    price: '\$49.00 MXN / Mes',
                    features: [
                      'Descargas ILIMITADAS todo el mes',
                      'Uso de Servidores Dedicados',
                      '0% Anuncios y Bloqueos',
                      'Cancela cuando quieras',
                    ],
                    buttonText: 'Suscribirse al Plan Mensual',
                    isPopular: false,
                    isGold: true,
                    onTap: () => _handleSubscription('sub_premium'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPlanCard({
    required BuildContext context,
    required String title,
    required String price,
    required List<String> features,
    required String buttonText,
    required VoidCallback onTap,
    bool isPopular = false,
    bool isGold = false,
  }) {
    final borderColor = isGold
        ? Colors.amber
        : (isPopular ? Colors.blueAccent : Colors.transparent);
    final primaryColor = isGold ? Colors.amber.shade700 : Colors.blueAccent;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: isPopular || isGold
            ? [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.1),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPopular || isGold)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isGold ? 'MEJOR VALOR' : 'MÁS POPULAR',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            price,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(f)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: (isPopular || isGold) ? primaryColor : null,
                foregroundColor: isGold ? Colors.black : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(buttonText),
            ),
          ),
        ],
      ),
    );
  }
}
