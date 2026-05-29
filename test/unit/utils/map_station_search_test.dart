import 'package:chargix_production/models/map_station.dart';
import 'package:chargix_production/utils/map_station_search.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_data.dart';

void main() {
  group('MapStationSearch', () {
    late List<MapStation> stations;

    setUp(() {
      stations = [
        FakeData.partnerMapStation(
          stationModel: FakeData.station(
            name: 'Chargix Downtown',
            city: 'Amman',
            description: 'Fast DC charging hub',
          ),
        ),
        FakeData.externalMapStation(
          name: 'Ionity Desert',
          address: 'Desert Highway, Maan',
          chargerTypeHint: 'CCS2 ultra-fast',
        ),
      ];
    });

    test('filter empty query returns all stations', () {
      expect(MapStationSearch.filter(stations, ''), stations);
    });

    test('filter matches station name', () {
      final result = MapStationSearch.filter(stations, 'downtown');
      expect(result.length, 1);
      expect(result.first.name, 'Chargix Downtown');
    });

    test('filter matches partner city field', () {
      final result = MapStationSearch.filter(stations, 'amman');
      expect(result.length, 1);
    });

    test('filter matches external charger type hint', () {
      final result = MapStationSearch.filter(stations, 'ccs2');
      expect(result.length, 1);
      expect(result.first.isExternal, isTrue);
    });

    test('filter matches address tokens of length >= 3', () {
      final result = MapStationSearch.filter(stations, 'maan');
      expect(result.length, 1);
    });
  });
}
