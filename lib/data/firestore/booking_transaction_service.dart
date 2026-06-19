import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firebase/firestore_paths.dart';
import '../../core/result/data_state.dart';
import 'package:chargix_production/models/booking_model.dart';
import '../../models/enums/booking_status.dart';
import '../../models/notification_model.dart';
import '../../models/slot_time_window.dart';
import '../../models/station_model.dart';
import '../../models/station_slot_model.dart';
import 'base_firestore_service.dart';
import 'notifications_firestore_service.dart';

/// Concurrency-safe slot reservation using Firestore transactions.
class BookingTransactionService extends BaseFirestoreService {
  BookingTransactionService({super.firestore});

  static final BookingTransactionService instance = BookingTransactionService();

  final NotificationsFirestoreService _notifs = NotificationsFirestoreService();

  /// Atomically books [windowId] for [dateKey] ("yyyy-MM-dd") on [slot].
  ///
  /// Transaction steps:
  ///   1. Read slot doc — verify it still exists.
  ///   2. Locate the time window by [windowId].
  ///   3. Verify [dateKey] is NOT already in [bookedDates] (race-condition guard).
  ///   4. Set `bookedDates[dateKey] = bookingId` in the window.
  ///   5. Write updated `timeWindows` array back to slot doc.
  ///   6. Create booking doc.
  Future<DataState<BookingModel>> reserveSlot({
    required String userId,
    required StationModel station,
    required StationSlotModel slot,
    required String windowId,
    required String dateKey,
    String? vehicleId,
  }) async {
    try {
      final bookingId =
          'bk_${station.id}_${slot.id}_${DateTime.now().millisecondsSinceEpoch}';
      final slotRef = doc(FirestorePaths.stationSlot(station.id, slot.id));
      final bookingRef = doc(FirestorePaths.booking(bookingId));

      // Fetch user's verified status before the transaction (read-only)
      final userRef = db.doc(FirestorePaths.user(userId));
      final userSnap = await userRef.get();
      final isDriverVerified =
          (userSnap.data()?['isVerifiedDriver'] as bool?) ?? false;

      final booking = await db.runTransaction<BookingModel>((tx) async {
        final slotSnap = await tx.get(slotRef);
        if (!slotSnap.exists) {
          throw const SlotReservationException('Charger bay not found.');
        }

        final slotData = slotSnap.data()!;

        // Deserialize timeWindows from stored data
        final rawWindows = slotData['timeWindows'];
        final List<SlotTimeWindow> windows;
        if (rawWindows is List) {
          windows = rawWindows
              .whereType<Map<String, dynamic>>()
              .map(SlotTimeWindow.fromMap)
              .toList();
        } else {
          windows = [];
        }

        // Find the target window
        final idx = windows.indexWhere((w) => w.id == windowId);
        if (idx < 0) {
          throw const SlotReservationException(
            'This time window no longer exists.',
          );
        }
        final tw = windows[idx];

        // Check date is not already booked
        if (tw.isDateBooked(dateKey)) {
          throw const SlotReservationException(
            'This slot was just taken. Please choose another.',
          );
        }

        // Compute scheduledStart / scheduledEnd from window + date
        final parts = dateKey.split('-');
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);
        final scheduledStart = DateTime(year, month, day, tw.startHour, tw.startMinute);
        final scheduledEnd = DateTime(year, month, day, tw.endHour, tw.endMinute);

        // Build booking model
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
          windowId: windowId,
          windowDateKey: dateKey,
          priceTotal: (slot.pricePerKwh ?? station.pricePerKwh) * tw.durationMinutes / 60,
          notes: 'Awaiting station approval',
          isDriverVerified: isDriverVerified,
          createdAt: now,
          updatedAt: now,
        );

        // Lock the date in the window
        final newDates = Map<String, String>.from(tw.bookedDates)
          ..[dateKey] = bookingId;
        windows[idx] = tw.copyWith(bookedDates: newDates);

        tx.update(slotRef, {
          'timeWindows': windows.map((w) => w.toMap()).toList(),
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
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') {
        return const DataError('No internet connection. Please try again.');
      }
      return DataError(e, stackTrace: StackTrace.current);
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

        // Release the window date on reject or cancel
        final slotId = booking.slotId;
        final windowId = booking.windowId;
        final dateKey = booking.windowDateKey;

        if (slotId != null &&
            windowId != null &&
            dateKey != null &&
            (newStatus == BookingStatus.rejected ||
                newStatus == BookingStatus.cancelled)) {
          final slotRef =
              doc(FirestorePaths.stationSlot(booking.stationId, slotId));
          final slotSnap = await tx.get(slotRef);
          if (slotSnap.exists) {
            final rawWindows = slotSnap.data()!['timeWindows'];
            final List<SlotTimeWindow> windows;
            if (rawWindows is List) {
              windows = rawWindows
                  .whereType<Map<String, dynamic>>()
                  .map(SlotTimeWindow.fromMap)
                  .toList();
            } else {
              windows = [];
            }
            final idx = windows.indexWhere((w) => w.id == windowId);
            if (idx >= 0) {
              final tw = windows[idx];
              final newDates = Map<String, String>.from(tw.bookedDates)
                ..remove(dateKey);
              windows[idx] = tw.copyWith(bookedDates: newDates);
              tx.update(slotRef, {
                'timeWindows': windows.map((w) => w.toMap()).toList(),
                'updatedAt': FieldValue.serverTimestamp(),
              });
            }
          }
        }
      });

      // Write driver notification outside the transaction (best-effort)
      final notifTitle = switch (newStatus) {
        BookingStatus.approved || BookingStatus.confirmed =>
          'Booking confirmed ✓',
        BookingStatus.rejected => 'Booking rejected',
        BookingStatus.completed => 'Session completed',
        _ => null,
      };
      if (notifTitle != null) {
        final notifBody = switch (newStatus) {
          BookingStatus.approved || BookingStatus.confirmed =>
            'Your charging reservation has been accepted.',
          BookingStatus.rejected =>
            'Your reservation was rejected'
            '${rejectionReason != null ? ": $rejectionReason" : "."}',
          BookingStatus.completed =>
            'Your charging session is complete. Thank you!',
          _ => '',
        };
        final notif = AppNotification(
          id: 'notif_${booking.id}_${newStatus.value}',
          userId: booking.userId,
          title: notifTitle,
          body: notifBody,
          bookingId: booking.id,
          createdAt: DateTime.now(),
        );
        await _notifs.write(notif);
      }

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
