import '../errors/app_exception.dart';

/// Wraps Firestore calls with consistent [FirestoreAppException] mapping.
Future<T> guardFirestore<T>(
  Future<T> Function() operation, {
  String? context,
}) async {
  try {
    return await operation();
  } on AppException {
    rethrow;
  } catch (e, st) {
    Error.throwWithStackTrace(
      FirestoreAppException.fromFirebaseException(
        e,
        fallbackMessage: context != null
            ? '$context failed.'
            : 'Firestore operation failed.',
      ),
      st,
    );
  }
}

Stream<T> guardFirestoreStream<T>(
  Stream<T> Function() streamFactory, {
  String? context,
}) {
  return streamFactory().handleError((Object error, StackTrace st) {
    Error.throwWithStackTrace(
      FirestoreAppException.fromFirebaseException(
        error,
        fallbackMessage: context != null
            ? '$context stream failed.'
            : 'Firestore stream failed.',
      ),
      st,
    );
  });
}
