// Platform detection: use Flutter's foundation APIs instead of dart:io so web compile succeeds
import 'package:flutter/foundation.dart'
    show
        kIsWeb,
        defaultTargetPlatform,
        TargetPlatform,
        debugPrint,
        VoidCallback;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart' as firebase_core;
import 'package:cloud_firestore/cloud_firestore.dart';

class AdManager {
  static InterstitialAd? _interstitialAd;
  static int _numInterstitialLoadAttempts = 0;
  static const int maxFailedLoadAttempts = 3;

  /// True only on platforms where the google_mobile_ads plugin is available.
  static bool get isMobileAds =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  // Private alias kept for internal use.
  static bool get _isMobileAds => isMobileAds;

  /// Retorna si el usuario está actualmente activo bajo una suscripción/compra Premium.
  /// Los usuarios Premium reciben un "bypass" nativo que neutraliza todas las llamadas a anuncios.
  static Future<bool> isPremium() async {
    // Si la plataforma actual no soporta GoogleMobileAds (Ej: Web/Windows), evitamos renderizado.
    // Aunque en Web usamos AdSense, el flag de isPremium se reutiliza.

    // Guard: if Firebase hasn't been initialised (e.g. Linux desktop), bail out.
    try {
      if (firebase_core.Firebase.apps.isEmpty) return false;
    } catch (_) {
      return false;
    }

    final User? user;
    try {
      user = FirebaseAuth.instance.currentUser;
    } catch (_) {
      return false;
    }
    if (user != null) {
      // Verificamos el plan
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists && doc.data()?['plan'] == 'premium') {
          return true;
        }
      } on FirebaseException catch (e) {
        debugPrint('Error getting premium status: $e');
        if (e.code == 'permission-denied') {
          // Authentication token might be invalid; sign out to force re-login
          await FirebaseAuth.instance.signOut();
          debugPrint(
            'Signed out due to permission error, user must reauthenticate',
          );
        }
      } catch (e) {
        debugPrint('Error getting premium status: $e');
      }
    }
    return false; // Gratis / Unauth -> Mostramos anuncios
  }

  /// TEST UNIT IDs: Replace with real IDs on Production
  static String get bannerAdUnitId {
    if (kIsWeb) {
      return ''; // Banners in Web are handled via WebAdView separately
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'ca-app-pub-4579298756868487/3183415422'; // AnunciosMediaB
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'ca-app-pub-4579298756868487/3183415422';
    }
    return '';
  }

  static String get interstitialAdUnitId {
    if (kIsWeb) return '';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'ca-app-pub-4579298756868487/3510718482'; // AdsMediaI
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'ca-app-pub-4579298756868487/3510718482';
    }
    return '';
  }

  /// Instancia un banner y exige un callback estricto cuando termine de cargar
  /// para inyectarlo en el árbol de widgets de forma segura.
  static Future<BannerAd?> loadBanner(VoidCallback onLoaded) async {
    // Plugin not available on web or desktop — those platforms are handled
    // by WebAdView (AdSense) and with no ads respectively.
    if (!_isMobileAds) return null;

    if (await isPremium()) return null; // Bypass

    final banner = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          debugPrint('BannerAd loaded.');
          onLoaded();
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          debugPrint('BannerAd failed to load: $error');
          ad.dispose();
        },
      ),
    );

    banner.load();
    return banner;
  }

  /// Carga y mantiene en memoria un anuncio a pantalla completa
  /// para ser invocado sin latencia cuando se requiera.
  static Future<void> createInterstitialAd() async {
    // plugin not supported on web or desktop
    if (!_isMobileAds) return;
    if (await isPremium()) return; // Bypass

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          debugPrint('$ad loaded');
          _interstitialAd = ad;
          _numInterstitialLoadAttempts = 0;
          _interstitialAd!.setImmersiveMode(true);
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('InterstitialAd failed to load: $error.');
          _numInterstitialLoadAttempts += 1;
          _interstitialAd = null;
          if (_numInterstitialLoadAttempts < maxFailedLoadAttempts) {
            createInterstitialAd();
          }
        },
      ),
    );
  }

  static AppOpenAd? _appOpenAd;
  static bool _isShowingAd = false;
  static DateTime? _appOpenLoadTime;

  static String get appOpenAdUnitId {
    if (kIsWeb) return '';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'ca-app-pub-4579298756868487/6168671412'; // AnunciosMediaAA
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'ca-app-pub-4579298756868487/6168671412';
    }
    return '';
  }

  /// Carga el anuncio App Open en memoria
  static Future<void> loadAppOpenAd() async {
    if (!_isMobileAds) return; // only Android / iOS
    if (await isPremium()) return;

    AppOpenAd.load(
      adUnitId: appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('AppOpenAd loaded');
          _appOpenAd = ad;
          _appOpenLoadTime = DateTime.now();
        },
        onAdFailedToLoad: (error) {
          debugPrint('AppOpenAd failed to load: $error');
          _appOpenAd = null;
        },
      ),
    );
  }

  /// Muestra el anuncio App Open si está listo y no ha expirado (max 4 horas)
  static Future<void> showAppOpenAdIfAvailable() async {
    // quick early checks
    if (!_isMobileAds) return;
    if (await isPremium()) return;

    try {
      if (_appOpenAd == null) {
        debugPrint('AppOpenAd not available, trying to load it.');
        loadAppOpenAd();
        return;
      }

      if (_isShowingAd) {
        debugPrint('AppOpenAd already showing.');
        return;
      }

      if (_appOpenLoadTime != null &&
          DateTime.now().difference(_appOpenLoadTime!).inHours >= 4) {
        debugPrint('AppOpenAd expired. Reloading...');
        _appOpenAd!.dispose();
        _appOpenAd = null;
        loadAppOpenAd();
        return;
      }

      _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          _isShowingAd = true;
          debugPrint('AppOpenAd showed full screen content.');
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('AppOpenAd failed to show: $error');
          _isShowingAd = false;
          ad.dispose();
          _appOpenAd = null;
        },
        onAdDismissedFullScreenContent: (ad) {
          debugPrint('AppOpenAd dismissed full screen content.');
          _isShowingAd = false;
          ad.dispose();
          _appOpenAd = null;
          loadAppOpenAd();
        },
      );

      _appOpenAd!.show();
    } catch (e, s) {
      debugPrint('Error in showAppOpenAdIfAvailable: $e\n$s');
    }
  }

  /// Muestra el anuncio en pantalla completa consumiendo la memoria
  /// reservada y encolando una nueva precarga para el futuro.
  static Future<void> showInterstitialAd() async {
    if (!_isMobileAds) return; // only Android / iOS
    if (await isPremium() || _interstitialAd == null) {
      return; // Bypass o faltante
    }

    // Evitar superposición si ya hay AppOpen mostrándose
    if (_isShowingAd) return;

    _isShowingAd = true;
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) =>
          debugPrint('ad onAdShowedFullScreenContent.'),
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        debugPrint('$ad onAdDismissedFullScreenContent.');
        _isShowingAd = false;
        ad.dispose();
        createInterstitialAd(); // Recargamos para la próxima vez
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        debugPrint('$ad onAdFailedToShowFullScreenContent: $error');
        _isShowingAd = false;
        ad.dispose();
        createInterstitialAd();
      },
    );
    _interstitialAd!.show();
    _interstitialAd = null;
  }

  // ─── REWARDED ADS (Anuncios Bonificados) ─────────────────────────────────

  static RewardedAd? _rewardedAd;
  static int _numRewardedLoadAttempts = 0;

  static String get rewardedAdUnitId {
    if (kIsWeb) return '';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'ca-app-pub-4579298756868487/5753738440'; // AdsMediaR
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'ca-app-pub-4579298756868487/5753738440';
    }
    return '';
  }

  /// Carga el anuncio bonificado en memoria para tenerlo listo
  static void loadRewardedAd() {
    if (!_isMobileAds) return;
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          debugPrint('RewardedAd loaded.');
          _rewardedAd = ad;
          _numRewardedLoadAttempts = 0;
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('RewardedAd failed to load: $error');
          _rewardedAd = null;
          _numRewardedLoadAttempts += 1;
          if (_numRewardedLoadAttempts < maxFailedLoadAttempts) {
            loadRewardedAd();
          }
        },
      ),
    );
  }

  /// Muestra el anuncio bonificado y ejecuta un callback al completarse exitosamente
  static void showRewardedAd(Function(num amount) onEarnedReward) {
    if (!_isMobileAds) return;
    if (_rewardedAd == null) {
      debugPrint('Warning: attempt to show rewarded before loaded.');
      // Attempt to load for next time
      loadRewardedAd();
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) =>
          debugPrint('Rewarded ad shown.'),
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        debugPrint('Rewarded ad dismissed.');
        ad.dispose();
        loadRewardedAd(); // Load the next ad right away
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        debugPrint('Rewarded ad failed to show: $error');
        ad.dispose();
        loadRewardedAd();
      },
    );

    _rewardedAd!.setImmersiveMode(true);
    _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        debugPrint('User earned reward: ${reward.amount} ${reward.type}');
        onEarnedReward(reward.amount);
      },
    );
    _rewardedAd = null; // Reference consumed
  }

  // ─── REWARDED INTERSTITIAL ADS (Intersticiales Bonificados) --------------

  static RewardedInterstitialAd? _rewardedInterstitialAd;
  static int _numRewardedInterstitialLoadAttempts = 0;

  static String get rewardedInterstitialAdUnitId {
    if (kIsWeb) return '';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'ca-app-pub-4579298756868487/7809056141'; // AdsMediaIR
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'ca-app-pub-4579298756868487/7809056141';
    }
    return '';
  }

  /// Carga un anuncio Intersticial Bonificado (se abre a pantalla completa automático)
  static void loadRewardedInterstitialAd() {
    if (!_isMobileAds) return;
    RewardedInterstitialAd.load(
      adUnitId: rewardedInterstitialAdUnitId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (RewardedInterstitialAd ad) {
          debugPrint('RewardedInterstitialAd loaded.');
          _rewardedInterstitialAd = ad;
          _numRewardedInterstitialLoadAttempts = 0;
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('RewardedInterstitialAd failed to load: $error');
          _rewardedInterstitialAd = null;
          _numRewardedInterstitialLoadAttempts += 1;
          if (_numRewardedInterstitialLoadAttempts < maxFailedLoadAttempts) {
            loadRewardedInterstitialAd();
          }
        },
      ),
    );
  }

  /// Muestra el anuncio intersticial bonificado que requiere menos fricción
  static void showRewardedInterstitialAd(Function onEarnedReward) {
    if (!_isMobileAds) return;
    if (_rewardedInterstitialAd == null) {
      debugPrint(
        'Warning: attempt to show rewarded interstitial before loaded.',
      );
      loadRewardedInterstitialAd();
      return;
    }

    _rewardedInterstitialAd!.fullScreenContentCallback =
        FullScreenContentCallback(
          onAdShowedFullScreenContent: (RewardedInterstitialAd ad) =>
              debugPrint('Rewarded interstitial ad shown.'),
          onAdDismissedFullScreenContent: (RewardedInterstitialAd ad) {
            debugPrint('Rewarded interstitial ad dismissed.');
            ad.dispose();
            loadRewardedInterstitialAd();
          },
          onAdFailedToShowFullScreenContent:
              (RewardedInterstitialAd ad, AdError error) {
                debugPrint('Rewarded interstitial ad failed to show: $error');
                ad.dispose();
                loadRewardedInterstitialAd();
              },
        );

    _rewardedInterstitialAd!.setImmersiveMode(true);
    _rewardedInterstitialAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        debugPrint('User earned reward via interstitial: ${reward.amount}');
        onEarnedReward();
      },
    );
    _rewardedInterstitialAd = null;
  }

  // ─── NATIVE ADVANCED ADS (Nativos Avanzados) -----------------------------

  static String get nativeAdUnitId {
    if (kIsWeb) return '';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'ca-app-pub-4579298756868487/7588400577'; // AdsMediaNa
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'ca-app-pub-4579298756868487/7588400577';
    }
    return '';
  }

  /// Instancia un NativeAd que encaja en el diseño nativo de la app
  static Future<NativeAd?> loadNativeAd(VoidCallback onLoaded) async {
    if (!_isMobileAds) return null; // not supported on web/desktop
    if (await isPremium()) return null; // Bypass prmium

    final nativeAd = NativeAd(
      adUnitId: nativeAdUnitId,
      factoryId:
          'listTile', // Required pre-configured factory inside MainActivity
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (Ad ad) {
          debugPrint('NativeAd loaded.');
          onLoaded();
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          debugPrint('NativeAd failed to load: $error');
          ad.dispose();
        },
      ),
    );

    nativeAd.load();
    return nativeAd;
  }
}
