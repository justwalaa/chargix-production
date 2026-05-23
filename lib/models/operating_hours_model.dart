import 'package:flutter/foundation.dart';

import '../core/firebase/firestore_helpers.dart';

/// Weekly operating hours embedded on station documents.
@immutable
class OperatingHoursModel {
  const OperatingHoursModel({
    this.openTime = '06:00',
    this.closeTime = '23:00',
    this.timezone = 'Asia/Amman',
    this.openDays = const [1, 2, 3, 4, 5, 6, 7],
  });

  final String openTime;
  final String closeTime;
  final String timezone;
  final List<int> openDays;

  Map<String, dynamic> toMap() => {
        'openTime': openTime,
        'closeTime': closeTime,
        'timezone': timezone,
        'openDays': openDays,
      };

  factory OperatingHoursModel.fromMap(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) {
      return const OperatingHoursModel();
    }
    final days = map['openDays'];
    return OperatingHoursModel(
      openTime: FirestoreHelpers.optionalString(map, 'openTime') ?? '06:00',
      closeTime: FirestoreHelpers.optionalString(map, 'closeTime') ?? '23:00',
      timezone: FirestoreHelpers.optionalString(map, 'timezone') ?? 'Asia/Amman',
      openDays: days is List
          ? days.map((e) => int.tryParse(e.toString()) ?? 0).where((d) => d > 0).toList()
          : const [1, 2, 3, 4, 5, 6, 7],
    );
  }
}
