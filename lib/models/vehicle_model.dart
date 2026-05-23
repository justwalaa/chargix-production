import 'package:flutter/foundation.dart';

import '../core/firebase/firestore_helpers.dart';

/// Firestore `vehicles/{id}` — owned by a user.
@immutable
class VehicleModel {
  const VehicleModel({
    required this.id,
    required this.userId,
    required this.make,
    required this.model,
    this.year,
    this.batteryCapacityKwh,
    this.connectorType = 'CCS2',
    this.licensePlate,
    this.isDefault = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String make;
  final String model;
  final int? year;
  final double? batteryCapacityKwh;
  final String connectorType;
  final String? licensePlate;
  final bool isDefault;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get displayLabel => '$make $model${year != null ? ' ($year)' : ''}';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'make': make,
      'model': model,
      if (year != null) 'year': year,
      if (batteryCapacityKwh != null) 'batteryCapacityKwh': batteryCapacityKwh,
      'connectorType': connectorType,
      if (licensePlate != null) 'licensePlate': licensePlate,
      'isDefault': isDefault,
      if (createdAt != null)
        'createdAt': FirestoreHelpers.dateTimeToTimestamp(createdAt),
      if (updatedAt != null)
        'updatedAt': FirestoreHelpers.dateTimeToTimestamp(updatedAt),
    };
  }

  factory VehicleModel.fromMap(Map<String, dynamic> map) {
    return VehicleModel(
      id: FirestoreHelpers.requireString(map, 'id'),
      userId: FirestoreHelpers.requireString(map, 'userId'),
      make: FirestoreHelpers.requireString(map, 'make'),
      model: FirestoreHelpers.requireString(map, 'model'),
      year: map['year'] != null
          ? FirestoreHelpers.requireInt(map, 'year')
          : null,
      batteryCapacityKwh: map['batteryCapacityKwh'] != null
          ? FirestoreHelpers.requireDouble(map, 'batteryCapacityKwh')
          : null,
      connectorType:
          FirestoreHelpers.optionalString(map, 'connectorType') ?? 'CCS2',
      licensePlate: FirestoreHelpers.optionalString(map, 'licensePlate'),
      isDefault: FirestoreHelpers.requireBool(map, 'isDefault'),
      createdAt: FirestoreHelpers.timestampToDateTime(map['createdAt']),
      updatedAt: FirestoreHelpers.timestampToDateTime(map['updatedAt']),
    );
  }
}
