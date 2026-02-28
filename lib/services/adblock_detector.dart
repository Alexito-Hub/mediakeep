import 'package:flutter/foundation.dart';
import 'dart:async';

// Conditionally import the web implementation
import 'adblock_detector_stub.dart'
    if (dart.library.js_interop) 'adblock_detector_web.dart';

class AdBlockDetector {
  /// Checks if an AdBlocker is enabled.
  /// Always returns false on non-web platforms.
  static Future<bool> hasAdBlock() async {
    if (!kIsWeb) return false;
    return checkAdBlockWeb();
  }
}
