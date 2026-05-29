import 'package:chargix_production/widgets/map/station_type_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_data.dart';
import '../../helpers/pump_helpers.dart';

void main() {
  group('StationTypeBadge', () {
    testWidgets('shows Chargix Partner for partner stations', (tester) async {
      await pumpChargixWidget(
        tester,
        StationTypeBadge(station: FakeData.partnerMapStation()),
      );

      expect(find.text('Chargix Partner'), findsOneWidget);
      expect(find.byIcon(Icons.verified_rounded), findsOneWidget);
    });

    testWidgets('shows External Station for places results', (tester) async {
      await pumpChargixWidget(
        tester,
        StationTypeBadge(station: FakeData.externalMapStation()),
      );

      expect(find.text('External Station'), findsOneWidget);
      expect(find.byIcon(Icons.public_rounded), findsOneWidget);
    });
  });
}
