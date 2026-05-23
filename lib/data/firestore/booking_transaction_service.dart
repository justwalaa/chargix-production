import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firebase/firestore_paths.dart';
import '../../core/result/data_state.dart';
import 'package:chargix_production/models/booking_model.dart';
import '../../models/enums/booking_status.dart';
import '../../models/station_model.dart';
import '../../models/station_slot_model.dart';
import 'base_firestore_service.dart';

/// Concurrency-safe slot reservation using Firestore transactions.
class BookingTransactionService extends BaseFirestoreService {
  BookingTransactionService({super.firestore});

  static final BookingTransactionService instance = BookingTransactionService();

  Future<DataState<BookingModel>> reserveSlot({
    required String userId,
    required StationModel station,
    required StationSlotModel slot,
    required DateTime scheduledStart,
    required DateTime scheduledEnd,
    String? vehicleId,
  }) async {
    try {
      final bookingId =
          'bk_${station.id}_${slot.id}_${DateTime.now().millisecondsSinceEpoch}';
      final slotRef = doc(FirestorePaths.stationSlot(station.id, slot.id));
      final bookingRef = doc(FirestorePaths.booking(bookingId));

      final booking = await db.runTransaction<BookingModel>((tx) async {
        final slotSnap = await tx.get(slotRef);
        if (!slotSnap.exists) {
          throw const SlotReservationException('Charger bay not found.');
        }
        final slotData = slotSnap.data()!;
        final available = slotData['isAvailable'] as bool? ?? false;
        if (!available) {
          throw const SlotReservationException(
            'This bay was just taken. Pick another slot.',
          );
        }

        final holdUser = slotData['holdUserId'] as String?;
        if (holdUser != null && holdUser != userId) {
          throw const SlotReservationException(
            'This bay is reserved by another driver.',
          );
        }

        final now = DateTime.now();
        final model = BookingModel(
          id: bookingId,
          userId: userId,
          stationId: station.id,
          vehicleId: vehicleId,
          status: BookingStatus.pending,
          scheduledStart: scheduledStart,
          scheduledEnd: scheduledEnd,
          portNumber: null,
          slotId: slot.id,
          priceTotal: (slot.pricePerKwh ?? station.pricePerKwh) * 35,
          notes: 'Awaiting station approval',
          createdAt: now,
          updatedAt: now,
        );

        tx.update(slotRef, {
          'isAvailable': false,
          'holdUserId': userId,
          'holdBookingId': bookingId,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        tx.set(
          bookingRef,
          withWriteTimestamps(data: model.toMap(), isCreate: true),
        );

        return model;
      });

      return DataSuccess(booking);
    } on SlotReservationException catch (e) {
      return DataError(e.message);
    } catch (e, st) {
      return DataError(e, stackTrace: st);
    }
  }

  Future<DataState<void>> respondToBooking({
    required BookingModel booking,
    required BookingStatus newStatus,
    String? rejectionReason,
  }) async {
    try {
      await db.runTransaction((tx) async {
        final bookingRef = doc(FirestorePaths.booking(booking.id));
        final bookingSnap = await tx.get(bookingRef);
        if (!bookingSnap.exists) {
          throw StateError('Booking not found');
        }

        tx.update(bookingRef, {
          'status': newStatus.value,
          'rejectionReason': ?rejectionReason,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        final slotId = booking.slotId;
        if (slotId == null) {
          return;
        }
        final slotRef =
            doc(FirestorePaths.stationSlot(booking.stationId, slotId));

        if (newStatus == BookingStatus.rejected ||
            newStatus == BookingStatus.cancelled) {
          tx.update(slotRef, {
            'isAvailable': true,
            'holdUserId': FieldValue.delete(),
            'holdBookingId': FieldValue.delete(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else if (newStatus == BookingStatus.approved ||
            newStatus == BookingStatus.confirmed ||
            newStatus == BookingStatus.active) {
          tx.update(slotRef, {
            'isAvailable': false,
            'holdBookingId': booking.id,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });
      return const DataSuccess(null);
    } catch (e, st) {
      return DataError(e, stackTrace: st);
    }
  }
}

/// User-visible slot contention failure.
class SlotReservationException implements Exception {
  const SlotReservationException(this.message);
  final String message;

  @override
  String toString() => message;
}
