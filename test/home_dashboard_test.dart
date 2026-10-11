import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' hide AppState;
import 'package:provider/provider.dart';
import 'package:nova_windows_cloud/screens/home_shell.dart';
import 'package:nova_windows_cloud/state/app_state.dart';

void main() {
  testWidgets('home shows an honest empty backup state before repo selection', (tester) async {
    final originalConsentInformation = ConsentInformation.instance;
    ConsentInformation.instance = _NoConsentInformation();
    addTearDown(() {
      ConsentInformation.instance = originalConsentInformation;
    });

    await tester.binding.setSurfaceSize(const Size(390, 1000));
    final state = AppState();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.binding.setSurfaceSize(null);
      state.dispose();
    });

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: state,
        child: const MaterialApp(
          locale: Locale('ar'),
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('ar'), Locale('en'), Locale('fr')],
          home: HomeFlowScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('لم يتم اختيار مستودع بعد'), findsOneWidget);
    expect(find.text('جارٍ تحميل النسخ الاحتياطية'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _NoConsentInformation extends ConsentInformation {
  @override
  void requestConsentInfoUpdate(
    ConsentRequestParameters params,
    OnConsentInfoUpdateSuccessListener successListener,
    OnConsentInfoUpdateFailureListener failureListener,
  ) {
    failureListener(FormError(errorCode: 0, message: 'UMP is not available in widget tests'));
  }

  @override
  Future<bool> isConsentFormAvailable() async => false;

  @override
  Future<ConsentStatus> getConsentStatus() async => ConsentStatus.unknown;

  @override
  Future<void> reset() async {}

  @override
  Future<bool> canRequestAds() async => false;

  @override
  Future<PrivacyOptionsRequirementStatus> getPrivacyOptionsRequirementStatus() async =>
      PrivacyOptionsRequirementStatus.notRequired;
}
