import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firebase/firestore_paths.dart';
import '../../models/charging_session_model.dart';
import '../../models/enums/charging_session_status.dart';
import 'base_firestore_service.dart';

class ChargingSessionsFirestoreService extends BaseFirestoreService {
  ChargingSessionsFirestoreService({super.firestore});

  CollectionReference<Map<String, dynamic>> get _sessions =>
      collection(FirestorePaths.chargingSessions);

  Future<List<ChargingSessionModel>> getSessionsForUser(String userId) =>
      run(() async {
        final query =
            await _sessions.where('userId', isEqualTo: userId).get();
        final list = query.docs
            .map((d) => parseDoc(d, ChargingSessionModel.fromMap))
            .toList();
        list.sort((a, b) {
          final at = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bt.compareTo(at);
        });
        return list;
      }, context: 'getSessionsForUser');

  Stream<List<ChargingSessionModel>> watchSessionsForUser(String userId) {
    return runStream(
      () => _sessions.where('userId', isEqualTo: userId).snapshots().map((snap) {
            final list = snap.docs
                .map((d) => parseDoc(d, ChargingSessionModel.fromMap))
                .toList();
            list.sort((a, b) {
              final at = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              final bt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              return bt.compareTo(at);
            });
            return list;
          }),
      context: 'watchSessionsForUser',
    );
  }

  Stream<ChargingSessionModel?> watchActiveSessionForUser(String userId) {
    return runStream(
      () => _sessions.where('userId', isEqualTo: userId).snapshots().map((snap) {
            for (final doc in snap.docs) {
              final session = parseDoc(doc, ChargingSessionModel.fromMap);
              if (session.status == ChargingSessionStatus.charging ||
                  session.status == ChargingSessionStatus.paused) {
                return session;
              }
            }
            return null;
          }),
      context: 'watchActiveSessionForUser',
    );
  }

  Future<void> upsertSession(
    ChargingSessionModel session, {
    required bool isCreate,
  }) =>
      run(() async {
        final data = withWriteTimestamps(
          data: session.toMap(),
          isCreate: isCreate,
        );
        await _sessions.doc(session.id).set(data, SetOptions(merge: true));
      }, context: 'upsertSession');
}
