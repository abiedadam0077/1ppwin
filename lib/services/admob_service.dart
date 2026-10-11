import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme.dart';

/// Google Mobile Ads is optional: every failure path falls back to no ad.
/// Debug/profile builds use Google's official test app/unit IDs; only release
/// builds use the publisher IDs supplied by the app owner.
class NovaAdMob {
  NovaAdMob._();

  static const androidAppId = 'ca-app-pub-8333402469736519~5380632760';
  static const bannerReleaseId = 'ca-app-pub-8333402469736519/8587134624';
  static const interstitialReleaseId = 'ca-app-pub-8333402469736519/5268952122';

  static const testAndroidAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const bannerTestId = 'ca-app-pub-3940256099942544/6300978111';
  static const interstitialTestId = 'ca-app-pub-3940256099942544/1033173712';

  static const _lastInterstitialKey = 'nova_ads_last_interstitial_at';
  static const _interstitialCooldown = Duration(minutes: 20);

  static String get bannerUnitId => kReleaseMode ? bannerReleaseId : bannerTestId;
  static String get interstitialUnitId =>
      kReleaseMode ? interstitialReleaseId : interstitialTestId;

  static Future<bool>? _initialization;
  static bool _canRequestAds = false;
  static bool _sdkInitialized = false;
  static bool _interstitialLoading = false;
  static bool _showingInterstitial = false;
  static InterstitialAd? _interstitial;

  /// Request consent if required, then initialize the SDK. Any SDK/UMP/network
  /// error is deliberately non-fatal to the rest of the app.
  static Future<bool> initialize() => _initialization ??= _initialize();

  static Future<bool> _initialize() async {
    try {
      await _refreshConsentInformation();
      _canRequestAds = await ConsentInformation.instance.canRequestAds();
      if (!_canRequestAds) return false;

      await _ensureSdkInitialized();
      _loadInterstitial();
      return true;
    } catch (_) {
      _canRequestAds = false;
      _initialization = null;
      return false;
    }
  }

  static Future<void> _ensureSdkInitialized() async {
    if (_sdkInitialized) return;
    await MobileAds.instance.initialize();
    _sdkInitialized = true;
  }

  static Future<void> _refreshConsentInformation() async {
    final completed = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        try {
          await ConsentForm.loadAndShowConsentFormIfRequired((_) {});
        } catch (_) {
          // Continue with the cached consent state if the form cannot load.
        }
        if (!completed.isCompleted) completed.complete();
      },
      (_) {
        if (!completed.isCompleted) completed.complete();
      },
    );
    await completed.future.timeout(
      const Duration(seconds: 20),
      onTimeout: () {},
    );
  }

  /// Shows Google's privacy options form only when UMP says an entry point is
  /// required. Returns false when it is unnecessary or unavailable.
  static Future<bool> showPrivacyOptions() async {
    try {
      await initialize();
      final requirement =
          await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
      if (requirement != PrivacyOptionsRequirementStatus.required) return false;

      await ConsentForm.showPrivacyOptionsForm((_) {});
      _canRequestAds = await ConsentInformation.instance.canRequestAds();
      if (_canRequestAds) {
        await _ensureSdkInitialized();
        _loadInterstitial();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  static void _loadInterstitial() {
    if (!_canRequestAds || _interstitialLoading || _interstitial != null) return;
    _interstitialLoading = true;
    try {
      InterstitialAd.load(
        adUnitId: interstitialUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialLoading = false;
            _interstitial = ad;
          },
          onAdFailedToLoad: (_) {
            _interstitialLoading = false;
            _interstitial = null;
          },
        ),
      );
    } catch (_) {
      _interstitialLoading = false;
      _interstitial = null;
    }
  }

  /// Called only after a user-requested repository-list refresh succeeds. It
  /// is frequency-capped across app restarts and never holds core app behavior
  /// open if an ad is unavailable or fails to show.
  static Future<bool> showInterstitialIfEligible() async {
    if (!_canRequestAds || _showingInterstitial) return false;
    if (_interstitial == null) {
      _loadInterstitial();
      return false;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final lastShown = prefs.getInt(_lastInterstitialKey);
      final now = DateTime.now();
      if (lastShown != null &&
          now.difference(DateTime.fromMillisecondsSinceEpoch(lastShown)) <
              _interstitialCooldown) {
        return false;
      }

      final ad = _interstitial!;
      _interstitial = null;
      _showingInterstitial = true;
      final completed = Completer<void>();
      var wasShown = false;

      void finish(InterstitialAd closedAd) {
        closedAd.dispose();
        _showingInterstitial = false;
        _loadInterstitial();
        if (!completed.isCompleted) completed.complete();
      }

      ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
        onAdShowedFullScreenContent: (_) {
          wasShown = true;
          unawaited(prefs.setInt(
            _lastInterstitialKey,
            DateTime.now().millisecondsSinceEpoch,
          ).then<void>((_) {}));
        },
        onAdDismissedFullScreenContent: finish,
        onAdFailedToShowFullScreenContent: (closedAd, _) => finish(closedAd),
      );

      try {
        ad.show();
      } catch (_) {
        finish(ad);
        return false;
      }

      await completed.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          _showingInterstitial = false;
          _loadInterstitial();
        },
      );
      return wasShown;
    } catch (_) {
      return false;
    }
  }
}

/// A non-overlay banner reserved in the Home scaffold's layout. On load
/// failure it takes no space and never covers navigation or page content.
class NovaBannerAdSlot extends StatefulWidget {
  const NovaBannerAdSlot({super.key});

  @override
  State<NovaBannerAdSlot> createState() => _NovaBannerAdSlotState();
}

class _NovaBannerAdSlotState extends State<NovaBannerAdSlot> {
  BannerAd? _banner;

  @override
  void initState() {
    super.initState();
    unawaited(_loadBanner());
  }

  Future<void> _loadBanner() async {
    try {
      if (!await NovaAdMob.initialize() || !mounted) return;

      final width = MediaQuery.sizeOf(context).width.truncate();
      final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
      if (size == null || !mounted) return;

      final banner = BannerAd(
        adUnitId: NovaAdMob.bannerUnitId,
        size: size,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (!mounted) {
              ad.dispose();
              return;
            }
            setState(() => _banner = ad);
          },
          onAdFailedToLoad: (ad, _) {
            ad.dispose();
            if (mounted) setState(() => _banner = null);
          },
        ),
      );
      await banner.load();
    } catch (_) {
      if (mounted) setState(() => _banner = null);
    }
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banner = _banner;
    if (banner == null) return const SizedBox.shrink();

    return ColoredBox(
      color: NovaTheme.bg2,
      child: Center(
        child: SizedBox(
          width: banner.size.width.toDouble(),
          height: banner.size.height.toDouble(),
          child: AdWidget(ad: banner),
        ),
      ),
    );
  }
}
