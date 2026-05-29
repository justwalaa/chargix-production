import 'package:chargix_production/models/station_slot_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_data.dart';

void main() {
  group('StationSlotModel', () {
    test('toMap and fromMap round-trip', () {
      final original = FakeData.slot();
      final restored = StationSlotModel.fromMap(original.toMap());

      expect(restored.id, original.id);
      expect(restored.label, original.label);
      expect(restored.isOpen, isTrue);
      expect(restored.isAvailable, isTrue);
    });

    test('copyWith overrides selected fields', () {
      final slot = FakeData.slot();
      final updated = slot.copyWith(isAvailable: false, label: 'Bay B');

      expect(updated.isAvailable, isFalse);
      expect(updated.label, 'Bay B');
      expect(updated.id, slot.id);
    });

    test('fromMap applies defaults for connector and charging type', () {
      final map = {
        'id': 's1',
        'stationId': 'st1',
        'label': 'A',
      };
      final slot = StationSlotModel.fromMap(map);
      expect(slot.connectorType, 'Type 2');
      expect(slot.chargingType, 'AC');
      expect(slot.powerKw, 22);
    });
  });
}
