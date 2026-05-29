import 'package:chargix_production/models/enums/booking_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BookingStatus', () {
    test('fromValue maps confirmed alias to approved', () {
      expect(BookingStatus.fromValue('confirmed'), BookingStatus.approved);
    });

    test('fromValue returns pending for unknown values', () {
      expect(BookingStatus.fromValue('unknown'), BookingStatus.pending);
      expect(BookingStatus.fromValue(null), BookingStatus.pending);
    });

    test('isTerminal is true for completed, cancelled, rejected', () {
      expect(BookingStatus.completed.isTerminal, isTrue);
      expect(BookingStatus.cancelled.isTerminal, isTrue);
      expect(BookingStatus.rejected.isTerminal, isTrue);
      expect(BookingStatus.pending.isTerminal, isFalse);
      expect(BookingStatus.active.isTerminal, isFalse);
    });

    test('holdsSlot is true for active reservation states', () {
      expect(BookingStatus.pending.holdsSlot, isTrue);
      expect(BookingStatus.approved.holdsSlot, isTrue);
      expect(BookingStatus.confirmed.holdsSlot, isTrue);
      expect(BookingStatus.active.holdsSlot, isTrue);
      expect(BookingStatus.completed.holdsSlot, isFalse);
      expect(BookingStatus.rejected.holdsSlot, isFalse);
    });

    test('value round-trips for canonical enum members', () {
      for (final status in BookingStatus.values) {
        if (status == BookingStatus.confirmed) continue;
        expect(BookingStatus.fromValue(status.value), status);
      }
      expect(BookingStatus.fromValue('confirmed'), BookingStatus.approved);
    });
  });
}
