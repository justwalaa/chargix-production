import 'package:flutter/foundation.dart';

import '../core/firebase/firestore_helpers.dart';

@immutable
class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.bookingId,
    this.isRead = false,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String title;
  final String body;
  final String? bookingId;
  final bool isRead;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'title': title,
        'body': body,
        if (bookingId != null) 'bookingId': bookingId,
        'isRead': isRead,
        'createdAt': FirestoreHelpers.dateTimeToTimestamp(createdAt),
      };

  factory AppNotification.fromMap(Map<String, dynamic> map) => AppNotification(
        id: FirestoreHelpers.requireString(map, 'id'),
        userId: FirestoreHelpers.requireString(map, 'userId'),
        title: FirestoreHelpers.requireString(map, 'title'),
        body: FirestoreHelpers.requireString(map, 'body'),
        bookingId: FirestoreHelpers.optionalString(map, 'bookingId'),
        isRead: (map['isRead'] as bool?) ?? false,
        createdAt: FirestoreHelpers.timestampToDateTime(map['createdAt']) ??
            DateTime.now(),
      );

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        userId: userId,
        title: title,
        body: body,
        bookingId: bookingId,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );
}
