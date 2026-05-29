import 'package:chargix_production/widgets/chargix/status_badge.dart';
import 'package:chargix_production/widgets/chargix/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_helpers.dart';

void main() {
  group('StatusBadge', () {
    testWidgets('renders uppercase label with color', (tester) async {
      await pumpChargixWidget(
        tester,
        const StatusBadge(label: 'Active', color: Colors.green),
      );

      expect(find.text('ACTIVE'), findsOneWidget);
    });
  });

  group('ChargixEmptyState', () {
    testWidgets('renders title, message, and optional action', (tester) async {
      var tapped = false;
      await pumpChargixWidget(
        tester,
        ChargixEmptyState(
          icon: Icons.ev_station_outlined,
          title: 'No stations',
          message: 'Try adjusting your filters.',
          actionLabel: 'Refresh',
          onAction: () => tapped = true,
        ),
      );

      expect(find.text('No stations'), findsOneWidget);
      expect(find.text('Try adjusting your filters.'), findsOneWidget);

      await tester.tap(find.text('Refresh'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });
  });
}
