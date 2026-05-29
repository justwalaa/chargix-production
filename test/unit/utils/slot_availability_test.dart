import 'package:chargix_production/utils/slot_availability.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_data.dart';

void main() {
  group('SlotAvailability', () {
    test('compute counts open available slots as driverVisible', () {
      final slots = [
        FakeData.slot(id: '1', isOpen: true, isAvailable: true),
        FakeData.slot(id: '2', isOpen: true, isAvailable: true),
        FakeData.slot(id: '3', isOpen: true, isAvailable: false),
        FakeData.slot(id: '4', isOpen: false, isAvailable: true),
      ];

      final stats = SlotAvailability.compute(slots);

      expect(stats.total, 4);
      expect(stats.open, 3);
      expect(stats.available, 2);
      expect(stats.booked, 1);
      expect(stats.driverVisible, 2);
    });

    test('empty list returns zero stats', () {
      final stats = SlotAvailability.compute([]);
      expect(stats.total, 0);
      expect(stats.driverVisible, 0);
    });

    test('all closed bays yield zero driverVisible', () {
      final slots = [
        FakeData.slot(isOpen: false),
        FakeData.slot(id: '2', isOpen: false),
      ];
      final stats = SlotAvailability.compute(slots);
      expect(stats.driverVisible, 0);
      expect(stats.open, 0);
    });
  });
}
