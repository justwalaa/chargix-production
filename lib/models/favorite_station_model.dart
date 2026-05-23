import 'package:flutter/foundation.dart';

import '../core/firebase/firestore_helpers.dart';

/// Firestore `favorites/{userId}_{stationId}`.
@immutable
class FavoriteStationModel {
  const FavoriteStationModel({
    required this.id,
    required this.userId,
    required this.stationId,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String stationId;
  final DateTime? createdAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'stationId': stationId,
      if (createdAt != null)
        'createdAt': FirestoreHelpers.dateTimeToTimestamp(createdAt),
    };
  }

  factory FavoriteStationModel.fromMap(Map<String, dynamic> map) {
    return FavoriteStationModel(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      stationId: map['stationId'] as String? ?? '',
      createdAt: FirestoreHelpers.timestampToDateTime(map['createdAt']),
    );
  }
}
