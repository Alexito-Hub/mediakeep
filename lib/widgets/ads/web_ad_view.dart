import 'package:flutter/material.dart';
import '../../services/ad_manager.dart';
import 'web_ad_view_stub.dart'
    if (dart.library.js_interop) 'web_ad_view_web.dart';

class WebAdView extends StatelessWidget {
  const WebAdView({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AdManager.isPremium(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 100);
        }
        if (snapshot.hasData && snapshot.data == true) {
          return const SizedBox.shrink();
        }
        return buildWebAd();
      },
    );
  }
}
