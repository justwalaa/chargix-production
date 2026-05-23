import 'package:flutter/foundation.dart';

import '../core/firebase/firestore_helpers.dart';
import 'enums/user_role.dart';

/// Firestore `users/{uid}` profile (phone auth + dashboard metadata).
@immutable
class UserModel {
  const UserModel({
    required this.uid,
    required this.phoneE164,
    this.displayName,
    this.email,
    this.photoUrl,
    this.role = UserRole.user,
    this.locale = 'en',
    this.notificationsEnabled = true,
    this.vehicleIds = const [],
    this.stationId,
    this.createdAt,
    this.updatedAt,
    this.lastLoginAt,
  });

  final String uid;
  final String phoneE164;
  final String? displayName;
  final String? email;
  final String? photoUrl;
  final UserRole role;
  final String locale;
  final bool notificationsEnabled;
  final List<String> vehicleIds;
  /// Owned/managed station document id when [role] is [UserRole.station].
  final String? stationId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLoginAt;

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'phoneE164': phoneE164,
      'phone': phoneE164,
      if (displayName != null) 'displayName': displayName,
      if (email != null) 'email': email,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'role': role.value,
      'locale': locale,
      'notificationsEnabled': notificationsEnabled,
      'vehicleIds': vehicleIds,
      if (stationId != null) 'stationId': stationId,
      if (createdAt != null)
        'createdAt': FirestoreHelpers.dateTimeToTimestamp(createdAt),
      if (updatedAt != null)
        'updatedAt': FirestoreHelpers.dateTimeToTimestamp(updatedAt),
      if (lastLoginAt != null)
        'lastLoginAt': FirestoreHelpers.dateTimeToTimestamp(lastLoginAt),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: FirestoreHelpers.requireString(map, 'uid').isNotEmpty
          ? FirestoreHelpers.requireString(map, 'uid')
          : FirestoreHelpers.requireString(map, 'id'),
      phoneE164: FirestoreHelpers.optionalString(map, 'phoneE164') ??
          FirestoreHelpers.requireString(map, 'phone'),
      displayName: FirestoreHelpers.optionalString(map, 'displayName'),
      email: FirestoreHelpers.optionalString(map, 'email'),
      photoUrl: FirestoreHelpers.optionalString(map, 'photoUrl'),
      role: UserRole.fromValue(FirestoreHelpers.optionalString(map, 'role')),
      locale: FirestoreHelpers.optionalString(map, 'locale') ?? 'en',
      notificationsEnabled: FirestoreHelpers.requireBool(
        map,
        'notificationsEnabled',
        fallback: true,
      ),
      vehicleIds: FirestoreHelpers.stringList(map, 'vehicleIds'),
      stationId: FirestoreHelpers.optionalString(map, 'stationId'),
      createdAt: FirestoreHelpers.timestampToDateTime(map['createdAt']),
      updatedAt: FirestoreHelpers.timestampToDateTime(map['updatedAt']),
      lastLoginAt: FirestoreHelpers.timestampToDateTime(map['lastLoginAt']),
    );
  }

  UserModel copyWith({
    String? displayName,
    String? email,
    String? photoUrl,
    UserRole? role,
    String? locale,
    bool? notificationsEnabled,
    List<String>? vehicleIds,
    String? stationId,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      uid: uid,
      phoneE164: phoneE164,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      locale: locale ?? this.locale,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      vehicleIds: vehicleIds ?? this.vehicleIds,
      stationId: stationId ?? this.stationId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}
