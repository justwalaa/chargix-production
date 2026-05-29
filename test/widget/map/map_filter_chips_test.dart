import 'package:chargix_production/utils/map_station_utils.dart';
import 'package:chargix_production/widgets/map/map_filter_chips.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_helpers.dart';

void main() {
  group('MapFilterChips', () {
    testWidgets('renders all filter labels', (tester) async {
      await pumpChargixWidget(
        tester,
        MapFilterChips(
          selected: MapStationFilter.all,
          onSelected: (_) {},
        ),
      );

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Chargix'), findsOneWidget);
      expect(find.text('External'), findsOneWidget);
      expect(find.text('Available'), findsOneWidget);
    });

    testWidgets('tap invokes onSelected with filter', (tester) async {
      MapStationFilter? selected;
      await pumpChargixWidget(
        tester,
        MapFilterChips(
          selected: MapStationFilter.all,
          onSelected: (f) => selected = f,
        ),
      );

      await tester.tap(find.text('External'));
      await tester.pumpAndSettle();

      expect(selected, MapStationFilter.external);
    });

    testWidgets('highlights selected chip', (tester) async {
      await pumpChargixWidget(
        tester,
        MapFilterChips(
          selected: MapStationFilter.partners,
          onSelected: (_) {},
        ),
      );

      final chips = tester.widgetList<FilterChip>(find.byType(FilterChip));
      expect(chips.elementAt(1).selected, isTrue);
    });
  });
}
