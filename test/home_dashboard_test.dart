import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:nova_windows_cloud/screens/home_shell.dart';
import 'package:nova_windows_cloud/state/app_state.dart';

void main() {
  testWidgets('home shows an honest empty backup state before repo selection', (tester) async {
    final state = AppState();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      state.dispose();
    });

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: state,
        child: const MaterialApp(
          locale: Locale('ar'),
          supportedLocales: [Locale('ar'), Locale('en'), Locale('fr')],
          home: HomeShell(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('لم يتم اختيار مستودع بعد'), findsOneWidget);
    expect(find.text('جارٍ تحميل النسخ الاحتياطية'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
