import 'package:chargix_production/core/navigation/main_tab_scope.dart';
import 'package:chargix_production/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Navigation flow', () {
    testWidgets('MainTabScope.goTo invokes goToTab callback', (tester) async {
      var tab = MainTabIndex.home;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: StatefulBuilder(
            builder: (context, setState) {
              return MainTabScope(
                goToTab: (i) => setState(() => tab = i),
                child: Builder(
                  builder: (innerContext) {
                    return Scaffold(
                      body: Text('Tab $tab'),
                      floatingActionButton: FloatingActionButton(
                        onPressed: () =>
                            MainTabScope.goTo(innerContext, MainTabIndex.map),
                        child: const Icon(Icons.map),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tab, MainTabIndex.home);
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      expect(tab, MainTabIndex.map);
      expect(find.text('Tab ${MainTabIndex.map}'), findsOneWidget);
    });

    test('MainTabIndex legacy bookings alias equals activity', () {
      expect(MainTabIndex.bookings, MainTabIndex.activity);
    });
  });
}
