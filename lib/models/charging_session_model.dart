import 'package:flutter/foundation.dart';

import '../core/firebase/firestore_helpers.dart';
import 'enums/charging_session_status.dart';

/// Firestore `charging_sessions/{id}` — live or historical charge.
@immutable
class ChargingSessionModel {
  const ChargingSessionModel({
    required this.id,
    required this.userId,
    required this.stationId,
    required this.status,
    this.bookingId,
    this.vehicleId,
    this.startedAt,
    this.endedAt,
    this.energyDeliveredKwh,
    this.cost,
    this.portNumber,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String stationId;
  final String? bookingId;
  final String? vehicleId;
  final ChargingSessionStatus status;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final double? energyDeliveredKwh;
  final double? cost;
  final int? portNumber;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'stationId': stationId,
      if (bookingId != null) 'bookingId': bookingId,
      if (vehicleId != null) 'vehicleId': vehicleId,
      'status': status.value,
      if (startedAt != null)
        'startedAt': FirestoreHelpers.dateTimeToTimestamp(startedAt),
      if (endedAt != null)
        'endedAt': FirestoreHelpers.dateTimeToTimestamp(endedAt),
      if (energyDeliveredKwh != null) 'energyDeliveredKwh': energyDeliveredKwh,
      if (cost != null) 'cost': cost,
      if (portNumber != null) 'portNumber': portNumber,
      if (createdAt != null)
        'createdAt': FirestoreHelpers.dateTimeToTimestamp(createdAt),
      if (updatedAt != null)
        'updatedAt': FirestoreHelpers.dateTimeToTimestamp(updatedAt),
    };
  }

  factory ChargingSessionModel.fromMap(Map<String, dynamic> map) {
    return ChargingSessionModel(
      id: FirestoreHelpers.requireString(map, 'id'),
      userId: FirestoreHelpers.requireString(map, 'userId'),
      stationId: FirestoreHelpers.requireString(map, 'stationId'),
      bookingId: FirestoreHelpers.optionalString(map, 'bookingId'),
      vehicleId: FirestoreHelpers.optionalString(map, 'vehicleId'),
      status: ChargingSessionStatus.fromValue(
        FirestoreHelpers.optionalString(map, 'status'),
      ),
      startedAt: FirestoreHelpers.timestampToDateTime(map['startedAt']),
      endedAt: FirestoreHelpers.timestampToDateTime(map['endedAt']),
      energyDeliveredKwh: map['energyDeliveredKwh'] != null
          ? FirestoreHelpers.requireDouble(map, 'energyDeliveredKwh')
          : null,
      cost: map['cost'] != null
          ? FirestoreHelpers.requireDouble(map, 'cost')
          : null,
      portNumber: map['portNumber'] != null
          ? FirestoreHelpers.requireInt(map, 'portNumber')
          : null,
      createdAt: FirestoreHelpers.timestampToDateTime(map['createdAt']),
      updatedAt: FirestoreHelpers.timestampToDateTime(map['updatedAt']),
    );
  }
}
