import '../../core/result/data_state.dart';
import '../../models/notification_model.dart';
import '../firestore/notifications_firestore_service.dart';

class NotificationsRepository {
  NotificationsRepository({NotificationsFirestoreService? service})
      : _service = service ?? NotificationsFirestoreService();

  static final NotificationsRepository instance = NotificationsRepository();

  final NotificationsFirestoreService _service;

  Stream<List<AppNotification>> watchForUser(String uid) =>
      _service.watchForUser(uid);

  Future<DataState<void>> write(AppNotification notif) async {
    try {
      await _service.write(notif);
      return const DataSuccess(null);
    } catch (e, st) {
      return DataError(e, stackTrace: st);
    }
  }

  Future<DataState<void>> markRead(String uid, String notifId) async {
    try {
      await _service.markRead(uid, notifId);
      return const DataSuccess(null);
    } catch (e, st) {
      return DataError(e, stackTrace: st);
    }
  }
}
