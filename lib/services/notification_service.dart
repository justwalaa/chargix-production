import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../core/firebase/firestore_paths.dart';

/// Local + FCM notifications for booking lifecycle events.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      final token = await messaging.getToken();
      debugPrint('Chargix FCM token: ${token ?? "none"}');
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null && token != null) {
        await _saveToken(uid, token);
      }
      FirebaseAuth.instance.authStateChanges().listen((user) async {
        if (user == null) return;
        final t = await messaging.getToken();
        if (t != null) await _saveToken(user.uid, t);
      });
    } on Object catch (e) {
      debugPrint('Chargix FCM init skipped: $e');
    }

    _initialized = true;
  }

  Future<void> _saveToken(String uid, String token) async {
    try {
      await FirebaseFirestore.instance.doc(FirestorePaths.user(uid)).set(
        {
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      debugPrint('Chargix: FCM token saved for $uid');
    } on Object catch (e) {
      debugPrint('Chargix: FCM token save failed: $e');
    }
  }

  Future<void> showBookingNotification({
    required String title,
    required String body,
  }) async {
    if (!_initialized) await initialize();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'chargix_bookings',
        'Bookings',
        channelDescription: 'Chargix booking and session updates',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
    debugPrint('Chargix notify: $title — $body');
  }
}
