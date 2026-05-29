import 'package:chargix_production/core/result/data_state.dart';
import 'package:chargix_production/data/repositories/booking_repository.dart';
import 'package:chargix_production/models/enums/booking_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/helpers/fake_data.dart';
import '../test/helpers/firestore_setup.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Booking flow integration', () {
    test('end-to-end booking persistence via fake Firestore', () async {
      final db = FirestoreTestSetup.fresh();
      final service = FirestoreTestSetup.bookingsService(db);
      final repository = BookingRepository(service: service);

      final booking = FakeData.booking(
        id: 'flow-booking-1',
        userId: 'driver-1',
        status: BookingStatus.pending,
      );
      await FirestoreTestSetup.seedBooking(db, booking);

      final fetchResult = await repository.fetchBookingsForUser('driver-1');
      expect(fetchResult, isA<DataSuccess>());
      final bookings = (fetchResult as DataSuccess).data;
      expect(bookings.length, 1);
      expect(bookings.first.slotId, booking.slotId);

      final updateResult = await repository.updateBookingStatus(
        bookingId: booking.id,
        status: BookingStatus.approved,
      );
      expect(updateResult, isA<DataSuccess<void>>());

      final doc = await db.collection('bookings').doc(booking.id).get();
      expect(doc.data()?['status'], 'approved');
    });

    test('booking list sorted by createdAt descending', () async {
      final db = FirestoreTestSetup.fresh();
      final service = FirestoreTestSetup.bookingsService(db);

      final older = FakeData.booking(
        id: 'old',
        userId: 'u1',
        createdAt: DateTime.utc(2026, 1, 1),
      );
      final newer = FakeData.booking(
        id: 'new',
        userId: 'u1',
        createdAt: DateTime.utc(2026, 6, 1),
      );

      await FirestoreTestSetup.seedBooking(db, older);
      await FirestoreTestSetup.seedBooking(db, newer);

      final list = await service.getBookingsForUser('u1');
      expect(list.first.id, 'new');
      expect(list.last.id, 'old');
    });
  });
}
