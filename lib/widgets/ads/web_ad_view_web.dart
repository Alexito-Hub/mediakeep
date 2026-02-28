import 'package:flutter/material.dart';
import 'dart:ui_web' as ui_web;
import 'package:web/web.dart' as web;
import 'dart:js_interop';

@JS('pushAd')
external void pushAd();

/// Create a banner ad view using the meta tags defined in `web/index.html`.
///
/// The `<meta name="adsense-client" ...>` and `<meta name="adsense-slot"`
/// tags are read at runtime so you can change the values without recompiling
/// Dart. This mirrors the approach used by `WebAdService` elsewhere in the
/// project.
Widget buildWebAd() {
  final viewId = 'adSenseView-${UniqueKey()}';

  ui_web.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
    final ins = web.document.createElement('ins') as web.HTMLElement;
    ins.className = 'adsbygoogle';
    ins.setAttribute('style', 'display:block; width:100%; height:100px;');

    // read configuration from meta tags; fallback to known test IDs if not
    // present so development still works.
    final client = web.document
            .querySelector('meta[name="adsense-client"]')
            ?.getAttribute('content')
            ?? 'ca-pub-3940256099942544';
    final slot = web.document
            .querySelector('meta[name="adsense-slot"]')
            ?.getAttribute('content')
            ?? '1234567890';

    ins.setAttribute('data-ad-client', client);
    ins.setAttribute('data-ad-slot', slot);
    ins.setAttribute('data-ad-format', 'auto');
    ins.setAttribute('data-full-width-responsive', 'true');

    // give the element a moment to attach before pushing the ad.
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
