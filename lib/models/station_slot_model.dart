import 'package:flutter/foundation.dart';

import '../core/firebase/firestore_helpers.dart';

/// `stations/{stationId}/slots/{slotId}` — bookable charger bay.
@immutable
class StationSlotModel {
  const StationSlotModel({
    required this.id,
    required this.stationId,
    required this.label,
    this.connectorType = 'Type 2',
    this.chargingType = 'AC',
    this.powerKw = 22,
    this.pricePerKwh,
    this.estimatedDurationMinutes = 45,
    this.isOpen = true,
    this.isAvailable = true,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String stationId;
  final String label;
  final String connectorType;
  final String chargingType;
  final double powerKw;
  final double? pricePerKwh;
  final int estimatedDurationMinutes;
  final bool isOpen;
  final bool isAvailable;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'stationId': stationId,
      'label': label,
      'connectorType': connectorType,
      'chargingType': chargingType,
      'powerKw': powerKw,
      if (pricePerKwh != null) 'pricePerKwh': pricePerKwh,
      'estimatedDurationMinutes': estimatedDurationMinutes,
      'isOpen': isOpen,
      'isAvailable': isAvailable,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
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
          FirestoreHelpers.optionalString(map, 'connectorType') ?? 'Type 2',
      chargingType:
          FirestoreHelpers.optionalString(map, 'chargingType') ?? 'AC',
      powerKw: FirestoreHelpers.requireDouble(map, 'powerKw', fallback: 22),
      pricePerKwh: map['pricePerKwh'] != null
          ? FirestoreHelpers.requireDouble(map, 'pricePerKwh')
          : null,
      estimatedDurationMinutes: FirestoreHelpers.requireInt(
        map,
        'estimatedDurationMinutes',
        fallback: 45,
      ),
      isOpen: FirestoreHelpers.requireBool(map, 'isOpen', fallback: true),
      isAvailable: FirestoreHelpers.requireBool(map, 'isAvailable', fallback: true),
      notes: FirestoreHelpers.optionalString(map, 'notes'),
      createdAt: FirestoreHelpers.timestampToDateTime(map['createdAt']),
      updatedAt: FirestoreHelpers.timestampToDateTime(map['updatedAt']),
    );
  }

  StationSlotModel copyWith({
    String? id,
    String? stationId,
    String? label,
    String? connectorType,
    String? chargingType,
    double? powerKw,
    double? pricePerKwh,
    int? estimatedDurationMinutes,
    bool? isOpen,
    bool? isAvailable,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StationSlotModel(
      id: id ?? this.id,
      stationId: stationId ?? this.stationId,
      label: label ?? this.label,
      connectorType: connectorType ?? this.connectorType,
      chargingType: chargingType ?? this.chargingType,
      powerKw: powerKw ?? this.powerKw,
      pricePerKwh: pricePerKwh ?? this.pricePerKwh,
      estimatedDurationMinutes:
          estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      isOpen: isOpen ?? this.isOpen,
      isAvailable: isAvailable ?? this.isAvailable,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
