import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ad_manager.dart';
import 'ads/web_ad_view.dart';

/// Cross-platform banner widget.
///
/// - **Android / iOS**: loads a Google Mobile Ads BannerAd.
/// - **Web**: renders an AdSense slot via [WebAdView] / HtmlElementView.
/// - **Linux / Windows / macOS**: hidden (SizedBox.shrink) — no ad SDK.
///
/// Usage: simply place `const AdBanner()` anywhere in your layout.
class AdBanner extends StatefulWidget {
  final double height;
  const AdBanner({super.key, this.height = 100});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    // Only Android and iOS have the google_mobile_ads plugin.
    if (!AdManager.isMobileAds) return;
    AdManager.loadBanner(() {
      if (mounted) setState(() => _isLoaded = true);
    }).then((ad) {
      if (!mounted) return;
      setState(() => _bannerAd = ad);
    });
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Desktop platforms (Linux, Windows, macOS) — no ads, no empty gap.
    if (!kIsWeb && !AdManager.isMobileAds) return const SizedBox.shrink();

    return FutureBuilder<bool>(
      future: AdManager.isPremium(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(height: widget.height);
        }
        // Premium users see nothing.
        if (snapshot.data == true) return const SizedBox.shrink();

        // ── Web: AdSense via HtmlElementView ────────────────────────────────
        if (kIsWeb) {
          return SizedBox(
            height: widget.height,
            width: double.infinity,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 728),
                child: const WebAdView(),
              ),
            ),
          );
        }

        // ── Android / iOS: Google Mobile Ads banner ──────────────────────────
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

        // Banner not yet loaded — reserve space so layout doesn't jump.
        return SizedBox(height: widget.height);
      },
    );
  }
}
