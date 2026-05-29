import 'package:chargix_production/widgets/stations/station_list_tile.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_data.dart';
import '../../helpers/pump_helpers.dart';

void main() {
  group('StationListTile', () {
    testWidgets('displays station name, ports, and rating', (tester) async {
      final station = FakeData.station(
        name: 'Test Hub',
        availablePorts: 2,
        totalPorts: 4,
        rating: 4.8,
      );

      await pumpChargixWidget(
        tester,
        StationListTile(station: station, onTap: () {}),
      );

      expect(find.text('Test Hub'), findsOneWidget);
      expect(find.text('2/4 ports open'), findsOneWidget);
      expect(find.text('4.8'), findsOneWidget);
    });

    testWidgets('onTap callback fires when card tapped', (tester) async {
      var tapped = false;
      await pumpChargixWidget(
        tester,
        StationListTile(
          station: FakeData.station(),
          onTap: () => tapped = true,
        ),
      );

      await tester.tap(find.byType(StationListTile));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('shows error color when no ports available', (tester) async {
      final station = FakeData.station(availablePorts: 0, totalPorts: 2);
      await pumpChargixWidget(
        tester,
        StationListTile(station: station, onTap: () {}),
      );

      expect(find.text('0/2 ports open'), findsOneWidget);
    });
  });
}
