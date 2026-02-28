import 'package:flutter/material.dart';
import 'dart:ui_web' as ui_web;
import 'package:web/web.dart' as web;
import 'dart:js_interop';

@JS('pushAd')
external void pushAd();

Widget buildWebAd() {
  final viewId = 'adSenseView-${UniqueKey()}';

  ui_web.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
    final ins = web.document.createElement('ins') as web.HTMLElement;
    ins.className = 'adsbygoogle';
    ins.setAttribute('style', 'display:block; width:100%; height:100px;');
    ins.setAttribute('data-ad-client', 'ca-pub-3940256099942544');
    ins.setAttribute('data-ad-slot', '1234567890');
    ins.setAttribute('data-ad-format', 'auto');
    ins.setAttribute('data-full-width-responsive', 'true');

    Future.delayed(const Duration(milliseconds: 500), () {
      try {
        pushAd();
      } catch (e) {
        debugPrint('Failed to push AdSense: $e');
      }
    });

    return ins;
  });

  return Container(
    width: double.infinity,
    height: 100,
    color: Colors.transparent,
    child: HtmlElementView(viewType: viewId),
  );
}
