import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ad_manager.dart';
import 'ads/web_ad_view.dart';

/// Cross-platform banner widget.
///
/// Usage: simply place `const AdBanner()` in your layout (e.g. as
/// `bottomNavigationBar`). It handles premium check, platform differences,
/// and automatically loads/disposes the mobile `BannerAd` instance.
class AdBanner extends StatefulWidget {
  /// Height in pixels for the banner. On web this is only a hint; the actual
  /// element may resize depending on AdSense configuration.
  final double height;

  const AdBanner({Key? key, this.height = 100}) : super(key: key);

  @override
  _AdBannerState createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();

    // only mobile needs to load an actual BannerAd object
    if (!kIsWeb) {
      AdManager.loadBanner(() {
        if (mounted) setState(() => _isLoaded = true);
      }).then((ad) {
        if (!mounted) return;
        setState(() => _bannerAd = ad);
      });
    } else {
      // ensure web service is initialised so the HtmlElementView is registered
      AdManager.loadBanner(() {});
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AdManager.isPremium(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(height: widget.height);
        }
        if (snapshot.hasData && snapshot.data == true) {
          return const SizedBox.shrink();
        }

        if (kIsWeb) {
          return SizedBox(
            height: widget.height,
            width: double.infinity,
            child: Center(child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 728),
              child: WebAdView(),
            )),
          );
        }

        if (_isLoaded && _bannerAd != null) {
          return SafeArea(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              width: double.infinity,
              height: _bannerAd!.size.height.toDouble(),
              alignment: Alignment.center,
              child: SizedBox(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
            ),
          );
        }

        return SizedBox(height: widget.height);
      },
    );
  }
}
