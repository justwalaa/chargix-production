import 'package:chargix_production/models/booking_model.dart';
import 'package:chargix_production/core/result/data_state.dart';
import 'package:chargix_production/data/repositories/booking_repository.dart';
import 'package:chargix_production/models/enums/booking_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chargix_production/data/firestore/booking_transaction_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fake_data.dart';
import '../../helpers/firestore_setup.dart';
import '../../helpers/mock_services.dart';
void main() {
  late MockBookingsFirestoreService mockService;
  late BookingRepository repository;

  setUpAll(() {
    registerFallbackValue(FakeData.booking());
  });

  setUp(() {
    mockService = MockBookingsFirestoreService();
    final db = FakeFirebaseFirestore();
    repository = BookingRepository(
      service: mockService,
      transactions: BookingTransactionService(firestore: db),
    );
  });

  group('BookingRepository with mocktail', () {
    test('updateBookingStatus delegates to service and returns success', () async {
      when(
        () => mockService.updateBookingStatus(
          any(),
          any(),
          rejectionReason: any(named: 'rejectionReason'),
        ),
      ).thenAnswer((_) async {});

      final result = await repository.updateBookingStatus(
        bookingId: 'b1',
        status: BookingStatus.approved,
      );

      expect(result, isA<DataSuccess<void>>());
      verify(
        () => mockService.updateBookingStatus('b1', 'approved'),
      ).called(1);
    });

    test('updateBookingStatus returns DataError on failure', () async {
      when(
        () => mockService.updateBookingStatus(
          any(),
          any(),
          rejectionReason: any(named: 'rejectionReason'),
        ),
      ).thenThrow(Exception('network'));

      final result = await repository.updateBookingStatus(
        bookingId: 'b1',
        status: BookingStatus.rejected,
        rejectionReason: 'Full',
      );

      expect(result, isA<DataError<void>>());
    });

    test('saveBooking creates when booking does not exist', () async {
      when(() => mockService.getBooking('b1')).thenAnswer((_) async => null);
      when(
        () => mockService.upsertBooking(any(), isCreate: true),
      ).thenAnswer((_) async {});

      final booking = FakeData.booking(id: 'b1');
      final result = await repository.saveBooking(booking);

      expect(result, isA<DataSuccess<void>>());
      verify(() => mockService.upsertBooking(booking, isCreate: true)).called(1);
    });
  });

  group('BookingRepository with fake_cloud_firestore', () {
    test('fetchBookingsForUser returns seeded bookings', () async {
      final db = FirestoreTestSetup.fresh();
      final booking = FakeData.booking(userId: 'u1');
      await FirestoreTestSetup.seedBooking(db, booking);

      repository = BookingRepository(
        service: FirestoreTestSetup.bookingsService(db),
        transactions: BookingTransactionService(firestore: db),
      );

      final result = await repository.fetchBookingsForUser('u1');
      expect(result, isA<DataSuccess>());
      final list = (result as DataSuccess<List<BookingModel>>).data;
      expect(list.length, 1);
      expect(list.first.id, booking.id);
    });
  });
}
