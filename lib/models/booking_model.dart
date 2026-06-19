import 'package:flutter/foundation.dart';

import '../core/firebase/firestore_helpers.dart';
import 'enums/booking_status.dart';

/// Firestore `bookings/{id}` — driver reservation at a partner station.
@immutable
class BookingModel {
  const BookingModel({
    required this.id,
    required this.userId,
    required this.stationId,
    required this.status,
    this.vehicleId,
    this.scheduledStart,
    this.scheduledEnd,
    this.portNumber,
    this.slotId,
    this.windowId,
    this.windowDateKey,
    this.priceTotal,
    this.notes,
    this.rejectionReason,
    this.isDriverVerified,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String stationId;
  final String? vehicleId;
  final BookingStatus status;
  final DateTime? scheduledStart;
  final DateTime? scheduledEnd;
  final int? portNumber;
  final String? slotId;

  /// ID of the [SlotTimeWindow] that was booked (e.g. "tw_1").
  /// Used to release the window's [bookedDates] entry on cancel/reject.
  final String? windowId;

  /// The "yyyy-MM-dd" date key locked in [SlotTimeWindow.bookedDates].
  final String? windowDateKey;

  final double? priceTotal;
  final String? notes;
  final String? rejectionReason;

  /// Snapshot of the driver's verified status at booking creation time.
  final bool? isDriverVerified;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'stationId': stationId,
      if (vehicleId != null) 'vehicleId': vehicleId,
      'status': status.value,
      if (scheduledStart != null)
        'scheduledStart':
            FirestoreHelpers.dateTimeToTimestamp(scheduledStart),
      if (scheduledEnd != null)
        'scheduledEnd': FirestoreHelpers.dateTimeToTimestamp(scheduledEnd),
      if (portNumber != null) 'portNumber': portNumber,
      if (slotId != null) 'slotId': slotId,
      if (windowId != null) 'windowId': windowId,
      if (windowDateKey != null) 'windowDateKey': windowDateKey,
      if (priceTotal != null) 'priceTotal': priceTotal,
      if (notes != null) 'notes': notes,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      if (isDriverVerified != null) 'isDriverVerified': isDriverVerified,
      if (createdAt != null)
        'createdAt': FirestoreHelpers.dateTimeToTimestamp(createdAt),
      if (updatedAt != null)
        'updatedAt': FirestoreHelpers.dateTimeToTimestamp(updatedAt),
    };
  }

  factory BookingModel.fromMap(Map<String, dynamic> map) {
    return BookingModel(
      id: FirestoreHelpers.requireString(map, 'id'),
      userId: FirestoreHelpers.requireString(map, 'userId'),
      stationId: FirestoreHelpers.requireString(map, 'stationId'),
      vehicleId: FirestoreHelpers.optionalString(map, 'vehicleId'),
      status: BookingStatus.fromValue(
        FirestoreHelpers.optionalString(map, 'status'),
      ),
      scheduledStart:
          FirestoreHelpers.timestampToDateTime(map['scheduledStart']),
      scheduledEnd: FirestoreHelpers.timestampToDateTime(map['scheduledEnd']),
      portNumber: map['portNumber'] != null
          ? FirestoreHelpers.requireInt(map, 'portNumber')
          : null,
      slotId: FirestoreHelpers.optionalString(map, 'slotId'),
      windowId: FirestoreHelpers.optionalString(map, 'windowId'),
      windowDateKey: FirestoreHelpers.optionalString(map, 'windowDateKey'),
      priceTotal: map['priceTotal'] != null
          ? FirestoreHelpers.requireDouble(map, 'priceTotal')
          : null,
      notes: FirestoreHelpers.optionalString(map, 'notes'),
      rejectionReason:
          FirestoreHelpers.optionalString(map, 'rejectionReason'),
      isDriverVerified: map['isDriverVerified'] as bool?,
      createdAt: FirestoreHelpers.timestampToDateTime(map['createdAt']),
      updatedAt: FirestoreHelpers.timestampToDateTime(map['updatedAt']),
    );
  }
}
