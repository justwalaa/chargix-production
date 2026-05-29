import 'package:chargix_production/utils/map_directions.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_data.dart';

void main() {
  group('MapDirections', () {
    test('mapsUri encodes destination coordinates', () {
      final station = FakeData.partnerMapStation();
      final uri = MapDirections.mapsUri(station);

      expect(uri.host, 'www.google.com');
      expect(uri.query, contains('destination=${station.latitude}'));
      expect(uri.query, contains('${station.longitude}'));
    });

    test('mapsUri includes external place id when present', () {
      final station = FakeData.externalMapStation(placeId: 'place-xyz');
      final uri = MapDirections.mapsUri(station);
      expect(uri.query, contains('destination_place_id=place-xyz'));
    });
  });
}
