// Smoke test — full suite lives under test/unit, test/widget, integration_test/.

import 'package:chargix_production/utils/geo_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('GeoUtils smoke test', () {
    expect(GeoUtils.formatDistanceKm(null), '—');
  });
}
