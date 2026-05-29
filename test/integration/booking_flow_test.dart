import 'package:chargix_production/core/result/data_state.dart';
import 'package:chargix_production/data/repositories/booking_repository.dart';
import 'package:chargix_production/data/firestore/booking_transaction_service.dart';
import 'package:chargix_production/models/enums/booking_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_data.dart';
import '../helpers/firestore_setup.dart';

/// VM-runnable booking flow tests (mirrors integration_test/booking_flow_test.dart).
void main() {
  group('Booking flow', () {
    test('persists and updates booking via fake Firestore', () async {
      final db = FirestoreTestSetup.fresh();
      final repository = BookingRepository(
        service: FirestoreTestSetup.bookingsService(db),
        transactions: BookingTransactionService(firestore: db),
      );

      final booking = FakeData.booking(
        id: 'flow-booking-1',
        userId: 'driver-1',
      );
      await FirestoreTestSetup.seedBooking(db, booking);

      final fetchResult = await repository.fetchBookingsForUser('driver-1');
      expect(fetchResult, isA<DataSuccess>());
      final bookings = (fetchResult as DataSuccess).data;
      expect(bookings.length, 1);

      final updateResult = await repository.updateBookingStatus(
        bookingId: booking.id,
        status: BookingStatus.approved,
      );
      expect(updateResult, isA<DataSuccess<void>>());

      final doc = await db.collection('bookings').doc(booking.id).get();
      expect(doc.data()?['status'], 'approved');
    });

    test('returns bookings sorted newest first', () async {
      final db = FirestoreTestSetup.fresh();
      final service = FirestoreTestSetup.bookingsService(db);

      await FirestoreTestSetup.seedBooking(
        db,
        FakeData.booking(
          id: 'old',
          userId: 'u1',
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );
      await FirestoreTestSetup.seedBooking(
        db,
        FakeData.booking(
          id: 'new',
          userId: 'u1',
          createdAt: DateTime.utc(2026, 6, 1),
        ),
      );

      final list = await service.getBookingsForUser('u1');
      expect(list.first.id, 'new');
    });
  });
}
