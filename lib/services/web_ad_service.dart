// Web-specific helper for injecting a banner ad element
// This file is only used when compiling for the web; other platforms
// import a stub that contains no-op implementations.
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
// ignore: uri_does_not_exist
import 'dart:js_util' as js_util; // for calling global JS function

class WebAdService {
  static bool _initialized = false;

  /// Registers a view factory that creates an AdSense `<ins>` block. The
  /// caller should place a `HtmlElementView(viewType: 'ad-banner')` widget in
  /// the widget tree where the banner should appear.
  static void init() {
    if (_initialized) return;

    // Flutter web exposes a global `flutterPlatformViewRegistry` object
    // on the window; use JS interop to invoke its registerViewFactory method.
    final registry = js_util.getProperty(
      html.window,
      'flutterPlatformViewRegistry',
    );
    if (registry == null) {
      // nothing to register (maybe running under a non-web build or early startup)
      _initialized = true;
      return;
    }
    js_util.callMethod(registry, 'registerViewFactory', [
      'ad-banner',
      js_util.allowInterop((int viewId) {
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
      }),
    ]);

    _initialized = true;
  }
}
