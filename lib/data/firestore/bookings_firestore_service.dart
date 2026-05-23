import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firebase/firestore_paths.dart';
import 'package:chargix_production/models/booking_model.dart';
import 'base_firestore_service.dart';

class BookingsFirestoreService extends BaseFirestoreService {
  BookingsFirestoreService({super.firestore});

  CollectionReference<Map<String, dynamic>> get _bookings =>
      collection(FirestorePaths.bookings);

  Future<List<BookingModel>> getBookingsForUser(String userId) => run(() async {
        final query =
            await _bookings.where('userId', isEqualTo: userId).get();
        final list =
            query.docs.map((d) => parseDoc(d, BookingModel.fromMap)).toList();
        list.sort((a, b) {
          final at = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bt.compareTo(at);
        });
        return list;
      }, context: 'getBookingsForUser');

  Stream<List<BookingModel>> watchBookingsForUser(String userId) {
    return runStream(
      () => _bookings.where('userId', isEqualTo: userId).snapshots().map((snap) {
            final list =
                snap.docs.map((d) => parseDoc(d, BookingModel.fromMap)).toList();
            list.sort((a, b) {
              final at = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              final bt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              return bt.compareTo(at);
            });
            return list;
          }),
      context: 'watchBookingsForUser',
    );
  }

  Future<BookingModel?> getBooking(String id) => run(() async {
        final snap = await _bookings.doc(id).get();
        if (!snap.exists) {
          return null;
        }
        return parseDoc(snap, BookingModel.fromMap);
      }, context: 'getBooking');

  Stream<List<BookingModel>> watchBookingsForStation(String stationId) {
    return runStream(
      () => _bookings
          .where('stationId', isEqualTo: stationId)
          .snapshots()
          .map((snap) {
            final list =
                snap.docs.map((d) => parseDoc(d, BookingModel.fromMap)).toList();
            list.sort((a, b) {
              final at = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              final bt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              return bt.compareTo(at);
            });
            return list;
          }),
      context: 'watchBookingsForStation',
    );
  }

  Future<void> upsertBooking(BookingModel booking, {required bool isCreate}) =>
      run(() async {
        final data = withWriteTimestamps(
          data: booking.toMap(),
          isCreate: isCreate,
        );
        await _bookings.doc(booking.id).set(data, SetOptions(merge: true));
      }, context: 'upsertBooking');

  Future<void> updateBookingStatus(
    String bookingId,
    String status, {
    String? rejectionReason,
  }) =>
      run(() async {
        await _bookings.doc(bookingId).set(
          {
            'status': status,
            'rejectionReason': ?rejectionReason,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }, context: 'updateBookingStatus');
}
