import 'package:chargix_production/core/navigation/main_tab_scope.dart';
import 'package:chargix_production/theme/app_theme.dart';
import 'package:chargix_production/widgets/chargix/empty_state.dart';
import 'package:chargix_production/widgets/home/quick_action_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Dashboard flow', () {
    testWidgets('driver shell switches from home to activity tab', (tester) async {
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
                      body: IndexedStack(
                        index: tab,
                        children: [
                          QuickActionCard(
                            icon: Icons.bolt,
                            title: 'Find charger',
                            onTap: () {},
                          ),
                          const ChargixEmptyState(
                            icon: Icons.map_outlined,
                            title: 'Map',
                            message: 'Map tab',
                          ),
                          const ChargixEmptyState(
                            icon: Icons.event_note,
                            title: 'Bookings',
                            message: 'Your reservations appear here.',
                          ),
                          const ChargixEmptyState(
                            icon: Icons.person_outline,
                            title: 'Profile',
                            message: 'Account settings',
                          ),
                        ],
                      ),
                      floatingActionButton: FloatingActionButton(
                        onPressed: () => MainTabScope.goTo(
                          innerContext,
                          MainTabIndex.activity,
                        ),
                        child: const Icon(Icons.event_note),
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

      expect(find.text('Find charger'), findsOneWidget);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      expect(tab, MainTabIndex.activity);
      expect(find.text('Your reservations appear here.'), findsOneWidget);
    });
  });
}
