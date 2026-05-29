import 'package:chargix_production/data/repositories/station_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_data.dart';

void main() {
  group('StationRepository.isMapPartnerStation', () {
    test('accepts valid partner station', () {
      final station = FakeData.station(ownerUserId: 'owner-1');
      expect(StationRepository.isMapPartnerStation(station), isTrue);
    });

    test('rejects demo-prefixed ids', () {
      final station = FakeData.station(id: 'demo-123', ownerUserId: 'o1');
      expect(StationRepository.isMapPartnerStation(station), isFalse);
    });

    test('rejects missing ownerUserId', () {
      final station = FakeData.station(ownerUserId: null);
      expect(StationRepository.isMapPartnerStation(station), isFalse);
    });

    test('rejects zero coordinates', () {
      final station = FakeData.station(
        latitude: 0,
        longitude: 0,
        ownerUserId: 'o1',
      );
      expect(StationRepository.isMapPartnerStation(station), isFalse);
    });

    test('rejects invalid latitude', () {
      final station = FakeData.station(
        latitude: double.nan,
        ownerUserId: 'o1',
      );
      expect(StationRepository.isMapPartnerStation(station), isFalse);
    });

    test('onlyMapPartners filters list', () {
      final stations = [
        FakeData.station(id: 'demo-x', ownerUserId: 'o1'),
        FakeData.station(id: 'real-1', ownerUserId: 'o1'),
      ];
      final filtered = StationRepository.onlyMapPartners(stations);
      expect(filtered.length, 1);
      expect(filtered.first.id, 'real-1');
    });
  });
}
