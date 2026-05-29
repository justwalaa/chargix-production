import 'package:chargix_production/models/partner_map_data.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_data.dart';

void main() {
  group('MapStation', () {
    test('partner station flags and markerId', () {
      final station = FakeData.partnerMapStation();
      expect(station.isPartner, isTrue);
      expect(station.isExternal, isFalse);
      expect(station.markerId, 'partner_${station.id}');
    });

    test('external station markerId uses place id', () {
      final station = FakeData.externalMapStation(placeId: 'pid-1');
      expect(station.isExternal, isTrue);
      expect(station.markerId, 'ext_pid-1');
    });

    test('isBookable reflects partner availability', () {
      final bookable = FakeData.partnerMapStation(
        stationModel: FakeData.station(availablePorts: 2),
      );
      final full = FakeData.partnerMapStation(
        stationModel: FakeData.station(availablePorts: 0),
      );
      expect(bookable.isBookable, isTrue);
      expect(full.isBookable, isFalse);
    });

    test('copyWith updates distanceKm', () {
      final station = FakeData.partnerMapStation();
      final updated = station.copyWith(distanceKm: 5.2);
      expect(updated.distanceKm, 5.2);
      expect(updated.id, station.id);
    });
  });

  group('PartnerMapData', () {
    test('canBook requires ports and booking enabled', () {
      final data = PartnerMapData(
        station: FakeData.station(
          availablePorts: 1,
          shipmentBookingEnabled: true,
        ),
      );
      expect(data.canBook, isTrue);
      expect(data.isApproved, isTrue);
    });
  });
}
