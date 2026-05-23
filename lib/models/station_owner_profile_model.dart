import 'package:flutter/foundation.dart';

import '../core/firebase/firestore_helpers.dart';

/// Firestore `station_owner_profiles/{uid}` — extended operator metadata.
@immutable
class StationOwnerProfileModel {
  const StationOwnerProfileModel({
    required this.userId,
    required this.stationId,
    this.businessName,
    this.supportPhone,
    this.createdAt,
    this.updatedAt,
  });

  final String userId;
  final String stationId;
  final String? businessName;
  final String? supportPhone;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'stationId': stationId,
      if (businessName != null) 'businessName': businessName,
      if (supportPhone != null) 'supportPhone': supportPhone,
      if (createdAt != null)
        'createdAt': FirestoreHelpers.dateTimeToTimestamp(createdAt),
      if (updatedAt != null)
        'updatedAt': FirestoreHelpers.dateTimeToTimestamp(updatedAt),
    };
  }

  factory StationOwnerProfileModel.fromMap(Map<String, dynamic> map) {
    return StationOwnerProfileModel(
      userId: map['userId'] as String? ?? '',
      stationId: map['stationId'] as String? ?? '',
      businessName: map['businessName'] as String?,
      supportPhone: map['supportPhone'] as String?,
      createdAt: FirestoreHelpers.timestampToDateTime(map['createdAt']),
      updatedAt: FirestoreHelpers.timestampToDateTime(map['updatedAt']),
    );
  }
}
