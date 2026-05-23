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
    this.priceTotal,
    this.notes,
    this.rejectionReason,
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
  final double? priceTotal;
  final String? notes;
  final String? rejectionReason;
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
      if (priceTotal != null) 'priceTotal': priceTotal,
      if (notes != null) 'notes': notes,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
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
      priceTotal: map['priceTotal'] != null
          ? FirestoreHelpers.requireDouble(map, 'priceTotal')
          : null,
      notes: FirestoreHelpers.optionalString(map, 'notes'),
      rejectionReason: FirestoreHelpers.optionalString(map, 'rejectionReason'),
      createdAt: FirestoreHelpers.timestampToDateTime(map['createdAt']),
      updatedAt: FirestoreHelpers.timestampToDateTime(map['updatedAt']),
    );
  }
}
