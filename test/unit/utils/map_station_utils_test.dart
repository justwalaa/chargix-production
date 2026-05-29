import 'package:chargix_production/models/map_station_item.dart';
import 'package:chargix_production/utils/map_station_utils.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_data.dart';

void main() {
  group('MapStationUtils', () {
    late List<MapStationItem> items;

    setUp(() {
      final partner = FakeData.partnerMapStation();
      final external = FakeData.externalMapStation();
      items = MapStationUtils.withDistances(
        stations: [partner, external],
        userLat: FakeData.ammanLat,
        userLng: FakeData.ammanLng,
      );
    });

    test('withDistances attaches distanceKm from user location', () {
      expect(items.every((e) => e.distanceKm != null), isTrue);
      expect(items.first.distanceKm, closeTo(0, 1));
    });

    test('sortByDistance orders nearest first', () {
      final sorted = MapStationUtils.sortByDistance(items);
      expect(
        sorted.first.distanceKm! <= sorted.last.distanceKm!,
        isTrue,
      );
    });

    test('applyFilter partners returns only Chargix stations', () {
      final filtered = MapStationUtils.applyFilter(items, MapStationFilter.partners);
      expect(filtered.every((e) => e.station.isPartner), isTrue);
      expect(filtered.length, 1);
    });

    test('applyFilter external returns only external stations', () {
      final filtered = MapStationUtils.applyFilter(items, MapStationFilter.external);
      expect(filtered.every((e) => e.station.isExternal), isTrue);
    });

    test('applyFilter available requires partner with open ports', () {
      final noPorts = FakeData.partnerMapStation(
        stationModel: FakeData.station(availablePorts: 0),
      );
      final withPorts = FakeData.partnerMapStation(
        stationModel: FakeData.station(id: 's2', availablePorts: 3),
      );
      final list = MapStationUtils.withDistances(
        stations: [noPorts, withPorts],
        userLat: FakeData.ammanLat,
        userLng: FakeData.ammanLng,
      );
      final filtered = MapStationUtils.applyFilter(list, MapStationFilter.available);
      expect(filtered.length, 1);
      expect(filtered.first.station.id, 's2');
    });

    test('applySearch matches name and address', () {
      final byName = MapStationUtils.applySearch(items, 'chargix');
      expect(byName.length, 1);

      final byAddress = MapStationUtils.applySearch(items, 'desert');
      expect(byAddress.length, 1);
    });

    test('applySearch empty query returns all items', () {
      expect(MapStationUtils.applySearch(items, ''), items);
      expect(MapStationUtils.applySearch(items, '   '), items);
    });

    test('mergePartnerAndExternal dedupes nearby external stations', () {
      final partner = FakeData.partnerMapStation();
      final duplicateExternal = FakeData.externalMapStation(
        latitude: FakeData.ammanLat + 0.0001,
        longitude: FakeData.ammanLng + 0.0001,
      );
      final farExternal = FakeData.externalMapStation(
        id: 'ext-far',
        latitude: FakeData.aqabaLat,
        longitude: FakeData.aqabaLng,
      );

      final merged = MapStationUtils.mergePartnerAndExternal(
        partners: [partner],
        external: [duplicateExternal, farExternal],
      );
      expect(merged.length, 2);
      expect(merged.any((s) => s.id == 'ext-far'), isTrue);
    });
  });
}
