// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';

/// Service for handling storage and media permissions, including
/// user-facing rationale dialogs shown BEFORE the OS prompt.
class PermissionService {
  // ─── Rationale dialog ────────────────────────────────────────────────────

  /// Shows a rationale dialog and returns [true] if the user tapped "Continuar".
  static Future<bool> _showRationale(
    BuildContext context, {
    required String title,
    required String reason,
    required IconData icon,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: Icon(icon, size: 40),
        title: Text(title, textAlign: TextAlign.center),
        content: Text(reason, textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Ahora no'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
    return result == true;
  }

  // ─── Storage ─────────────────────────────────────────────────────────────

  /// Requests storage permissions, showing a rationale dialog first.
  static Future<bool> requestStorageWithRationale(BuildContext context) async {
    if (kIsWeb) return true;
    if (!Platform.isAndroid) return true;

    // Skip rationale if already granted
    if (await _isStorageGranted()) return true;

    final dialogContext = context;
    final ok = await _showRationale(
      dialogContext,
      icon: Icons.folder_rounded,
      title: 'Acceso al almacenamiento',
      reason:
          'MediaKeep necesita guardar los archivos descargados en tu dispositivo. '
          'Sin este permiso las descargas no podrán completarse.',
    );
    if (!ok) return false;

    return _requestAndroidPermissions();
  }

  /// Silent version (no rationale) — used internally.
  static Future<bool> requestStoragePermissions() async {
    if (kIsWeb) return true;
    if (Platform.isAndroid) return await _requestAndroidPermissions();
    return true;
  }

  // ─── Notifications ────────────────────────────────────────────────────────

  /// Requests notification permissions, showing a rationale dialog first.
  static Future<bool> requestNotificationWithRationale(
    BuildContext context,
  ) async {
    if (kIsWeb) return true;
    if (!Platform.isAndroid) return true;

    if (await Permission.notification.isGranted) return true;

    final dialogContext = context;
    final ok = await _showRationale(
      dialogContext,
      icon: Icons.notifications_rounded,
      title: 'Notificaciones',
      reason:
          'MediaKeep usa notificaciones para informarte cuando una descarga '
          'ha finalizado o si ocurre algún error.',
    );
    if (!ok) return false;

    final status = await Permission.notification.request();
    return status.isGranted;
  }

  static Future<bool> requestNotificationPermissions() async {
    if (kIsWeb) return true;
    if (Platform.isAndroid) {
      if (await Permission.notification.isDenied) {
        final status = await Permission.notification.request();
        return status.isGranted;
      }
      return await Permission.notification.isGranted;
    }
    return true;
  }

  // ─── All permissions (with rationale) ────────────────────────────────────

  /// Requests all required permissions, showing rationale dialogs first.
  /// Call this after the first frame renders (addPostFrameCallback).
  static Future<void> requestAllPermissionsWithRationale(
    BuildContext context,
  ) async {
    if (kIsWeb) return;
    if (!Platform.isAndroid) return;

    await requestStorageWithRationale(context);
    if (!context.mounted) return;
    await requestNotificationWithRationale(context);
  }

  /// Requests all necessary permissions silently (no dialogs).
  static Future<void> requestAllPermissions() async {
    await requestStoragePermissions();
    await requestNotificationPermissions();

    if (kIsWeb) return;
    if (Platform.isAndroid) {
      if (await Permission.systemAlertWindow.isDenied) {
        await Permission.systemAlertWindow.request();
      }
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  static Future<bool> _isStorageGranted() async {
    return await Permission.storage.isGranted ||
        await Permission.photos.isGranted ||
        await Permission.videos.isGranted ||
        await Permission.audio.isGranted;
  }

  static Future<bool> _requestAndroidPermissions() async {
    if (await _isStorageGranted()) return true;

    final statuses = await [
      Permission.storage,
      Permission.photos,
      Permission.videos,
      Permission.audio,
    ].request();

    return statuses[Permission.storage]?.isGranted == true ||
        statuses[Permission.photos]?.isGranted == true ||
        statuses[Permission.videos]?.isGranted == true ||
        statuses[Permission.audio]?.isGranted == true;
  }
}
