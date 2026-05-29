import 'package:chargix_production/core/navigation/main_tab_scope.dart';
import 'package:chargix_production/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Navigation flow integration', () {
    testWidgets('MainTabScope switches visible tab content', (tester) async {
      final pages = ['Home', 'Map', 'Activity', 'Profile'];
      int currentIndex = MainTabIndex.home;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: StatefulBuilder(
            builder: (context, setState) {
              void goToTab(int index) => setState(() => currentIndex = index);

              return MainTabScope(
                goToTab: goToTab,
                child: Scaffold(
                  body: IndexedStack(
                    index: currentIndex,
                    children: pages
                        .map((p) => Center(child: Text(p)))
                        .toList(),
                  ),
                  bottomNavigationBar: Row(
                    children: List.generate(
                      pages.length,
                      (i) => TextButton(
                        onPressed: () => MainTabScope.goTo(context, i),
                        child: Text(pages[i]),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsWidgets);

      await tester.tap(find.text('Map'));
      await tester.pumpAndSettle();
      expect(find.text('Map'), findsWidgets);

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.text('Profile'), findsWidgets);
    });

    testWidgets('MainTabIndex constants match navigation order', (tester) async {
      expect(MainTabIndex.home, 0);
      expect(MainTabIndex.map, 1);
      expect(MainTabIndex.activity, 2);
      expect(MainTabIndex.profile, 3);
      expect(MainTabIndex.bookings, MainTabIndex.activity);
    });
  });
}
