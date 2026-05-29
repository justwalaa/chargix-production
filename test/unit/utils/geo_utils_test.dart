import 'package:chargix_production/utils/geo_utils.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_data.dart';

void main() {
  group('GeoUtils', () {
    test('distanceKm returns zero for identical points', () {
      expect(
        GeoUtils.distanceKm(
          FakeData.ammanLat,
          FakeData.ammanLng,
          FakeData.ammanLat,
          FakeData.ammanLng,
        ),
        closeTo(0, 0.001),
      );
    });

    test('distanceKm computes Amman to Aqaba roughly 300 km', () {
      final km = GeoUtils.distanceKm(
        FakeData.ammanLat,
        FakeData.ammanLng,
        FakeData.aqabaLat,
        FakeData.aqabaLng,
      );
      expect(km, inInclusiveRange(280, 330));
    });

    test('formatDistanceKm shows meters under 1 km', () {
      expect(GeoUtils.formatDistanceKm(0.45), '450 m');
    });

    test('formatDistanceKm shows one decimal under 10 km', () {
      expect(GeoUtils.formatDistanceKm(3.456), '3.5 km');
    });

    test('formatDistanceKm shows em dash for null', () {
      expect(GeoUtils.formatDistanceKm(null), '—');
    });
  });
}
