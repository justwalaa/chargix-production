import 'package:chargix_production/services/map/map_pipeline.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_data.dart';

void main() {
  group('MapPipeline', () {
    test('process rejects invalid firestore coordinates', () {
      final invalid = FakeData.station(
        id: 'bad',
        latitude: 0,
        longitude: 0,
      );
      final valid = FakeData.station(id: 'good');

      final result = MapPipeline.process(
        rawFirestore: [invalid, valid],
        rawPlaces: [],
        centerLat: FakeData.ammanLat,
        centerLng: FakeData.ammanLng,
      );

      expect(result.firestoreRejectedCoords, 1);
      expect(result.firestoreAccepted, 1);
      expect(result.stations.length, 1);
      expect(result.stations.first.id, 'good');
    });

    test('process merges partners and deduped external places', () {
      final partner = FakeData.station(id: 'p1');
      final nearExternal = FakeData.externalMapStation(
        latitude: FakeData.ammanLat + 0.0002,
        longitude: FakeData.ammanLng + 0.0002,
      );
      final farExternal = FakeData.externalMapStation(
        id: 'ext-far',
        latitude: FakeData.aqabaLat,
        longitude: FakeData.aqabaLng,
      );

      final result = MapPipeline.process(
        rawFirestore: [partner],
        rawPlaces: [nearExternal, farExternal],
        centerLat: FakeData.ammanLat,
        centerLng: FakeData.ammanLng,
      );

      expect(result.mergedCount, 2);
      expect(result.dedupedExternalCount, 1);
    });

    test('process sorts merged stations by distance', () {
      final near = FakeData.station(
        id: 'near',
        latitude: FakeData.ammanLat + 0.01,
        longitude: FakeData.ammanLng,
      );
      final far = FakeData.station(
        id: 'far',
        latitude: FakeData.aqabaLat,
        longitude: FakeData.aqabaLng,
      );

      final result = MapPipeline.process(
        rawFirestore: [far, near],
        rawPlaces: [],
        centerLat: FakeData.ammanLat,
        centerLng: FakeData.ammanLng,
      );

      expect(result.stations.first.id, 'near');
      expect(
        result.stations.first.distanceKm! <
            result.stations.last.distanceKm!,
        isTrue,
      );
    });
  });
}
