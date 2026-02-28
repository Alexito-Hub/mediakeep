import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

// This widget only renders on Web; on other platforms it returns an empty
// SizedBox. The actual element is registered by WebAdService when the
// application boots.

class WebBannerAd extends StatelessWidget {
  const WebBannerAd({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return const SizedBox.shrink();

    // The viewType string must match the one registered in WebAdService.
    return const HtmlElementView(viewType: 'ad-banner');
  }
}
