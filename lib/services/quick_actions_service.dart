import 'package:flutter/foundation.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:flutter/material.dart';

/// Servicio para manejar accesos directos de la app
class QuickActionsService {
  final QuickActions quickActions = const QuickActions();

  /// Verifica si las acciones rápidas son soportadas
  bool get isSupported {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Inicializa los accesos directos de la aplicación
  void initialize(BuildContext context, Function(String) onActionPressed) {
    if (!isSupported) return;

    try {
      // Definir los accesos directos (solo Historial y Configuración)
      quickActions.setShortcutItems(<ShortcutItem>[
        const ShortcutItem(
          type: 'action_history',
          localizedTitle: 'Historial de Descargas',
          icon: 'ic_history',
        ),
        const ShortcutItem(
          type: 'action_settings',
          localizedTitle: 'Configuración',
          icon: 'ic_settings',
        ),
      ]);

      // Manejar cuando se presiona un acceso directo
      quickActions.initialize((String shortcutType) {
        onActionPressed(shortcutType);
      });
    } catch (e) {
      debugPrint('Error initializing QuickActions: $e');
    }
  }

  /// Cierra las acciones rápidas
  void dispose() {
    quickActions.clearShortcutItems();
  }
}
