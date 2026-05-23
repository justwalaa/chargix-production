import '../../../core/result/data_state.dart';
import '../../../models/enums/user_role.dart';
import '../../../models/user_model.dart';
import '../../firestore/users_firestore_service.dart';

/// User profile orchestration (auth → Firestore `users`).
class UserRepository {
  UserRepository({UsersFirestoreService? service})
      : _service = service ?? UsersFirestoreService();

  static final UserRepository instance = UserRepository();

  final UsersFirestoreService _service;

  Stream<UserModel?> watchCurrentUser(String uid) => _service.watchUser(uid);

  Future<DataState<UserModel>> getUser(String uid) async {
    try {
      final user = await _service.getUser(uid);
      if (user == null) {
        return const DataError<UserModel>(
          'User profile not found.',
        );
      }
      return DataSuccess(user);
    } catch (e, st) {
      return DataError(e, stackTrace: st);
    }
  }

  /// Creates or updates the user document after phone OTP sign-in.
  Future<DataState<UserModel>> ensureUserAfterSignIn({
    required String uid,
    required String phoneE164,
    UserRole role = UserRole.user,
    String? stationId,
    String locale = 'en',
    bool notificationsEnabled = true,
  }) async {
    try {
      final exists = await _service.userExists(uid);
      final existing = exists ? await _service.getUser(uid) : null;
      final profile = UserModel(
        uid: uid,
        phoneE164: phoneE164,
        role: existing?.role ?? role,
        stationId: existing?.stationId ?? stationId,
        displayName: existing?.displayName,
        locale: existing?.locale ?? locale,
        notificationsEnabled:
            existing?.notificationsEnabled ?? notificationsEnabled,
        lastLoginAt: DateTime.now().toUtc(),
      );
      await _service.upsertUser(profile, isCreate: !exists);
      final saved = await _service.getUser(uid);
      if (saved == null) {
        return const DataError<UserModel>(
          'Failed to load user after sign-in.',
        );
      }
      return DataSuccess(saved);
    } catch (e, st) {
      return DataError(e, stackTrace: st);
    }
  }

  Future<DataState<void>> updateProfile(UserModel user) async {
    try {
      await _service.upsertUser(user, isCreate: false);
      return const DataSuccess(null);
    } catch (e, st) {
      return DataError(e, stackTrace: st);
    }
  }
}
