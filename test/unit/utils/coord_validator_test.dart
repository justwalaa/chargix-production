import 'package:chargix_production/models/map_station_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../helpers/fake_data.dart';

void main() {
  group('CoordValidator', () {
    test('isValid accepts in-range coordinates', () {
      expect(CoordValidator.isValid(FakeData.ammanLat, FakeData.ammanLng), isTrue);
    });

    test('isValid rejects out-of-range latitude', () {
      expect(CoordValidator.isValid(95, 0), isFalse);
    });

    test('isValidMENA restricts to MENA bounding box', () {
      expect(
        CoordValidator.isValidMENA(FakeData.ammanLat, FakeData.ammanLng),
        isTrue,
      );
      expect(CoordValidator.isValidMENA(50, 10), isFalse);
    });

    test('haversineKm matches GeoUtils distance', () {
      final a = LatLng(FakeData.ammanLat, FakeData.ammanLng);
      final b = LatLng(FakeData.aqabaLat, FakeData.aqabaLng);
      final km = CoordValidator.haversineKm(a, b);
      expect(km, inInclusiveRange(280, 330));
    });
  });
}
