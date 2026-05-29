import 'package:chargix_production/models/vehicle_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_data.dart';

void main() {
  group('VehicleModel', () {
    test('displayLabel includes year when present', () {
      final vehicle = FakeData.vehicle(year: 2024);
      expect(vehicle.displayLabel, 'Tesla Model 3 (2024)');
    });

    test('displayLabel omits year when null', () {
      final vehicle = FakeData.vehicle(year: null);
      expect(vehicle.displayLabel, 'Tesla Model 3');
    });

    test('toMap and fromMap round-trip', () {
      final original = FakeData.vehicle();
      final restored = VehicleModel.fromMap(original.toMap());
      expect(restored.make, original.make);
      expect(restored.connectorType, 'CCS2');
    });
  });
}
