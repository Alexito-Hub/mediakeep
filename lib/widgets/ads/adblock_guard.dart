import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'dart:async';
import '../../services/adblock/adblock_detector.dart';
import '../../services/ad_manager.dart';

class AdBlockGuard extends StatefulWidget {
  final Widget child;
  const AdBlockGuard({super.key, required this.child});

  @override
  State<AdBlockGuard> createState() => _AdBlockGuardState();
}

class _AdBlockGuardState extends State<AdBlockGuard> {
  bool _adBlockDetected = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Only run ad-block detection on platforms that actually serve ads.
    if (!_adSupportedPlatform) return;
    _checkAdBlock();
    // Vigilancia constante cada 3 segundos
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _checkAdBlock());
  }

  /// Returns true only on platforms where Google Mobile Ads / AdSense are used.
  bool get _adSupportedPlatform {
    if (kIsWeb) return true;
    if (defaultTargetPlatform == TargetPlatform.android) return true;
    if (defaultTargetPlatform == TargetPlatform.iOS) return true;
    return false;
  }

  Future<void> _checkAdBlock() async {
    // Si somos Premium, ignoramos todo
    if (await AdManager.isPremium()) {
      if (_adBlockDetected) setState(() => _adBlockDetected = false);
      return;
    }

    final detected = await AdBlockDetector.isEnabled();
    if (detected && !_adBlockDetected && mounted) {
      setState(() => _adBlockDetected = true);
    } else if (!detected && _adBlockDetected && mounted) {
      setState(() => _adBlockDetected = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_adBlockDetected) {
      return Theme(
        data: ThemeData.dark(useMaterial3: true),
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 40.0,
                vertical: 24.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.warning_rounded,
                    color: Colors.amberAccent,
                    size: 100,
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'AdBlocker Detectado',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'MediaKeep se mantiene gratuito gracias a los anuncios publicitarios.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Por favor desactiva tu bloqueador o cambia a una cuenta Premium para navegar sin interrupciones.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.white54),
                  ),
                  const SizedBox(height: 48),
                  FilledButton.icon(
                    onPressed: () {
                      _checkAdBlock();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Verificando conexión...'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Ya lo desactivé, reintentar'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.amberAccent.shade700,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return widget.child;
  }
}
