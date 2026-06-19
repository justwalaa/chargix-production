import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firebase/firestore_paths.dart';
import '../../models/notification_model.dart';
import 'base_firestore_service.dart';

class NotificationsFirestoreService extends BaseFirestoreService {
  NotificationsFirestoreService({super.firestore});

  CollectionReference<Map<String, dynamic>> _notifs(String uid) =>
      db.collection(FirestorePaths.userNotificationsCollection(uid));

  Stream<List<AppNotification>> watchForUser(String uid) {
    return runStream(
      () => _notifs(uid)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => parseDoc(d, AppNotification.fromMap))
              .toList()),
      context: 'watchNotifications',
    );
  }

  Future<void> write(AppNotification notif) => run(() async {
        await _notifs(notif.userId)
            .doc(notif.id)
            .set(notif.toMap(), SetOptions(merge: true));
      }, context: 'writeNotification');

  Future<void> markRead(String uid, String notifId) => run(() async {
        await _notifs(uid).doc(notifId).update({'isRead': true});
      }, context: 'markNotificationRead');
}
