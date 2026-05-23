import '../../core/result/data_state.dart';
import '../../models/charging_session_model.dart';
import '../firestore/charging_sessions_firestore_service.dart';

class ChargingSessionRepository {
  ChargingSessionRepository({ChargingSessionsFirestoreService? service})
      : _service = service ?? ChargingSessionsFirestoreService();

  static final ChargingSessionRepository instance = ChargingSessionRepository();

  final ChargingSessionsFirestoreService _service;

  Stream<List<ChargingSessionModel>> watchSessionsForUser(String userId) =>
      _service.watchSessionsForUser(userId);

  Stream<ChargingSessionModel?> watchActiveSessionForUser(String userId) =>
      _service.watchActiveSessionForUser(userId);

  Future<DataState<List<ChargingSessionModel>>> fetchSessionsForUser(
    String userId,
  ) async {
    try {
      final list = await _service.getSessionsForUser(userId);
      return DataSuccess(list);
    } catch (e, st) {
      return DataError(e, stackTrace: st);
    }
  }

  Future<DataState<void>> saveSession(ChargingSessionModel session) async {
    try {
      await _service.upsertSession(session, isCreate: true);
      return const DataSuccess(null);
    } catch (e, st) {
      return DataError(e, stackTrace: st);
    }
  }
}
