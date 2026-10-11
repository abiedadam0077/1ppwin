import 'package:flutter_test/flutter_test.dart';
import 'package:nova_windows_cloud/services/admob_service.dart';

void main() {
  test('production AdMob identifiers match the supplied publisher IDs', () {
    expect(NovaAdMob.androidAppId, 'ca-app-pub-8333402469736519~5380632760');
    expect(NovaAdMob.bannerReleaseId, 'ca-app-pub-8333402469736519/8587134624');
    expect(NovaAdMob.interstitialReleaseId, 'ca-app-pub-8333402469736519/5268952122');
  });

  test('non-release builds use Google test ad units', () {
    expect(NovaAdMob.bannerUnitId, NovaAdMob.bannerTestId);
    expect(NovaAdMob.interstitialUnitId, NovaAdMob.interstitialTestId);
  });
}
