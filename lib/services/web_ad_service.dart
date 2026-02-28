// Web-specific helper for injecting a banner ad element
// This file is only used when compiling for the web; other platforms
// import a stub that contains no-op implementations.
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:ui' as ui; // for platformViewRegistry
// ignore: uri_does_not_exist
import 'dart:js_util' as js_util; // for calling global JS function

class WebAdService {
  static bool _initialized = false;

  /// Registers a view factory that creates an AdSense `<ins>` block. The
  /// caller should place a `HtmlElementView(viewType: 'ad-banner')` widget in
  /// the widget tree where the banner should appear.
  static void init() {
    if (_initialized) return;

    // Flutter web uses a `platformViewRegistry` to embed HTML elements.
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory('ad-banner', (int viewId) {
      final div = html.DivElement();
      div.style.width = '100%';
      div.style.textAlign = 'center';

      // appearance controlled by index.html script and AdSense configuration
      // the client ID and slot are stored as meta tags in index.html so
      // they can be changed without recompiling Dart code.
      // read publisher/slot from meta tags; fall back to known values
      // to make testing easier. The publisher ID below matches the one used in
      // index.html (ca-pub-1143269636112950).
      final client =
          html.document.head!
              .querySelector('meta[name="adsense-client"]')
              ?.getAttribute('content') ??
          'ca-pub-1143269636112950';
      final slot =
          html.document.head!
              .querySelector('meta[name="adsense-slot"]')
              ?.getAttribute('content') ??
          '1234567890';

      div.innerHtml =
          '<ins class="adsbygoogle" style="display:block" '
          'data-ad-client="$client" data-ad-slot="$slot" '
          'data-ad-format="auto" data-full-width-responsive="true"></ins>';

      // force rendering/push after element is added; use js_util because
      // Window doesn't expose callMethod.
      try {
        js_util.callMethod(html.window, 'pushAd', []);
      } catch (_) {
        // ignore - function may not exist if not configured yet
      }
      return div;
    });

    _initialized = true;
  }
}
