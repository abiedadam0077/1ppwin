import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_windows_cloud/core/widgets.dart';

void main() {
  testWidgets(
    'Arabic five-tab navigation fits a narrow screen and remains usable',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(240, 640));
      addTearDown(() async => tester.binding.setSurfaceSize(null));

      var selected = 2;
      const items = [
        NovaNavigationItem(
          icon: Icons.home_outlined,
          selectedIcon: Icons.home,
          label: 'الرئيسية',
        ),
        NovaNavigationItem(
          icon: Icons.folder_outlined,
          selectedIcon: Icons.folder,
          label: 'المستودعات',
        ),
        NovaNavigationItem(
          icon: Icons.backup_outlined,
          selectedIcon: Icons.backup,
          label: 'نسخ\nواستعادة',
        ),
        NovaNavigationItem(
          icon: Icons.history_outlined,
          selectedIcon: Icons.history,
          label: 'النشاط',
        ),
        NovaNavigationItem(
          icon: Icons.settings_outlined,
          selectedIcon: Icons.settings,
          label: 'الإعدادات',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: StatefulBuilder(
              builder: (context, setState) => Scaffold(
                body: const SizedBox.expand(),
                bottomNavigationBar: NovaBottomNavigationBar(
                  selectedIndex: selected,
                  items: items,
                  onSelected: (index) => setState(() => selected = index),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(NovaBottomNavigationBar), findsOneWidget);
      expect(find.text('نسخ\nواستعادة'), findsOneWidget);
      expect(
        tester.getSize(find.byType(NovaBottomNavigationBar)).height,
        greaterThanOrEqualTo(66),
      );
      expect(
        tester.getCenter(find.text('الرئيسية')).dx,
        greaterThan(tester.getCenter(find.text('المستودعات')).dx),
      );

      await tester.tap(find.text('الإعدادات'));
      await tester.pumpAndSettle();
      expect(selected, 4);
      expect(tester.takeException(), isNull);
    },
  );
}
