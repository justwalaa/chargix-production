import 'package:chargix_production/core/navigation/main_tab_scope.dart';
import 'package:chargix_production/theme/app_theme.dart';
import 'package:chargix_production/widgets/chargix/empty_state.dart';
import 'package:chargix_production/widgets/home/quick_action_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Dashboard flow integration', () {
    testWidgets('driver dashboard shell switches tabs and shows content',
        (tester) async {
      int tab = MainTabIndex.home;
      final tabLabels = ['Dashboard', 'Map', 'Bookings', 'Profile'];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: StatefulBuilder(
            builder: (context, setState) {
              return MainTabScope(
                goToTab: (i) => setState(() => tab = i),
                child: Scaffold(
                  appBar: AppBar(title: Text(tabLabels[tab])),
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
                        message: 'Map tab placeholder',
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
                  bottomNavigationBar: NavigationBar(
                    selectedIndex: tab,
                    onDestinationSelected: (i) =>
                        MainTabScope.goTo(context, i),
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(Icons.home_outlined),
                        label: 'Home',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.map_outlined),
                        label: 'Map',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.event_note_outlined),
                        label: 'Activity',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.person_outline),
                        label: 'Profile',
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Find charger'), findsOneWidget);

      await tester.tap(find.text('Activity'));
      await tester.pumpAndSettle();
      expect(find.text('Your reservations appear here.'), findsOneWidget);

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.text('Account settings'), findsOneWidget);
    });
  });
}
