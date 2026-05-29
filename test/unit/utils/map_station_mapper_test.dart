import 'package:chargix_production/utils/map_station_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_data.dart';

void main() {
  group('MapStationMapper', () {
    test('fromPartner maps StationModel to MapStation.partner', () {
      final model = FakeData.station();
      final mapStation = MapStationMapper.fromPartner(model);

      expect(mapStation.isPartner, isTrue);
      expect(mapStation.id, model.id);
      expect(mapStation.name, model.name);
      expect(mapStation.partner?.station.id, model.id);
    });

    test('fromPartner computes distance when user coords provided', () {
      final model = FakeData.station();
      final mapStation = MapStationMapper.fromPartner(
        model,
        userLat: FakeData.ammanLat,
        userLng: FakeData.ammanLng,
      );
      expect(mapStation.distanceKm, closeTo(0, 0.01));
    });

    test('fromPartners maps list preserving order', () {
      final models = [
        FakeData.station(id: 'a'),
        FakeData.station(id: 'b'),
      ];
      final result = MapStationMapper.fromPartners(models);
      expect(result.map((s) => s.id).toList(), ['a', 'b']);
    });
  });
}
