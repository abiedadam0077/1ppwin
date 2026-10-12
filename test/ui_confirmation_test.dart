import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nova_windows_cloud/screens/more.dart';
import 'package:nova_windows_cloud/screens/repos.dart';
import 'package:nova_windows_cloud/state/app_state.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('clearing activity requires confirmation and only clears local history', (tester) async {
    final state = AppState()..lang = 'en';
    state.activity.add(ActivityEntry(DateTime.utc(2026, 10, 12), 'act_login', true));
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      state.dispose();
    });

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: state,
        child: const MaterialApp(
          locale: Locale('en'),
          supportedLocales: [Locale('ar'), Locale('en'), Locale('fr')],
          home: ActivityScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Clear Log'));
    await tester.pumpAndSettle();
    expect(find.text('Clear local activity history?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(state.activity, hasLength(1));

    await tester.tap(find.byTooltip('Clear Log'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear local history'));
    await tester.pumpAndSettle();
    expect(state.activity, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('creating a repository shows a review dialog before any GitHub action', (tester) async {
    final state = AppState()..lang = 'en';
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      state.dispose();
    });

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: state,
        child: const MaterialApp(
          locale: Locale('en'),
          supportedLocales: [Locale('ar'), Locale('en'), Locale('fr')],
          home: CreateRepoScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'nova-review-test');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create & Setup'));
    await tester.pumpAndSettle();
    expect(find.text('Create this repository on GitHub?'), findsOneWidget);
    expect(find.text('nova-review-test'), findsWidgets);

    await tester.tap(
      find.descendant(of: find.byType(AlertDialog), matching: find.text('Cancel')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Create this repository on GitHub?'), findsNothing);
    expect(state.repos, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
