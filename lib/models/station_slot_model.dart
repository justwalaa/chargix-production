import 'package:flutter/foundation.dart';

import '../core/firebase/firestore_helpers.dart';

/// `stations/{stationId}/slots/{slotId}` — bookable charger bay.
@immutable
class StationSlotModel {
  const StationSlotModel({
    required this.id,
    required this.stationId,
    required this.label,
    this.connectorType = 'CCS2',
    this.powerKw = 50,
    this.pricePerKwh,
    this.isAvailable = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String stationId;
  final String label;
  final String connectorType;
  final double powerKw;
  final double? pricePerKwh;
  final bool isAvailable;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'stationId': stationId,
      'label': label,
      'connectorType': connectorType,
      'powerKw': powerKw,
      if (pricePerKwh != null) 'pricePerKwh': pricePerKwh,
      'isAvailable': isAvailable,
      if (createdAt != null)
        'createdAt': FirestoreHelpers.dateTimeToTimestamp(createdAt),
      if (updatedAt != null)
        'updatedAt': FirestoreHelpers.dateTimeToTimestamp(updatedAt),
    };
  }

  factory StationSlotModel.fromMap(Map<String, dynamic> map) {
    return StationSlotModel(
      id: FirestoreHelpers.requireString(map, 'id'),
      stationId: FirestoreHelpers.requireString(map, 'stationId'),
      label: FirestoreHelpers.requireString(map, 'label'),
      connectorType:
          FirestoreHelpers.optionalString(map, 'connectorType') ?? 'CCS2',
      powerKw: FirestoreHelpers.requireDouble(map, 'powerKw', fallback: 50),
      pricePerKwh: map['pricePerKwh'] != null
          ? FirestoreHelpers.requireDouble(map, 'pricePerKwh')
          : null,
      isAvailable: FirestoreHelpers.requireBool(map, 'isAvailable', fallback: true),
      createdAt: FirestoreHelpers.timestampToDateTime(map['createdAt']),
      updatedAt: FirestoreHelpers.timestampToDateTime(map['updatedAt']),
    );
  }
}
