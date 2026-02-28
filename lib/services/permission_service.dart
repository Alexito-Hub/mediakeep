import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';

/// Service for handling storage and media permissions
class PermissionService {
  /// Requests necessary storage permissions based on platform
  static Future<bool> requestStoragePermissions() async {
    if (kIsWeb) {
      return true; // Web doesn't need permissions
    }

    if (Platform.isAndroid) {
      return await _requestAndroidPermissions();
    } else if (Platform.isIOS) {
      return true; // iOS handles this automatically
    } else {
      return true; // Desktop platforms
    }
  }

  /// Requests notification permissions (Android 13+)
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

  /// Requests all necessary permissions for the app to function correctly
  static Future<void> requestAllPermissions() async {
    await requestStoragePermissions();
    await requestNotificationPermissions();

    if (kIsWeb) return;

    if (Platform.isAndroid) {
      // Request overlay permission for background clipboard access
      if (await Permission.systemAlertWindow.isDenied) {
        await Permission.systemAlertWindow.request();
      }
    }
  }

  /// Requests Android-specific storage permissions
  static Future<bool> _requestAndroidPermissions() async {
    final storageStatus = await Permission.storage.status;
    final photosStatus = await Permission.photos.status;
    final videosStatus = await Permission.videos.status;
    final audioStatus = await Permission.audio.status;

    // Check if any permission is already granted
    if (storageStatus.isGranted ||
        photosStatus.isGranted ||
        videosStatus.isGranted ||
        audioStatus.isGranted) {
      return true;
    }

    // Request permissions
    Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
      Permission.photos,
      Permission.videos,
      Permission.audio,
    ].request();

    // Check if any of the requested permissions were granted
    return statuses[Permission.storage]?.isGranted == true ||
        statuses[Permission.photos]?.isGranted == true ||
        statuses[Permission.videos]?.isGranted == true ||
        statuses[Permission.audio]?.isGranted == true;
  }
}
