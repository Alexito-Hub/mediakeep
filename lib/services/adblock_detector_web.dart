import 'dart:async';
import 'dart:js_interop';

@JS('window.adsbygoogle')
external JSObject? get adsByGoogle;

Future<bool> checkAdBlockWeb() async {
  // Give the DOM a tiny bit of time to let the ad script load in index.html
  await Future.delayed(const Duration(milliseconds: 1500));

  // If the adsbygoogle array is completely missing, the script was blocked
  final isBlocked = adsByGoogle == null;
  return isBlocked;
}
