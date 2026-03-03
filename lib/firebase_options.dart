import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform, debugPrint;

/// Platforms that have a Firebase plugin implementation.
bool get _isFirebaseSupported =>
    kIsWeb ||
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS;

Future initFirebase() async {
  if (!_isFirebaseSupported) {
    debugPrint('Firebase not supported on this platform, skipping init.');
    return;
  }
  if (Firebase.apps.isNotEmpty) return;

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyDXSJm4kmhZQ-WHYAZNxApPqzDC0yhprWQ",
        authDomain: "media-keep-e1636.firebaseapp.com",
        projectId: "media-keep-e1636",
        storageBucket: "media-keep-e1636.firebasestorage.app",
        messagingSenderId: "1073122313383",
        appId: "1:1073122313383:web:298bc84ca30fa3d3b1c782",
        measurementId: "G-Z8CNY1YELD",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
}
