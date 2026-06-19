import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firebase/firestore_paths.dart';
import '../../models/user_model.dart';
import 'base_firestore_service.dart';

/// Low-level Firestore access for `users` collection.
class UsersFirestoreService extends BaseFirestoreService {
  UsersFirestoreService({super.firestore});

  CollectionReference<Map<String, dynamic>> get _users =>
      collection(FirestorePaths.users);

  DocumentReference<Map<String, dynamic>> userDoc(String uid) =>
      _users.doc(uid);

  Future<UserModel?> getUser(String uid) => run(() async {
        final snap = await userDoc(uid).get();
        if (!snap.exists) {
          return null;
        }
        return parseDoc(snap, UserModel.fromMap);
      }, context: 'getUser');

  Stream<UserModel?> watchUser(String uid) {
    return runStream(
      () => userDoc(uid).snapshots().map((snap) {
        if (!snap.exists) {
          return null;
        }
        return parseDoc(snap, UserModel.fromMap);
      }),
      context: 'watchUser',
    );
  }

  Future<void> upsertUser(UserModel user, {required bool isCreate}) => run(() async {
        final data = withWriteTimestamps(
          data: user.toMap(),
          isCreate: isCreate,
        );
        data['lastLoginAt'] = FieldValue.serverTimestamp();
        await userDoc(user.uid).set(data, SetOptions(merge: true));
      }, context: 'upsertUser');

  Future<bool> userExists(String uid) => run(() async {
        final snap = await userDoc(uid).get();
        return snap.exists;
      }, context: 'userExists');

  Future<void> incrementBookingStats(
    String uid, {
    required bool qrVerified,
  }) =>
      run(() async {
        final updates = <String, dynamic>{
          'totalBookings': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (qrVerified) {
          updates['completedWithQR'] = FieldValue.increment(1);
        }
        await userDoc(uid).update(updates);

        // Recompute isVerifiedDriver after incrementing
        final snap = await userDoc(uid).get();
        if (snap.exists) {
          final data = snap.data()!;
          final total = (data['totalBookings'] as num?)?.toInt() ?? 0;
          final qr = (data['completedWithQR'] as num?)?.toInt() ?? 0;
          final isVerified = total >= 3 && qr == total;
          await userDoc(uid)
              .update({'isVerifiedDriver': isVerified});
        }
      }, context: 'incrementBookingStats');
}
