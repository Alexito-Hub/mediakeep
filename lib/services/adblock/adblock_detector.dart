import 'adblock_stub.dart' if (dart.library.js_interop) 'adblock_web.dart';

class AdBlockDetector {
  static Future<bool> isEnabled() async {
    return await verifyAdBlock();
  }
}
