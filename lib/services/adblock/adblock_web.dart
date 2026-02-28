import 'dart:js_interop';

@JS('isAdBlockActive')
external bool get isAdBlockActive;

Future<bool> verifyAdBlock() async {
  // En Web, leemos la variable global expuesta por index.html
  // tras la tentativa de carga de AdSense
  return isAdBlockActive;
}
